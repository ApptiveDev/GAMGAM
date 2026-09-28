import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/layout.dart';
import '../../data/models/appointment.dart';
import '../../data/models/live_location.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/live_location_repository.dart';
import 'widgets/podium.dart';

/// 09 · 도착 완료 — 도착 순서를 가볍게 축하하고, 지각은 벌칙 한 줄로만 부드럽게.
class ArrivalPage extends StatefulWidget {
  const ArrivalPage({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  State<ArrivalPage> createState() => _ArrivalPageState();
}

class _ArrivalPageState extends State<ArrivalPage> {
  bool _settling = false;

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AppointmentRepository>().findById(widget.appointmentId);
    final session = context.watch<LiveLocationRepository>().session(widget.appointmentId);
    if (a == null) return const Scaffold(body: Center(child: Text('약속을 찾을 수 없어요.')));
    if (session == null || !session.allArrived) return _NotYet(appointmentId: a.id);

    final late = _latecomers(a, session);
    final order = session.arrivalOrder;

    return Scaffold(
      appBar: BackAppBar(onBack: () => context.go(AppRoutes.room(a.id))),
      body: Stack(children: [
        const _Confetti(),
        ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          children: [
            const Text('다 모였어요!', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
            const SizedBox(height: 8),
            Text([a.name, if (a.time != null) DateText.time(a.time!)].join(' · '),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSub)),
            const SizedBox(height: 34),
            Podium(top: order.take(3).toList()),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Divider(thickness: 1.5)),
            const SizedBox(height: 24),
            _TodayRecord(appointment: a, session: session, late: late),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
              child: const Text('모두 도착해서 위치 공유가 자동으로 꺼졌어요.', style: TextStyle(fontSize: 13, color: AppColors.textSub)),
            ),
          ],
        ),
      ]),
      bottomNavigationBar: BottomCta(children: [
        FilledButton(onPressed: _settling ? null : () => _settle(a, late.length), child: const Text('정산 완료')),
        const SizedBox(height: 4),
        TextButton(
          // TODO: 지도 리플레이 (핵심기능 #2 이후)
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('지도 리플레이는 준비 중이에요'))),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSub),
          child: const Text('오늘 지도 리플레이 보기'),
        ),
      ]),
    );
  }

  Future<void> _settle(Appointment a, int lateCount) async {
    setState(() => _settling = true);
    await context.read<AppointmentRepository>().complete(a.id, lateCount: lateCount);
    if (mounted) context.go(AppRoutes.home);
  }

  /// 약속 시각 + 지각 기준을 넘겨 도착한 사람과 늦은 분.
  static List<(LiveParticipant, int)> _latecomers(Appointment a, LiveSession s) => [
        for (final p in s.arrivalOrder)
          if (p.arrivedAt!.difference(s.appointmentTime).inMinutes > a.lateThresholdMinutes) (p, p.arrivedAt!.difference(s.appointmentTime).inMinutes),
      ];
}

class _TodayRecord extends StatelessWidget {
  const _TodayRecord({required this.appointment, required this.session, required this.late});

  final Appointment appointment;
  final LiveSession session;
  final List<(LiveParticipant, int)> late;

  @override
  Widget build(BuildContext context) {
    final penalty = appointment.penalty;
    final hasPenalty = penalty != null && penalty != '벌칙 없음';
    final counts = session.pokeCounts.entries.where((e) => e.value > 0).toList()..sort((x, y) => y.value.compareTo(x.value));
    final mostPoked = counts.isEmpty ? null : session.byId(counts.first.key)?.participant.name;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('오늘의 기록', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSub)),
        const SizedBox(height: 13),
        if (late.isEmpty) const _RecordRow(leading: Icon(Icons.check_circle_outline, color: AppColors.textMuted), text: '늦은 사람 없이 모두 모였어요'),
        for (final (p, minutes) in late)
          _RecordRow(
            leading: Avatar(p.participant, size: 32),
            text: '${p.participant.name}님 $minutes분 늦음',
            trailing: hasPenalty
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.point, width: 1.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(penalty, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.point)),
                  )
                : null,
          ),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
        _RecordRow(
          leading: const Icon(Icons.touch_app_outlined, color: AppColors.textMuted),
          text: null,
          rich: TextSpan(children: [
            const TextSpan(text: '오늘 콕 찌르기 '),
            TextSpan(text: '${session.totalPokes}번', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textBody)),
            TextSpan(text: mostPoked == null ? ' 오갔어요' : ' 오갔어요 · 가장 많이 받은 사람은 $mostPoked'),
          ]),
        ),
      ]),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.leading, required this.text, this.rich, this.trailing});

  final Widget leading;
  final String? text;
  final InlineSpan? rich;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 32, child: Center(child: leading)),
          const SizedBox(width: 11),
          Expanded(
            child: text != null
                ? Text(text!, style: const TextStyle(fontSize: 14, color: AppColors.textBody))
                : Text.rich(rich!, style: const TextStyle(fontSize: 13, color: AppColors.textSub, height: 1.4)),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

/// 가벼운 축하 그래픽 — 색종이 조각 몇 개.
class _Confetti extends StatelessWidget {
  const _Confetti();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: SizedBox(
          height: 60,
          width: double.infinity,
          child: Stack(children: [
            _piece(left: 36, top: 12, size: 7, round: true, color: AppColors.point.withValues(alpha: 0.7)),
            _piece(left: 120, top: 0, size: 6, color: AppColors.avatar, angle: 0.4, tall: true),
            _piece(right: 52, top: 20, size: 8, color: AppColors.point.withValues(alpha: 0.45), angle: 0.35),
            _piece(right: 120, top: 4, size: 6, round: true, color: AppColors.borderStrong),
          ]),
        ),
      );

  static Widget _piece({double? left, double? right, required double top, required double size, required Color color, bool round = false, bool tall = false, double angle = 0}) =>
      Positioned(
        left: left,
        right: right,
        top: top,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: size,
            height: tall ? size * 2 : size,
            decoration: BoxDecoration(color: color, shape: round ? BoxShape.circle : BoxShape.rectangle, borderRadius: round ? null : BorderRadius.circular(2)),
          ),
        ),
      );
}

class _NotYet extends StatelessWidget {
  const _NotYet({required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: BackAppBar(onBack: () => context.go(AppRoutes.room(appointmentId))),
        body: const Padding(
          padding: kPagePadding,
          child: PageTitle('아직 다 모이지 않았어요', subtitle: '모두 도착하면 도착 순위와 오늘의 기록을 보여드릴게요.'),
        ),
      );
}

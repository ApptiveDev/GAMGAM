import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/tags.dart';
import '../../data/models/appointment.dart';
import '../../data/repositories/appointment_repository.dart';

/// 05 · 확정 완료 + 공유 (웹에서 열면 앱 설치 유도)
class ConfirmedPage extends StatelessWidget {
  const ConfirmedPage({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppointmentRepository>();
    final a = repo.findById(appointmentId);
    if (a == null) return const Scaffold(body: Center(child: Text('약속을 찾을 수 없어요.')));

    final noApp = a.participants.where((p) => !p.hasApp).toList();

    return Scaffold(
      appBar: BackAppBar(onBack: () => context.go(AppRoutes.room(a.id))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        children: [
          const Align(alignment: Alignment.centerLeft, child: SoftBadge('약속이 확정됐어요')),
          const SizedBox(height: 16),
          _ConfirmedCard(appointment: a),
          const SizedBox(height: 16),
          const _DayOfInfo(),
          if (noApp.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InstallStatus(appointment: a, noAppIds: {for (final p in noApp) p.id}),
          ],
        ],
      ),
      bottomNavigationBar: BottomCta(children: [
        // 웹(설치 전)에서는 설치 유도, 앱에서는 홈으로.
        if (kIsWeb)
          FilledButton(onPressed: () {/* TODO: 스토어 링크 */}, child: const Text('앱 설치하기'))
        else
          FilledButton(onPressed: () => context.go(AppRoutes.home), child: const Text('홈으로')),
        const SizedBox(height: 8),
        OutlinedButton(
          // TODO: 카카오톡 공유 SDK 연결. 지금은 링크 복사로 대신한다.
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: repo.inviteLink(a)));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('링크를 복사했어요. 카카오톡에 붙여넣어 보내주세요')));
          },
          child: const Text('카카오톡으로 공유'),
        ),
      ]),
    );
  }
}

class _ConfirmedCard extends StatelessWidget {
  const _ConfirmedCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final time = a.time;
    final penalty = a.penalty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderCard, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
        if (time != null) ...[
          const SizedBox(height: 6),
          Text(DateText.dDay(time), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.point, height: 1.1)),
          const SizedBox(height: 4),
          Text('${DateText.dateTime(time)}까지', style: const TextStyle(fontSize: 13, color: AppColors.textSub)),
        ],
        const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider()),
        if (a.place != null)
          Row(children: [
            const ImagePlaceholder(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.place!.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textTitle)),
                if (a.place!.description.isNotEmpty) Text(a.place!.description, style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
              ]),
            ),
          ]),
        if (penalty != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
            child: Text.rich(
              penalty == '벌칙 없음'
                  ? const TextSpan(text: '이번엔 벌칙 없이 만나요')
                  : TextSpan(children: [
                      TextSpan(text: '${a.lateThresholdMinutes}분 넘게 늦으면 '),
                      TextSpan(text: penalty, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
              style: const TextStyle(fontSize: 13, color: AppColors.textBody),
            ),
          ),
        ],
      ]),
    );
  }
}

/// 당일에 쓸 수 있는 기능 안내. (위치는 2시간 전부터 도착까지만)
class _DayOfInfo extends StatelessWidget {
  const _DayOfInfo();

  static const _items = ['친구들이 어디쯤 왔는지 실시간으로 보기', '늦는 친구 콕 찌르기', '집에서 나오면 자동으로 출발 알림'];

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.pointSoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.point, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(kIsWeb ? '당일 지도는 앱에서 볼 수 있어요' : '약속 당일엔 이렇게 만나요',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
          const SizedBox(height: 14),
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                const Icon(Icons.check_box_rounded, size: 20, color: AppColors.point),
                const SizedBox(width: 10),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
              ]),
            ),
          const Divider(),
          const SizedBox(height: 10),
          const Text.rich(
            TextSpan(children: [
              TextSpan(text: '위치는 '),
              TextSpan(text: '약속 2시간 전부터 도착할 때까지만', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textBody)),
              TextSpan(text: ' 공유돼요.'),
            ]),
            style: TextStyle(fontSize: 12, color: AppColors.textSub),
          ),
        ]),
      );
}

class _InstallStatus extends StatelessWidget {
  const _InstallStatus({required this.appointment, required this.noAppIds});

  final Appointment appointment;
  final Set<String> noAppIds;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          AvatarStack(appointment.participants, max: 4, dashedIds: noAppIds),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${appointment.participants.length}명 중 ${noAppIds.length}명이 아직 앱이 없어요',
              style: const TextStyle(fontSize: 13, color: AppColors.textBody),
            ),
          ),
        ]),
      );
}

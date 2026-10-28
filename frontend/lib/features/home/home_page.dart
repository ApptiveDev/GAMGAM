import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/gam_colors.dart';
import '../../core/theme/gam_text.dart';
import '../../core/widgets/gam/countdown_text.dart';
import '../../core/widgets/gam/gam_icon.dart';
import '../../core/widgets/gam/photo_card.dart';
import '../../core/widgets/gam/pink_frame.dart';
import '../../data/models/appointment.dart';
import '../../data/repositories/appointment_repository.dart';
import '../shell/main_shell.dart';

/// 메인화면. 사과 위에 가장 가까운 약속까지 남은 시간, 아래에서 약속 카드가 올라온다.
/// 스크롤하면 카드 판이 사과를 덮고 "Hello" 문구와 로고가 흐려진다.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scroll = ScrollController();

  /// 첫 줄 카드가 화면 아래에서 이만큼만 보인다. (Figma: 748 높이에서 카드 시작 609)
  static const _peek = 139.0;

  /// 카드 판이 카드보다 이만큼 위에서 시작한다. 처음 화면에서는 사과를 가리지 않도록 짧게 두고,
  /// 스크롤하면 판이 함께 올라오며 사과를 덮는다.
  static const _panelLead = 40.0;

  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppointmentRepository>();
    final now = DateTime.now();
    final next = _nextAppointment(repo.myAppointments, now);
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    final fade = (1 - offset / 220).clamp(0.0, 1.0);

    return PinkFrame(
      fadeEnd: 0,
      child: LayoutBuilder(builder: (context, box) {
        final gridTop = box.maxHeight - _peek;
        return Stack(children: [
          // 사과
          Positioned(
            left: box.maxWidth / 2 + 123 - 475,
            top: 94,
            width: 950,
            height: 534.375,
            child: Opacity(opacity: (0.4 + fade * 0.6).clamp(0, 1), child: Image.asset('assets/figma/apple.gif', fit: BoxFit.cover)),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 4, 17, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Opacity(
                  opacity: fade,
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const SizedBox(width: 40, height: 40, child: Center(child: GamIcon('logo_gamgam', size: 32))),
                    const GamIcon('ic_more_vertical', size: 22),
                  ]),
                ),
                const SizedBox(height: 31),
                Opacity(
                  opacity: fade,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Hello,\n${repo.me.name}.', style: GamText.matrix(40).copyWith(height: 1.2)),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(_weekdays[now.weekday - 1], style: GamText.body16.copyWith(color: GamColors.onBlueSoft)),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          // 카운트다운
          Positioned(
            top: 385,
            right: 20,
            width: 200,
            child: Opacity(opacity: fade, child: _NextAppointment(appointment: next)),
          ),
          // 약속 카드 판
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scroll,
              child: Column(children: [
                SizedBox(height: gridTop - _panelLead),
                _CardPanel(
                  minHeight: box.maxHeight - (gridTop - _panelLead),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, _panelLead, 20, 150),
                    child: AppointmentGrid(children: [
                      for (final a in _sorted(repo.myAppointments))
                        AppointmentGridItem(
                          name: a.name,
                          image: a.imageAsset,
                          voting: a.isCoordinating,
                          onTap: () => context.push(AppRoutes.room(a.id)),
                        ),
                      AddAppointmentItem(onTap: () => pickGroupThenCreate(context)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ]);
      }),
    );
  }

  /// 아직 시작 안 한 확정 약속 중 가장 가까운 것.
  static Appointment? _nextAppointment(List<Appointment> all, DateTime now) {
    final upcoming = all.where((a) => a.isConfirmed && a.confirmedTime != null && a.confirmedTime!.isAfter(now)).toList()
      ..sort((a, b) => a.confirmedTime!.compareTo(b.confirmedTime!));
    return upcoming.firstOrNull;
  }

  /// 약속 전(가까운 순) → 지난 약속(최근 순).
  static List<Appointment> _sorted(List<Appointment> all) {
    final far = DateTime(9999);
    int byTime(Appointment a, Appointment b) => (a.time ?? far).compareTo(b.time ?? far);
    return [
      ...all.where((a) => !a.isCompleted).toList()..sort(byTime),
      ...all.where((a) => a.isCompleted).toList()..sort((a, b) => byTime(b, a)),
    ];
  }
}

class _NextAppointment extends StatelessWidget {
  const _NextAppointment({required this.appointment});

  final Appointment? appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final soft = GamText.body14.copyWith(fontSize: 15, color: GamColors.onBlueSoft, fontWeight: FontWeight.w400);
    if (a == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('예정된 약속이 없어요', style: soft),
        const SizedBox(height: 4),
        Text('--:--:--', style: GamText.matrix(48)),
      ]);
    }
    return GestureDetector(
      onTap: () => context.push(AppRoutes.room(a.id)),
      behavior: HitTestBehavior.opaque,
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: '${a.name} ', style: soft.copyWith(fontWeight: FontWeight.w700)),
            const TextSpan(text: '약속까지'),
          ]),
          style: soft,
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 4),
        CountdownText(target: a.confirmedTime!, style: GamText.matrix(48)),
        const SizedBox(height: 10),
        Text('더보기 >', style: GamText.body14.copyWith(color: GamColors.onBlueSoft)),
      ]),
    );
  }
}

/// 위 [_fade]만큼은 투명에서 회보라색으로 바뀌고, 그 아래는 회보라색인 판.
class _CardPanel extends StatelessWidget {
  const _CardPanel({required this.child, required this.minHeight});

  final Widget child;
  final double minHeight;

  static const _fade = 40.0;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Stack(children: [
          const Positioned.fill(top: _fade, child: ColoredBox(color: GamColors.canvas)),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _fade,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00D7D9E6), GamColors.canvas],
                ),
              ),
            ),
          ),
          child,
        ]),
      );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/layout.dart';
import '../../data/models/live_location.dart';
import '../../data/repositories/live_location_repository.dart';
import 'widgets/share_level_card.dart';

/// 06 · 위치 공유 설정 — 방마다 처음 한 번, 이후엔 내정보에서 바꾼다.
/// 겁주지 않고 차분하게. '언제 켜지는지'를 타임라인으로 보여준다.
class LocationSettingPage extends StatefulWidget {
  const LocationSettingPage({super.key, required this.appointmentId, this.thenLiveMap = false});

  final String appointmentId;

  /// 당일 지도로 가는 길에 들렀으면 고른 뒤 지도로 넘어간다. 아니면 이전 화면으로 돌아간다.
  final bool thenLiveMap;

  @override
  State<LocationSettingPage> createState() => _LocationSettingPageState();
}

class _LocationSettingPageState extends State<LocationSettingPage> {
  late ShareLevel _selected = context.read<LiveLocationRepository>().shareLevelOf(widget.appointmentId) ?? ShareLevel.recommended;
  bool _saving = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const BackAppBar(),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          children: [
            const PageTitle('이 방에서 내 위치를\n어디까지 보여줄까요?', subtitle: '언제든 바꿀 수 있어요. 방마다 따로 설정돼요.'),
            const SizedBox(height: 20),
            for (final level in ShareLevel.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: ShareLevelCard(
                  level: level,
                  selected: level == _selected,
                  recommended: level == ShareLevel.recommended,
                  onTap: () => setState(() => _selected = level),
                ),
              ),
            const SizedBox(height: 11),
            const _SharingWindow(),
            const SizedBox(height: 14),
            const Text('내정보 › 방별 위치 공유에서 언제든 바꿀 수 있어요.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
        bottomNavigationBar: BottomCta(children: [
          FilledButton(onPressed: _saving ? null : _save, child: const Text('이걸로 할게요')),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _saving ? null : _next,
            style: TextButton.styleFrom(foregroundColor: AppColors.textSub),
            child: const Text('나중에 정하기'),
          ),
        ]),
      );

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<LiveLocationRepository>().setShareLevel(widget.appointmentId, _selected);
    if (mounted) _next();
  }

  /// '나중에 정하기'는 저장하지 않는다. 그동안은 권장값(기본)으로 보이고, 다음에 들어올 때 다시 묻는다.
  void _next() {
    if (widget.thenLiveMap) {
      context.pushReplacement(AppRoutes.liveMap(widget.appointmentId));
    } else {
      context.pop();
    }
  }
}

/// "약속 2시간 전부터 도착할 때까지만" 타임라인.
class _SharingWindow extends StatelessWidget {
  const _SharingWindow();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            '약속 2시간 전부터 도착할 때까지만 켜져요.\n평소엔 공유되지 않아요.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textBody, height: 1.6),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: const SizedBox(
              height: 6,
              // 자식 없는 ColoredBox는 높이가 0이 되므로 세로로 꽉 채운다.
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(flex: 16, child: ColoredBox(color: AppColors.divider)),
                Expanded(flex: 10, child: ColoredBox(color: AppColors.point)),
                Expanded(flex: 16, child: ColoredBox(color: AppColors.divider)),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('평소 — 꺼짐', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text('2시간 전 ~ 도착', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.point)),
            Text('이후 — 꺼짐', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ]),
        ]),
      );
}

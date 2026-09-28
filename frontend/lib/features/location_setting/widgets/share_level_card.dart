import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/live_location.dart';

/// 공개 범위 라디오 카드. 왼쪽 미리보기가 친구들에게 어떻게 보이는지 보여준다.
class ShareLevelCard extends StatelessWidget {
  const ShareLevelCard({super.key, required this.level, required this.selected, required this.recommended, required this.onTap});

  final ShareLevel level;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.pointSoft : AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? AppColors.point : AppColors.border, width: selected ? 1.8 : 1.2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.square(dimension: 64, child: CustomPaint(painter: _PreviewPainter(level))),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(level.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
                    if (recommended) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.point, borderRadius: BorderRadius.circular(4)),
                        child: const Text('권장', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(level.description, style: const TextStyle(fontSize: 12, color: AppColors.textSub, height: 1.5)),
                ]),
              ),
              const SizedBox(width: 8),
              _RadioDot(selected: selected),
            ]),
          ),
        ),
      );
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.point : null,
          border: selected ? null : Border.all(color: AppColors.borderStrong, width: 1.6),
        ),
        child: selected ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)) : null,
      );
}

/// 추상 지도(십자 도로) 위에 공개 범위를 그린다. 끔 = 빈 지도, 기본 = 대략적인 영역, 친한 방 = 정확한 점.
class _PreviewPainter extends CustomPainter {
  const _PreviewPainter(this.level);

  final ShareLevel level;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.surface);
    final road = Paint()..color = AppColors.divider;
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.4, size.width, 5), road);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.47, 0, 5, size.height), road);

    final center = Offset(size.width / 2, size.height / 2);
    switch (level) {
      case ShareLevel.off:
        break;
      case ShareLevel.basic:
        canvas.drawCircle(center, 16, Paint()..color = AppColors.point.withValues(alpha: 0.18));
        canvas.drawCircle(
          center,
          16,
          Paint()
            ..color = AppColors.point
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      case ShareLevel.close:
        canvas.drawCircle(center.translate(0, -3), 6.5, Paint()..color = AppColors.textSub);
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) => oldDelegate.level != level;
}

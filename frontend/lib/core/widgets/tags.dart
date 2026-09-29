import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 포인트 컬러로 채운 pill. ("● 위치 공유 중", "권장")
class PointBadge extends StatelessWidget {
  const PointBadge(this.label, {super.key, this.dot = false});

  final String label;
  final bool dot;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: AppColors.point, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (dot) ...[
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
}

/// 포인트 컬러 아웃라인 태그. ("조율 중")
class OutlineTag extends StatelessWidget {
  const OutlineTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(border: Border.all(color: AppColors.point), borderRadius: BorderRadius.circular(5)),
        child: Text(label, style: const TextStyle(color: AppColors.point, fontSize: 11, fontWeight: FontWeight.w500)),
      );
}

/// 회색 pill. ("약속이 확정됐어요")
class SoftBadge extends StatelessWidget {
  const SoftBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textBody)),
      );
}

/// 장소 사진 자리 (줄무늬 사각형).
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox.square(dimension: size, child: const CustomPaint(painter: _StripePainter())),
      );
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.surface);
    final stripe = Paint()
      ..color = AppColors.surfaceStrong
      ..strokeWidth = 5;
    for (double x = -size.height; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), stripe);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 점선 테두리. "+ 다른 시간 제안하기", 지난 약속 카드, 미설치 아바타 등에 쓴다.
class DashedBorder extends StatelessWidget {
  const DashedBorder({super.key, required this.child, this.radius = 14, this.color = AppColors.borderStrong});

  final Widget child;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DashedPainter(radius: radius, color: color), child: child);
}

class _DashedPainter extends CustomPainter {
  _DashedPainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) => old.radius != radius || old.color != color;
}

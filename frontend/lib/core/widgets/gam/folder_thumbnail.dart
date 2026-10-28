import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/gam_colors.dart';

/// 그룹 폴더: 뒷판 + 꽂힌 약속 사진(최대 3장) + 반투명 앞판.
/// 기준 크기는 그룹 상세의 209.85×159.56. 그룹 목록(149 폭)은 [width]만 바꿔 같은 비율로 줄인다.
class FolderThumbnail extends StatelessWidget {
  const FolderThumbnail({super.key, required this.images, this.width = _baseWidth});

  /// 앞에서부터 가운데·오른쪽·왼쪽 순서로 꽂힌다.
  final List<String> images;
  final double width;

  static const _baseWidth = 209.849;
  static const _baseHeight = 159.563;

  /// 사진 수별 배치 (left, top, 회전 각도). Figma "그룹(메인)1~4" 그대로.
  static const _layouts = <List<(double, double, double)>>[
    [],
    [(90.33, 17.0, 5.23)],
    [(107.24, 30.42, 18.0), (45.86, 10.18, -8.43)],
    [(69.61, 0, 0), (126.76, 35.6, 23.0), (13.24, 37.47, -19.0)],
  ];

  @override
  Widget build(BuildContext context) {
    final s = width / _baseWidth;
    final shown = images.take(3).toList();
    final layout = _layouts[shown.length];

    return SizedBox(
      width: width,
      height: _baseHeight * s,
      child: Stack(clipBehavior: Clip.none, children: [
        // 뒷판
        Positioned(
          left: 30.4 * s,
          top: 23.2 * s,
          width: 152.019 * s,
          height: 136.017 * s,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11.668 * s),
              border: Border.all(color: const Color(0xFFC8C8C8), width: 1.408 * s),
              gradient: const RadialGradient(
                center: Alignment(0, -0.7),
                radius: 1.1,
                colors: [Color(0xFFD2D3D8), Color(0xFFDADBDF)],
              ),
              boxShadow: [BoxShadow(color: const Color(0x14212121), blurRadius: 3 * s, offset: Offset(0, 3 * s))],
            ),
          ),
        ),
        for (final (i, (left, top, angle)) in layout.indexed)
          Positioned(
            left: left * s,
            top: top * s,
            child: Transform.rotate(
              angle: angle * math.pi / 180,
              child: _MiniCard(image: shown[i], scale: s),
            ),
          ),
        // 앞판 (뒤가 비치는 유리)
        Positioned(
          left: 18.4 * s,
          top: 30.4 * s,
          width: 173.987 * s,
          height: 129.159 * s,
          child: _FolderFront(scale: s),
        ),
      ]),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.image, required this.scale});

  final String image;
  final double scale;

  @override
  Widget build(BuildContext context) => Container(
        width: 68.809 * scale,
        height: 92.812 * scale,
        padding: EdgeInsets.all(4.225 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.802 * scale),
          border: Border.all(color: GamColors.cardOutline, width: 1.408 * scale),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4 * scale),
          child: Image.asset(image, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
        ),
      );
}

class _FolderFront extends StatelessWidget {
  const _FolderFront({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: const _FolderFrontClipper(),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8 * scale, sigmaY: 8 * scale),
          child: CustomPaint(painter: const _FolderFrontPainter(), size: Size.infinite),
        ),
      );
}

/// 앞판 외곽선. Figma "Rectangle 6702" 경로 (173.987×129.159 기준).
Path _folderFrontPath(Size size) {
  final sx = size.width / 173.987;
  final sy = size.height / 129.159;
  return Path()
    ..moveTo(0.0275 * sx, 12.461 * sy)
    ..cubicTo(-0.4318 * sx, 5.7205 * sy, 4.9122 * sx, 0, 11.6683 * sx, 0)
    ..lineTo(63.5713 * sx, 0)
    ..cubicTo(66.6517 * sx, 0, 69.607 * sx, 1.2181 * sy, 71.7928 * sx, 3.3886 * sy)
    ..lineTo(84.0006 * sx, 15.5113 * sy)
    ..cubicTo(86.1732 * sx, 17.6687 * sy, 89.1067 * sx, 18.8857 * sy, 92.1685 * sx, 18.8998 * sy)
    ..lineTo(162.372 * sx, 19.2224 * sy)
    ..cubicTo(169.162 * sx, 19.2536 * sy, 174.491 * sx, 25.0533 * sy, 173.949 * sx, 31.8216 * sy)
    ..lineTo(167.013 * sx, 118.423 * sy)
    ..cubicTo(166.527 * sx, 124.486 * sy, 161.465 * sx, 129.159 * sy, 155.382 * sx, 129.159 * sy)
    ..lineTo(18.8793 * sx, 129.159 * sy)
    ..cubicTo(12.7432 * sx, 129.159 * sy, 7.6557 * sx, 124.407 * sy, 7.2385 * sx, 118.285 * sy)
    ..close();
}

class _FolderFrontClipper extends CustomClipper<Path> {
  const _FolderFrontClipper();

  @override
  Path getClip(Size size) => _folderFrontPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _FolderFrontPainter extends CustomPainter {
  const _FolderFrontPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = _folderFrontPath(size);
    final rect = Offset.zero & size;
    final sy = size.height / 129.159;

    // 위는 거의 투명, 아래로 갈수록 불투명해지는 유리.
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCCF0F1F6), Color(0xCCF0F1F6), Color(0xFFE6E6E6)],
          stops: [0, 0.667, 1],
        ).createShader(rect),
    );
    // 아래쪽 두 줄 하이라이트 (접힌 자국).
    for (final (top, bottom, opacity) in [(109.852, 125.83, 0.56), (102.307, 118.729, 0.34)]) {
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: opacity),
              const Color(0xFFE6E6E6).withValues(alpha: opacity),
              const Color(0xFFF0F1F6).withValues(alpha: opacity),
              const Color(0xFFF0F1F6).withValues(alpha: 0),
            ],
            stops: const [0, 0.395, 0.666, 0.712, 1],
          ).createShader(Rect.fromLTRB(0, top * sy, size.width, bottom * sy)),
      );
    }
    // 가장자리 그늘.
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          radius: 0.83,
          colors: const [Color(0x00E6E6E6), Color(0xFFCAD3D6)],
          stops: const [0.75, 1],
          transform: _StretchTransform(size.height / size.width),
        ).createShader(rect),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * sy
        ..color = GamColors.photoOutline,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 원형 그라데이션을 앞판 비율대로 납작하게 편다.
class _StretchTransform extends GradientTransform {
  const _StretchTransform(this.ratio);

  final double ratio;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final center = bounds.center;
    return Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(1, ratio * 1.5, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
  }
}

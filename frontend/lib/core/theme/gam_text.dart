import 'package:flutter/material.dart';

import 'gam_colors.dart';

/// 글꼴. 한글은 Pretendard, "Hello, there."·카운트다운 같은 도트 글자는 Matrix Sans Screen.
/// 파일은 assets/fonts/ 에 있고 pubspec.yaml 의 fonts 에 등록돼 있다.
abstract final class GamFonts {
  static const pretendard = 'Pretendard';
  static const matrix = 'MatrixSansScreen';
}

/// Figma 텍스트 스타일. 이름은 크기·굵기 그대로 붙인다. 자간은 디자인 전체가 -0.3.
abstract final class GamText {
  static TextStyle _p(double size, FontWeight weight, Color color, {double height = 1}) => TextStyle(
        fontFamily: GamFonts.pretendard,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: -0.3,
      );

  static TextStyle matrix(double size, {Color color = Colors.white}) =>
      TextStyle(fontFamily: GamFonts.matrix, fontSize: size, color: color, height: 1, letterSpacing: -0.3);

  static final title24 = _p(24, FontWeight.w700, Colors.white);
  static final title20 = _p(20, FontWeight.w600, Colors.white);
  static final section16 = _p(16, FontWeight.w600, GamColors.text900);
  static final body16 = _p(16, FontWeight.w500, GamColors.text900);
  static final name15 = _p(15, FontWeight.w500, GamColors.text800);
  static final body14 = _p(14, FontWeight.w500, GamColors.text800);
  static final button14 = _p(14, FontWeight.w600, GamColors.text900);
  static final body13 = _p(13, FontWeight.w500, GamColors.text900);
  static final regular13 = _p(13, FontWeight.w400, GamColors.text600);
  static final regular12 = _p(12, FontWeight.w400, GamColors.text500);
  static final caption12 = _p(12, FontWeight.w500, GamColors.text600);
  static final button12 = _p(12, FontWeight.w600, GamColors.text900);
  static final chip11 = _p(11, FontWeight.w600, GamColors.text900);
  static final meta11 = _p(11, FontWeight.w500, GamColors.text600);
  static final dot11 = _p(11, FontWeight.w900, GamColors.text400);
}

import 'package:flutter/material.dart';

/// 와이어프레임 디자인 토큰.
/// 포인트 컬러는 하나만 쓰고, 강조가 꼭 필요한 곳(주요 CTA, 카운트다운, 선택 상태)에만 쓴다.
abstract final class AppColors {
  static const point = Color(0xFFE5533D);
  static const pointSoft = Color(0xFFFDF6F4);

  static const canvas = Color(0xFFEFEDE9);
  static const background = Color(0xFFFFFFFF);
  static const card = Color(0xFFFAF9F7);
  static const surface = Color(0xFFF5F4F1);
  static const surfaceStrong = Color(0xFFEFEDEA);
  static const avatar = Color(0xFFDEDBD6);

  static const border = Color(0xFFDCD9D4);
  static const borderStrong = Color(0xFFC9C6C1);
  static const borderCard = Color(0xFFB9B5AF);
  static const divider = Color(0xFFE4E1DD);

  static const textTitle = Color(0xFF2B2A28);
  static const textBody = Color(0xFF3F3C39);
  static const textSub = Color(0xFF7A756E);
  static const textMuted = Color(0xFFACA8A2);
}

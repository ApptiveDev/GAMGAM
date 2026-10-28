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

/// 새 디자인(#16 당일 지도) 팔레트. 실제 색 값만 두고, 화면에서는 아래 역할 토큰을 쓴다.
/// 다른 화면이 리디자인되면 [AppColors.point]도 이 팔레트로 옮긴다.
abstract final class AppPalette {
  static const pink = Color(0xFFF8AFFE);
  static const blue = Color(0xFF6FAEFF);
  static const blueHalo = Color(0x85BCDAFF);
  static const lavenderGray = Color(0xFFD7D9E6);

  static const gray900 = Color(0xFF212121);
  static const gray800 = Color(0xFF424242);
  static const gray600 = Color(0xFF666666);
  static const gray500 = Color(0xFF999999);
  static const gray400 = Color(0xFFCDCDCD);
  static const gray300 = Color(0xFFDBDBDB);
  static const gray200 = Color(0xFFEDEDED);
}

/// 당일 지도 화면의 역할 토큰.
abstract final class LiveColors {
  /// 콕 찌르기 같은 주요 액션 배경. 위 글자는 [onAccent](흰 글자 아님).
  static const accent = AppPalette.pink;
  static const onAccent = AppPalette.gray900;

  /// 쿨다운·등수·편집처럼 누를 수 없거나 덜 중요한 pill.
  static const muted = AppPalette.gray200;
  static const onMuted = AppPalette.gray400;

  /// 선택된 마커 테두리와 후광.
  static const selected = AppPalette.blue;
  static const selectedHalo = AppPalette.blueHalo;

  static const textStrong = AppPalette.gray900;
  static const textBody = AppPalette.gray800;
  static const textSub = AppPalette.gray600;
  static const textHint = AppPalette.gray500;
  static const textFaint = Color(0x99666666);

  static const outline = AppPalette.gray800;
  static const border = AppPalette.gray300;
  static const handle = AppPalette.lavenderGray;
  static const sharingOffOverlay = Color(0xB3DBDBDB);
  static const shadow = Color(0x33212121);
}

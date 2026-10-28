import 'package:flutter/material.dart';

/// Figma "디자인 컨셉" 토큰. 새 화면(홈·그룹·약속 상세)은 이것만 쓴다.
/// [AppColors]는 지도·위치 공유 등 기존 화면이 계속 쓰므로 그대로 둔다.
abstract final class GamColors {
  /// 화면 테두리와 주요 버튼의 분홍.
  static const pink = Color(0xFFF8AFFE);
  static const pinkStrong = Color(0xFFF79CFF);

  /// 배경 그라데이션이 끝나는 회보라색. 화면 바탕.
  static const canvas = Color(0xFFD7D9E6);

  /// 투표·정보 카드.
  static const card = Color(0xFFD2D4E0);
  static const cardBorder = Color(0xFFC3C5D0);
  static const cardButton = Color(0xFFC8CAD5);
  static const voteTrack = Color(0xFFC6C8D2);

  /// 약속 이름 옆 "변경", 그룹 멤버 "+" 처럼 파란 배경 위의 작은 버튼.
  static const blueChip = Color(0xFF9EB5CD);
  static const blueChipBorder = Color(0xFF92A4B6);

  /// 그룹 검색창.
  static const searchField = Color(0xFF88BEE3);
  static const searchChip = Color(0xFFB5D6ED);
  static const searchChipText = Color(0xFF8E9DA4);
  static const searchSortBorder = Color(0xFF6C92AD);

  static const surface = Color(0xFFF0F1F6);
  static const surfaceSoft = Color(0xFFF0F0F4);
  static const countPill = Color(0xFFEBECEE);
  static const sortBorder = Color(0xFFBFC0CA);
  static const chipIdle = Color(0x8CFFFFFF);
  static const lineSoft = Color(0xFFEFEFF2);

  static const text900 = Color(0xFF212121);
  static const text800 = Color(0xFF424242);
  static const text600 = Color(0xFF666666);
  static const text500 = Color(0xFF797979);
  static const text400 = Color(0xFF999999);
  static const text300 = Color(0xFF98989A);
  static const cardOutline = Color(0xFF797979);
  static const photoOutline = Color(0xFFCDCDCD);
  static const placeholder = Color(0xFFEDEDED);

  static const onBlueSoft = Color(0xC7FFFFFF);
  static const onBlueTitle = Color(0xFFECF4FA);
  static const nameUnderline = Color(0xFFAFBCCB);
  static const outlineButton = Color(0xFFC2C6D2);
}

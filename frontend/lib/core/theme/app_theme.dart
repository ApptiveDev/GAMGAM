import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'gam_colors.dart';
import 'gam_text.dart';

abstract final class AppTheme {
  /// Figma "디자인 컨셉" 테마. 앱 기본값.
  static ThemeData get gam {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: GamFonts.pretendard,
      colorScheme: ColorScheme.fromSeed(seedColor: GamColors.pink, primary: GamColors.text900, surface: GamColors.surface),
      scaffoldBackgroundColor: GamColors.pink,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: GamColors.text900, displayColor: GamColors.text900),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.white, selectionColor: Color(0x55FFFFFF)),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: GamColors.text900,
        contentTextStyle: GamText.body13.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: GamColors.surface, surfaceTintColor: Colors.transparent),
    );
  }

  /// 와이어프레임 시절 테마. 지도·위치 공유·도착·벌칙·초대·내정보 화면은 디자인이 나오기 전까지 이걸로 그린다.
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.point,
        primary: AppColors.point,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textBody,
        displayColor: AppColors.textTitle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textSub,
        elevation: 0,
        titleSpacing: 0,
        titleTextStyle: TextStyle(fontSize: 16, color: AppColors.textSub),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.point,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceStrong,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textTitle,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.point, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        height: 74,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? AppColors.point : AppColors.textMuted),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(fontSize: 12, color: states.contains(WidgetState.selected) ? AppColors.point : AppColors.textMuted),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

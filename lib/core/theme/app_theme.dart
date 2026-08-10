import 'package:flutter/material.dart';

import 'package:notebook_pro/core/theme/app_colors.dart';
import 'package:notebook_pro/core/theme/gamification_colors.dart';

/// Theme factory — Graphite & Signal.
///
/// Reading stack (bundled, offline-safe):
/// - **Literata** — designed by TypeTogether for Google Play Books; strong
///   reviews for long-form screen reading (clear forms, comfortable contrast).
/// - **Source Sans 3** — Adobe’s open UI/sans companion; calm chrome text.
abstract final class AppTheme {
  static const readingFamily = 'Literata';
  static const uiFamily = 'SourceSans3';

  static TextTheme _textTheme(Color primary, Color secondary) {
    TextStyle reading(double size, double height, FontWeight weight) {
      return TextStyle(
        fontFamily: readingFamily,
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        letterSpacing: -0.15,
        color: primary,
      );
    }

    TextStyle ui(
      double size,
      double height,
      FontWeight weight,
      Color color, {
      double letterSpacing = 0,
    }) {
      return TextStyle(
        fontFamily: uiFamily,
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
      );
    }

    return TextTheme(
      displayLarge: reading(32, 40, FontWeight.w600),
      headlineLarge: reading(28, 36, FontWeight.w500),
      headlineMedium: reading(18, 26, FontWeight.w500),
      titleLarge: ui(20, 28, FontWeight.w600, primary),
      titleMedium: ui(17, 24, FontWeight.w600, primary),
      // Body sized for sustained reading (~16px / 1.55).
      bodyLarge: reading(16, 25, FontWeight.w400),
      bodyMedium: ui(14, 20, FontWeight.w500, primary),
      bodySmall: ui(13, 18, FontWeight.w400, secondary),
      labelSmall: ui(12, 16, FontWeight.w500, secondary, letterSpacing: 0.2),
    );
  }

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.signalBlueLight,
      onPrimary: Colors.white,
      secondary: AppColors.ember,
      onSecondary: Colors.white,
      surface: AppColors.lightPanel,
      onSurface: AppColors.lightTextPrimary,
      error: AppColors.danger,
      outline: AppColors.lightBorder,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: uiFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.lightCanvas,
      textTheme: _textTheme(
        AppColors.lightTextPrimary,
        AppColors.lightTextSecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightPanel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.lightTextPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightTextSecondary,
        size: 18,
      ),
      extensions: const [GamificationColors.light],
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.signalBlueDark,
      onPrimary: Colors.black,
      secondary: AppColors.emberDark,
      onSecondary: Colors.black,
      surface: AppColors.darkPanel,
      onSurface: AppColors.darkTextPrimary,
      error: AppColors.danger,
      outline: AppColors.darkBorder,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: uiFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkCanvas,
      textTheme: _textTheme(
        AppColors.darkTextPrimary,
        AppColors.darkTextSecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkPanel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.darkTextPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.darkTextSecondary,
        size: 18,
      ),
      extensions: const [GamificationColors.dark],
    );
  }
}

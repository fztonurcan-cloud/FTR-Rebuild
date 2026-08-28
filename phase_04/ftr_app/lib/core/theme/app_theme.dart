import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => dark;

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary600,
      brightness: Brightness.dark,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: AppColors.primary600,
        secondary: AppColors.primary500,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.border,
      splashColor: AppColors.primary600.withValues(alpha: .10),
      highlightColor: AppColors.primary600.withValues(alpha: .05),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 30,
          height: 1.16,
          fontWeight: FontWeight.w800,
          letterSpacing: -.4,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 25,
          height: 1.2,
          fontWeight: FontWeight.w800,
          letterSpacing: -.25,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 1.28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16.5,
          height: 1.32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.62,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.52,
          color: AppColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.45,
          color: AppColors.textMuted,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSoft,
        hintStyle: TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.primary600, width: 1.4),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 70,
        backgroundColor: AppColors.sidebar,
        indicatorColor: AppColors.primary100,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.sidebar,
        indicatorColor: AppColors.primary100,
        selectedIconTheme: IconThemeData(color: AppColors.primary500),
        unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary600,
        linearTrackColor: AppColors.primary100,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

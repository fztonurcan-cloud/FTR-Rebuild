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
        secondary: AppColors.primary700,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.border,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          height: 1.25,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.58,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.45,
          color: AppColors.textSecondary,
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
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.primary600, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary100,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary100,
        selectedIconTheme: IconThemeData(color: AppColors.primary600),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}

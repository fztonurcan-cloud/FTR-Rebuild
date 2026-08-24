import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary700,
      brightness: Brightness.light,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: AppColors.primary700,
        secondary: AppColors.primary600,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontSize: 24, height: 1.25, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontSize: 17, height: 1.3, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontSize: 15, height: 1.47, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: AppColors.textSecondary),
        labelMedium: TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w600),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary100,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

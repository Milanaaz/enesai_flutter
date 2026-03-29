import 'package:flutter/material.dart';
import 'package:dipl/app/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimary,
        brightness: Brightness.light,
      ),
    );
  }
}

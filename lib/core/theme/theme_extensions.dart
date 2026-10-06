import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-aware helpers — single source of truth for light/dark resolution.
/// Use via `context.isDark`, `context.bg`, `context.surface`, etc.
extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bg => Theme.of(this).scaffoldBackgroundColor;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get surfaceHigh =>
      isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh;
  Color get surfaceLight =>
      isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight;
  Color get border => isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get cardBorder =>
      isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
  Color get dividerColor =>
      isDark ? AppColors.darkDivider : AppColors.lightDivider;
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textMuted =>
      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
}

extension ColorSchemeX on ColorScheme {
  bool get isDark => brightness == Brightness.dark;
}

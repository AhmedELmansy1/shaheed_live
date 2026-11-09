import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware helpers — single source of truth for Paper × Ink × Vermilion resolution.
/// Use via `context.colors`, `context.isDark`, `context.bg`, `context.surface`, etc.
extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  AppThemeColors get colors =>
      Theme.of(this).extension<AppThemeColors>() ??
      (isDark ? AppThemeColors.dark : AppThemeColors.light);

  Color get bg => colors.background;
  Color get surface => colors.surface;
  Color get surfaceElevated => colors.surfaceElevated;
  Color get surfaceHigh => colors.surfaceElevated;
  Color get surfaceLight => colors.surfaceElevated;
  Color get border => colors.border;
  Color get cardBorder => colors.border;
  Color get dividerColor => colors.divider;
  Color get textPrimary => colors.textPrimary;
  Color get textSecondary => colors.textSecondary;
  Color get textMuted => colors.textMuted;
  Color get vermilion => colors.vermilion;
  Color get live => colors.vermilion;
  Color get upcoming => colors.upcoming;
  Color get finished => colors.finished;
}

extension ColorSchemeX on ColorScheme {
  bool get isDark => brightness == Brightness.dark;
}

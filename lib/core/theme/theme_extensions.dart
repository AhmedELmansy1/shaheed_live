import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design Token Typography — Context extension for semantic access.
/// Access theme-aware colors through BuildContext extensions.
extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  AppThemeColors get colors =>
      Theme.of(this).extension<AppThemeColors>() ??
      (isDark ? AppThemeColors.dark : AppThemeColors.light);

  // ─── Surfaces ─────────────────────────────────────────────────────────────
  Color get bg => colors.background;
  Color get surface => colors.surface;
  Color get surfaceElevated => colors.surfaceElevated;
  Color get surfaceHigh => colors.surfaceRaised;
  Color get surfaceLight => colors.surfaceElevated;
  Color get surfaceRaised => colors.surfaceRaised;

  // ─── Borders ──────────────────────────────────────────────────────────────
  Color get border => colors.border;
  Color get cardBorder => colors.border;
  Color get dividerColor => colors.divider;

  // ─── Text ─────────────────────────────────────────────────────────────────
  Color get textPrimary => colors.textPrimary;
  Color get textSecondary => colors.textSecondary;
  Color get textMuted => colors.textMuted;

  // ─── Brand ────────────────────────────────────────────────────────────────
  /// Electric blue primary — CTAs, selected nav, indicators.
  Color get primary => colors.primary;

  /// Red-orange live badge. NOT for success/win.
  Color get live => colors.live;

  /// Backward-compat: `vermilion` resolves to `live` (red-orange).
  Color get vermilion => colors.live;

  Color get warning => colors.warning;
  Color get info => colors.info;
  Color get danger => colors.danger;

  // ─── Match status ─────────────────────────────────────────────────────────
  Color get upcoming => colors.upcoming;
  Color get finished => colors.finished;
}

extension ColorSchemeX on ColorScheme {
  bool get isDark => brightness == Brightness.dark;
}

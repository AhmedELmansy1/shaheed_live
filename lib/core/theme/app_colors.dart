import 'package:flutter/material.dart';

/// Design tokens for the "Midnight Stadium" design system.
///
/// Dark-first, polished light theme.
/// Brand identity: deep midnight, white arcs, one red-orange live dot.
/// Reference aesthetic: Apple Sports / FotMob / Linear — restraint, precision,
/// generous spacing, one confident accent, motion that feels expensive.
///
/// RULE: NO green anywhere — not success states, not pitch field, nothing.
/// Win states use primary blue. Success states use ice-blue info color.
class AppColors {
  // ─── Dark Palette — "Midnight Stadium Dark" ───────────────────────────────

  static const Color darkBackground = Color(0xFF0A0F1E);
  static const Color darkSurface = Color(0xFF111830);
  static const Color darkSurfaceElevated = Color(0xFF17203F);
  static const Color darkSurfaceHigh = Color(0xFF1E2950);
  static const Color darkSurfaceLight = Color(0xFF17203F);
  static const Color darkBorder = Color(0xFF223056);
  static const Color darkCardBorder = Color(0xFF223056);
  static const Color darkDivider = Color(0xFF223056);

  static const Color darkTextPrimary = Color(0xFFF4F6FB);
  static const Color darkTextSecondary = Color(0xFFA9B4D0);
  static const Color darkTextMuted = Color(0xFF8392B3);

  /// Electric blue — primary action, selected nav, indicators.
  static const Color darkPrimary = Color(0xFF3D7BFF);
  static const Color darkPrimaryContainer = Color(0xFF172A66);
  static const Color darkOnPrimary = Color(0xFFFFFFFF);

  /// Red-orange — live badge, live dot, live score. NOT for success/win.
  static const Color darkLive = Color(0xFFFF4D3D);

  /// Amber — postponed, warnings.
  static const Color darkWarning = Color(0xFFFFB020);

  /// Ice-blue — info banners, secondary actions, positive/success states.
  static const Color darkInfo = Color(0xFF7FB2FF);

  /// Danger — errors, destructive actions.
  static const Color darkDanger = Color(0xFFFF6B6B);

  // ─── Light Palette — "Midnight Stadium Light" ─────────────────────────────

  static const Color lightBackground = Color(0xFFF4F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE3E8F3);
  static const Color lightCardBorder = Color(0xFFE3E8F3);
  static const Color lightDivider = Color(0xFFE3E8F3);

  static const Color lightTextPrimary = Color(0xFF0B1226);
  static const Color lightTextSecondary = Color(0xFF4A5878);
  static const Color lightTextMuted = Color(0xFF5F6C8A);

  static const Color lightPrimary = Color(0xFF1F5FE0);
  static const Color lightPrimaryContainer = Color(0xFFE6EEFF);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);

  static const Color lightLive = Color(0xFFC02A20);
  static const Color lightWarning = Color(0xFFB26A00);
  static const Color lightInfo = Color(0xFF1F5FE0);
  static const Color lightDanger = Color(0xFFC02A20);

  // ─── Signature Gradients (use SPARINGLY) ──────────────────────────────────

  /// Allowed: hero match card, primary CTA, avatar rings.
  /// Banned: full-screen bg, repeated cards, list items.
  static const LinearGradient signatureGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2B3FD6), Color(0xFF0F1B5C)],
  );

  static const LinearGradient signatureGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F5FE0), Color(0xFF172A66)],
  );

  /// Backward-compat aliases used by existing hero card code.
  static const LinearGradient brandGradient = signatureGradientDark;
  static const LinearGradient primaryGradient = signatureGradientDark;

  // ─── Form Result Indicators ───────────────────────────────────────────────
  // W = primary blue tonal | D = neutral | L = live red. NEVER green for W.

  static const Color darkWinBg = Color(0xFF172A66);
  static const Color darkWinText = Color(0xFF3D7BFF);
  static const Color darkDrawBg = Color(0xFF17203F);
  static const Color darkDrawText = Color(0xFF8392B3);
  static const Color darkLossBg = Color(0x33FF4D3D);
  static const Color darkLossText = Color(0xFFFF4D3D);

  static const Color lightWinBg = Color(0xFFE6EEFF);
  static const Color lightWinText = Color(0xFF1F5FE0);
  static const Color lightDrawBg = Color(0xFFF4F6FB);
  static const Color lightDrawText = Color(0xFF5F6C8A);
  static const Color lightLossBg = Color(0x22D4342A);
  static const Color lightLossText = Color(0xFFD4342A);

  // ─── Shimmer / Skeleton ───────────────────────────────────────────────────

  static const Color darkShimmerBase = Color(0xFF17203F);
  static const Color darkShimmerHighlight = Color(0xFF1E2950);
  static const Color lightShimmerBase = Color(0xFFE3E8F3);
  static const Color lightShimmerHighlight = Color(0xFFF4F6FB);

  // ─── Pitch field (neutral, NO green) ─────────────────────────────────────

  /// Neutral ink — used for lineup pitch background (never green).
  static const Color pitchNeutral = darkSurface;
  static const Color pitchNeutralLight = lightSurface;
  static const Color pitchLine = Color(0xFF223056);
  static const Color pitchLineLight = Color(0xFFE3E8F3);

  // ─── Backward-compat aliases ──────────────────────────────────────────────
  // These ensure existing widgets compile without changes.

  /// @deprecated Use context.colors.primary (blue) instead.
  static const Color vermilion = darkLive;
  static const Color primary = darkPrimary;
  static const Color secondary = darkPrimary;
  static const Color live = darkLive;
  static const Color livePulse = darkLive;
  static const Color liveIndicator = darkLive;

  /// @deprecated Never green! Use info (ice-blue) for success states.
  static const Color success = darkInfo;

  static const Color gold = Color(0xFFD97706);
  static const Color goldGlow = Color(0x33D97706);

  static const Color accentCyan = darkInfo;
  static const Color accentBlue = darkPrimary;
  static const Color divider = darkDivider;

  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color surfaceHigh = darkSurfaceHigh;
  static const Color surfaceElevated = darkSurfaceElevated;
  static const Color surfaceLight = darkSurfaceLight;
  static const Color border = darkBorder;
  static const Color cardBorder = darkBorder;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;

  static const Color primaryGlow = Color(0x223D7BFF);
  static const Color secondaryGlow = Color(0x223D7BFF);
  static const Color liveGlowColor = Color(0x22FF4D3D);

  /// Legacy names for surface levels.
  static const Color darkSurfaceRaised = darkSurfaceHigh;
  static const Color lightSurfaceRaised = lightSurfaceHigh;

  // ─── Pitch (old names) ────────────────────────────────────────────────────
  static const Color pitchGreen = darkSurface;
  static const Color pitchGreenLight = darkSurfaceElevated;

  // ─── Context-aware helpers ────────────────────────────────────────────────

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color surfaceElevatedOf(BuildContext context) =>
      isDark(context) ? darkSurfaceElevated : lightSurfaceElevated;

  static Color borderOf(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color textMutedOf(BuildContext context) =>
      isDark(context) ? darkTextMuted : lightTextMuted;

  static Color primaryOf(BuildContext context) =>
      isDark(context) ? darkPrimary : lightPrimary;

  static Color liveOf(BuildContext context) =>
      isDark(context) ? darkLive : lightLive;

  static Color warningOf(BuildContext context) =>
      isDark(context) ? darkWarning : lightWarning;

  static Color infoOf(BuildContext context) =>
      isDark(context) ? darkInfo : lightInfo;

  static Color dangerOf(BuildContext context) =>
      isDark(context) ? darkDanger : lightDanger;

  static Color upcomingOf(BuildContext context) =>
      isDark(context) ? darkPrimary : lightPrimary;

  static Color finishedOf(BuildContext context) =>
      isDark(context) ? darkTextMuted : lightTextMuted;

  static Color upcomingTextOf(BuildContext context) =>
      isDark(context) ? darkPrimary : lightPrimary;

  static Color finishedTextOf(BuildContext context) =>
      isDark(context) ? darkTextMuted : lightTextMuted;

  static Color vermilionOf(BuildContext context) =>
      isDark(context) ? darkLive : lightLive;

  static Color vermilionTextOf(BuildContext context) =>
      isDark(context) ? darkLive : lightLive;

  static LinearGradient signatureGradientOf(BuildContext context) =>
      isDark(context) ? signatureGradientDark : signatureGradientLight;

  /// Alias: `darkUpcoming` = `darkPrimary` (blue).
  static const Color darkUpcoming = darkPrimary;
  static const Color darkUpcomingText = Color(0xFF7B9BFF);
  static const Color lightUpcoming = lightPrimary;
  static const Color lightUpcomingText = lightPrimary;
  static const Color darkFinished = darkTextMuted;
  static const Color darkFinishedText = darkTextMuted;
  static const Color lightFinished = lightTextMuted;
  static const Color lightFinishedText = lightTextMuted;

  /// Alias kept for backward-compat: darkVermilion = live red-orange.
  static const Color darkVermilion = darkLive;
  static const Color darkVermilionText = darkLive;
  static const Color lightVermilion = lightLive;
  static const Color lightVermilionText = lightLive;

  static Color surfaceHighOf(BuildContext context) =>
      isDark(context) ? darkSurfaceHigh : lightSurfaceHigh;

  static Color dividerOf(BuildContext context) =>
      isDark(context) ? darkDivider : lightDivider;

  static Color secondaryOf(BuildContext context) =>
      isDark(context) ? darkPrimary : lightPrimary;

  /// isLight = inverse of isDark.
  static bool isLight(BuildContext context) => !isDark(context);

  static LinearGradient subtleCardWash(BuildContext context) {
    final s1 = surfaceOf(context);
    final s2 = surfaceElevatedOf(context);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [s1, s2],
    );
  }
}

/// Official [ThemeExtension] holding semantic colors for "Midnight Stadium".
///
/// Access via `Theme.of(context).extension<AppThemeColors>()` or
/// the convenience extension `context.colors`.
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceRaised,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.live,
    required this.warning,
    required this.info,
    required this.danger,
    // Legacy: live (red-orange) aliased as vermilion for backward-compat widgets.
    required this.vermilion,
    required this.vermilionText,
    // Status colors.
    required this.upcoming,
    required this.upcomingText,
    required this.finished,
    required this.finishedText,
    // Form result indicators.
    required this.winBg,
    required this.winText,
    required this.drawBg,
    required this.drawText,
    required this.lossBg,
    required this.lossText,
    // Shimmer.
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceRaised;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimary;
  final Color live;
  final Color warning;
  final Color info;
  final Color danger;
  final Color vermilion;
  final Color vermilionText;
  final Color upcoming;
  final Color upcomingText;
  final Color finished;
  final Color finishedText;
  final Color winBg;
  final Color winText;
  final Color drawBg;
  final Color drawText;
  final Color lossBg;
  final Color lossText;
  final Color shimmerBase;
  final Color shimmerHighlight;

  static const AppThemeColors dark = AppThemeColors(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceElevated: AppColors.darkSurfaceElevated,
    surfaceRaised: AppColors.darkSurfaceHigh,
    border: AppColors.darkBorder,
    divider: AppColors.darkDivider,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextMuted,
    primary: AppColors.darkPrimary,
    primaryContainer: AppColors.darkPrimaryContainer,
    onPrimary: AppColors.darkOnPrimary,
    live: AppColors.darkLive,
    warning: AppColors.darkWarning,
    info: AppColors.darkInfo,
    danger: AppColors.darkDanger,
    vermilion: AppColors.darkLive,
    vermilionText: AppColors.darkLive,
    upcoming: AppColors.darkPrimary,
    upcomingText: AppColors.darkUpcomingText,
    finished: AppColors.darkTextMuted,
    finishedText: AppColors.darkTextMuted,
    winBg: AppColors.darkWinBg,
    winText: AppColors.darkWinText,
    drawBg: AppColors.darkDrawBg,
    drawText: AppColors.darkDrawText,
    lossBg: AppColors.darkLossBg,
    lossText: AppColors.darkLossText,
    shimmerBase: AppColors.darkShimmerBase,
    shimmerHighlight: AppColors.darkShimmerHighlight,
  );

  static const AppThemeColors light = AppThemeColors(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceElevated: AppColors.lightSurfaceElevated,
    surfaceRaised: AppColors.lightSurfaceHigh,
    border: AppColors.lightBorder,
    divider: AppColors.lightDivider,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextMuted,
    primary: AppColors.lightPrimary,
    primaryContainer: AppColors.lightPrimaryContainer,
    onPrimary: AppColors.lightOnPrimary,
    live: AppColors.lightLive,
    warning: AppColors.lightWarning,
    info: AppColors.lightInfo,
    danger: AppColors.lightDanger,
    vermilion: AppColors.lightLive,
    vermilionText: AppColors.lightLive,
    upcoming: AppColors.lightPrimary,
    upcomingText: AppColors.lightPrimary,
    finished: AppColors.lightTextMuted,
    finishedText: AppColors.lightTextMuted,
    winBg: AppColors.lightWinBg,
    winText: AppColors.lightWinText,
    drawBg: AppColors.lightDrawBg,
    drawText: AppColors.lightDrawText,
    lossBg: AppColors.lightLossBg,
    lossText: AppColors.lightLossText,
    shimmerBase: AppColors.lightShimmerBase,
    shimmerHighlight: AppColors.lightShimmerHighlight,
  );

  // ─── Ramadan preset ───────────────────────────────────────────────────────
  static const AppThemeColors ramadanDark = AppThemeColors(
    background: Color(0xFF0C0A1E),
    surface: Color(0xFF131026),
    surfaceElevated: Color(0xFF1A163A),
    surfaceRaised: Color(0xFF221D4E),
    border: Color(0xFF2E2860),
    divider: Color(0xFF2E2860),
    textPrimary: Color(0xFFF8F4EC),
    textSecondary: Color(0xFFB8A87A),
    textMuted: Color(0xFF8A7A58),
    primary: Color(0xFFD4A017),
    primaryContainer: Color(0xFF4A3400),
    onPrimary: Color(0xFF0C0A1E),
    live: Color(0xFFFF4D3D),
    warning: Color(0xFFFFB020),
    info: Color(0xFFD4A017),
    danger: Color(0xFFFF6B6B),
    vermilion: Color(0xFFFF4D3D),
    vermilionText: Color(0xFFFF4D3D),
    upcoming: Color(0xFFD4A017),
    upcomingText: Color(0xFFD4A017),
    finished: Color(0xFF8A7A58),
    finishedText: Color(0xFF8A7A58),
    winBg: Color(0xFF4A3400),
    winText: Color(0xFFD4A017),
    drawBg: Color(0xFF1A163A),
    drawText: Color(0xFF8A7A58),
    lossBg: Color(0x33FF4D3D),
    lossText: Color(0xFFFF4D3D),
    shimmerBase: Color(0xFF1A163A),
    shimmerHighlight: Color(0xFF221D4E),
  );

  // ─── Champions League preset ──────────────────────────────────────────────
  static const AppThemeColors championsLeagueDark = AppThemeColors(
    background: Color(0xFF060D1E),
    surface: Color(0xFF0D1428),
    surfaceElevated: Color(0xFF131C36),
    surfaceRaised: Color(0xFF1A2544),
    border: Color(0xFF1E2D52),
    divider: Color(0xFF1E2D52),
    textPrimary: Color(0xFFF0F2FF),
    textSecondary: Color(0xFF8B9CF4),
    textMuted: Color(0xFF5A6BB8),
    primary: Color(0xFF8B9CF4),
    primaryContainer: Color(0xFF1A2544),
    onPrimary: Color(0xFF060D1E),
    live: Color(0xFFFF4D3D),
    warning: Color(0xFFFFB020),
    info: Color(0xFF8B9CF4),
    danger: Color(0xFFFF6B6B),
    vermilion: Color(0xFFFF4D3D),
    vermilionText: Color(0xFFFF4D3D),
    upcoming: Color(0xFF8B9CF4),
    upcomingText: Color(0xFF8B9CF4),
    finished: Color(0xFF5A6BB8),
    finishedText: Color(0xFF5A6BB8),
    winBg: Color(0xFF1A2544),
    winText: Color(0xFF8B9CF4),
    drawBg: Color(0xFF131C36),
    drawText: Color(0xFF5A6BB8),
    lossBg: Color(0x33FF4D3D),
    lossText: Color(0xFFFF4D3D),
    shimmerBase: Color(0xFF131C36),
    shimmerHighlight: Color(0xFF1A2544),
  );

  // ─── Golden preset ────────────────────────────────────────────────────────
  static const AppThemeColors goldenDark = AppThemeColors(
    background: Color(0xFF12100A),
    surface: Color(0xFF1A1710),
    surfaceElevated: Color(0xFF231F14),
    surfaceRaised: Color(0xFF2D281A),
    border: Color(0xFF3D3520),
    divider: Color(0xFF3D3520),
    textPrimary: Color(0xFFF8F4E8),
    textSecondary: Color(0xFFB8A060),
    textMuted: Color(0xFF8A7840),
    primary: Color(0xFFD97706),
    primaryContainer: Color(0xFF3D2800),
    onPrimary: Color(0xFF12100A),
    live: Color(0xFFFF4D3D),
    warning: Color(0xFFFFB020),
    info: Color(0xFFD97706),
    danger: Color(0xFFFF6B6B),
    vermilion: Color(0xFFFF4D3D),
    vermilionText: Color(0xFFFF4D3D),
    upcoming: Color(0xFFD97706),
    upcomingText: Color(0xFFD97706),
    finished: Color(0xFF8A7840),
    finishedText: Color(0xFF8A7840),
    winBg: Color(0xFF3D2800),
    winText: Color(0xFFD97706),
    drawBg: Color(0xFF231F14),
    drawText: Color(0xFF8A7840),
    lossBg: Color(0x33FF4D3D),
    lossText: Color(0xFFFF4D3D),
    shimmerBase: Color(0xFF231F14),
    shimmerHighlight: Color(0xFF2D281A),
  );

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceRaised,
    Color? border,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? primary,
    Color? primaryContainer,
    Color? onPrimary,
    Color? live,
    Color? warning,
    Color? info,
    Color? danger,
    Color? vermilion,
    Color? vermilionText,
    Color? upcoming,
    Color? upcomingText,
    Color? finished,
    Color? finishedText,
    Color? winBg,
    Color? winText,
    Color? drawBg,
    Color? drawText,
    Color? lossBg,
    Color? lossText,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      live: live ?? this.live,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      danger: danger ?? this.danger,
      vermilion: vermilion ?? this.vermilion,
      vermilionText: vermilionText ?? this.vermilionText,
      upcoming: upcoming ?? this.upcoming,
      upcomingText: upcomingText ?? this.upcomingText,
      finished: finished ?? this.finished,
      finishedText: finishedText ?? this.finishedText,
      winBg: winBg ?? this.winBg,
      winText: winText ?? this.winText,
      drawBg: drawBg ?? this.drawBg,
      drawText: drawText ?? this.drawText,
      lossBg: lossBg ?? this.lossBg,
      lossText: lossText ?? this.lossText,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      live: Color.lerp(live, other.live, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      vermilion: Color.lerp(vermilion, other.vermilion, t)!,
      vermilionText: Color.lerp(vermilionText, other.vermilionText, t)!,
      upcoming: Color.lerp(upcoming, other.upcoming, t)!,
      upcomingText: Color.lerp(upcomingText, other.upcomingText, t)!,
      finished: Color.lerp(finished, other.finished, t)!,
      finishedText: Color.lerp(finishedText, other.finishedText, t)!,
      winBg: Color.lerp(winBg, other.winBg, t)!,
      winText: Color.lerp(winText, other.winText, t)!,
      drawBg: Color.lerp(drawBg, other.drawBg, t)!,
      drawText: Color.lerp(drawText, other.drawText, t)!,
      lossBg: Color.lerp(lossBg, other.lossBg, t)!,
      lossText: Color.lerp(lossText, other.lossText, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}

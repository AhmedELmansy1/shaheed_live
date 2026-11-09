import 'package:flutter/material.dart';

/// Design tokens for the "Paper × Ink × Vermilion" design system.
///
/// Editorial, tactile, and restrained:
/// - Light: Warm paper backdrop (#F7F4EE), pure white surface (#FFFFFF), crisp ink text (#14161C).
/// - Dark: Deep obsidian ink (#0E1015), rich charcoal surface (#171A21), parchment text (#F2EFE8).
/// - Brand / Live: Striking Vermilion (#E5482D light, #FF5A3C dark).
/// - Upcoming: Deep Cobalt (#3B5BDB).
/// - Finished: Muted Slate (#6E7687 light, #8B93A4 dark).
class AppColors {
  // Light Palette ("Paper & Vermilion")
  static const Color lightBackground = Color(0xFFF7F4EE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFBF9F5);
  static const Color lightSurfaceHigh = lightSurfaceElevated;
  static const Color lightSurfaceLight = lightSurfaceElevated;
  static const Color lightBorder = Color(0xFFE6E1D8);
  static const Color lightCardBorder = lightBorder;
  static const Color lightDivider = Color(0xFFE6E1D8);
  static const Color lightTextPrimary = Color(0xFF14161C);
  static const Color lightTextSecondary = Color(0xFF5B6070);
  static const Color lightTextMuted = Color(0xFF888E9E);
  static const Color lightVermilion = Color(0xFFE5482D);
  static const Color lightVermilionText = Color(0xFFC23318);
  static const Color lightPrimary = lightVermilion;
  static const Color lightUpcoming = Color(0xFF3B5BDB);
  static const Color lightUpcomingText = Color(0xFF3B5BDB);
  static const Color lightSecondary = lightUpcoming;
  static const Color lightFinished = Color(0xFF525866);
  static const Color lightFinishedText = Color(0xFF525866);
  static const Color lightLive = lightVermilion;
  static const Color lightGlowBorder = lightBorder;

  // Dark Palette ("Ink & Vermilion")
  static const Color darkBackground = Color(0xFF0E1015);
  static const Color darkSurface = Color(0xFF171A21);
  static const Color darkSurfaceElevated = Color(0xFF1F232C);
  static const Color darkSurfaceHigh = darkSurfaceElevated;
  static const Color darkSurfaceLight = darkSurfaceElevated;
  static const Color darkBorder = Color(0xFF2A2F3A);
  static const Color darkCardBorder = darkBorder;
  static const Color darkDivider = Color(0xFF2A2F3A);
  static const Color darkTextPrimary = Color(0xFFF2EFE8);
  static const Color darkTextSecondary = Color(0xFFA3A8B5);
  static const Color darkTextMuted = Color(0xFF666C7A);
  static const Color darkVermilion = Color(0xFFFF5A3C);
  static const Color darkVermilionText = Color(0xFFFF5A3C);
  static const Color darkPrimary = darkVermilion;
  static const Color darkUpcoming = Color(0xFF4C6EF5);
  static const Color darkUpcomingText = Color(0xFF6C85F5);
  static const Color darkSecondary = darkUpcoming;
  static const Color darkFinished = Color(0xFF8B93A4);
  static const Color darkFinishedText = Color(0xFF8B93A4);
  static const Color darkLive = darkVermilion;
  static const Color darkGlowBorder = darkBorder;

  // Common Semantic Constants
  static const Color vermilion = lightVermilion;
  static const Color primary = darkVermilion;
  static const Color secondary = darkUpcoming;
  static const Color live = darkVermilion;
  static const Color livePulse = darkVermilion;
  static const Color liveIndicator = darkVermilion;
  static const Color gold = Color(0xFFD97706);
  static const Color goldGlow = Color(0x33D97706);
  static const Color pitchLine = Color(0xFF475569);
  static const Color pitchGreen = darkSurface;
  static const Color pitchGreenLight = darkSurfaceElevated;
  static const Color accentCyan = darkVermilion;
  static const Color accentBlue = darkUpcoming;
  static const Color divider = darkDivider;

  // Backward-compatibility default aliases (Dark theme defaults)
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color surfaceHigh = darkSurfaceElevated;
  static const Color surfaceElevated = darkSurfaceElevated;
  static const Color surfaceLight = darkSurfaceElevated;
  static const Color border = darkBorder;
  static const Color cardBorder = darkBorder;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;
  static const Color primaryGlow = Color(0x22E5482D);
  static const Color secondaryGlow = Color(0x223B5BDB);
  static const Color liveGlowColor = Color(0x22E5482D);

  // Subdued Brand Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE5482D), Color(0xFFFF5A3C)],
  );
  static const LinearGradient primaryGradient = brandGradient;
  static const LinearGradient neonCyanGradient = brandGradient;

  static bool isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Context-aware dynamic helpers
  static Color backgroundOf(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()?.background ??
        (isDark(context) ? darkBackground : lightBackground);
  }

  static Color surfaceOf(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()?.surface ??
        (isDark(context) ? darkSurface : lightSurface);
  }

  static Color surfaceElevatedOf(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()?.surfaceElevated ??
        (isDark(context) ? darkSurfaceElevated : lightSurfaceElevated);
  }

  static Color surfaceHighOf(BuildContext context) => surfaceElevatedOf(context);
  static Color surfaceLightOf(BuildContext context) => surfaceElevatedOf(context);

  static Color borderOf(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()?.border ??
        (isDark(context) ? darkBorder : lightBorder);
  }

  static Color cardBorderOf(BuildContext context) => borderOf(context);
  static Color dividerOf(BuildContext context) => borderOf(context);

  static Color textPrimaryOf(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()?.textPrimary ??
        (isDark(context) ? darkTextPrimary : lightTextPrimary);
  }

  static Color textSecondaryOf(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()?.textSecondary ??
        (isDark(context) ? darkTextSecondary : lightTextSecondary);
  }

  static Color textMutedOf(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()?.textMuted ??
        (isDark(context) ? darkTextMuted : lightTextMuted);
  }

  static Color primaryOf(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()?.vermilion ??
        (isDark(context) ? darkVermilion : lightVermilion);
  }

  static Color vermilionTextOf(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()?.vermilionText ??
        (isDark(context) ? darkVermilionText : lightVermilionText);
  }

  static Color secondaryOf(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()?.upcoming ??
        (isDark(context) ? darkUpcoming : lightUpcoming);
  }

  static Color upcomingTextOf(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()?.upcomingText ??
        (isDark(context) ? darkUpcomingText : lightUpcomingText);
  }

  static Color liveOf(BuildContext context) => primaryOf(context);

  static Color finishedOf(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()?.finished ??
        (isDark(context) ? darkFinished : lightFinished);
  }

  static Color finishedTextOf(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()?.finishedText ??
        (isDark(context) ? darkFinishedText : lightFinishedText);
  }

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

/// Official [ThemeExtension] holding semantic colors for "Paper × Ink × Vermilion".
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color vermilion;
  final Color vermilionText;
  final Color upcoming;
  final Color upcomingText;
  final Color finished;
  final Color finishedText;

  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.vermilion,
    required this.vermilionText,
    required this.upcoming,
    required this.upcomingText,
    required this.finished,
    required this.finishedText,
  });

  static const light = AppThemeColors(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceElevated: AppColors.lightSurfaceElevated,
    border: AppColors.lightBorder,
    divider: AppColors.lightDivider,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextMuted,
    vermilion: AppColors.lightVermilion,
    vermilionText: AppColors.lightVermilionText,
    upcoming: AppColors.lightUpcoming,
    upcomingText: AppColors.lightUpcomingText,
    finished: AppColors.lightFinished,
    finishedText: AppColors.lightFinishedText,
  );

  static const dark = AppThemeColors(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceElevated: AppColors.darkSurfaceElevated,
    border: AppColors.darkBorder,
    divider: AppColors.darkDivider,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextMuted,
    vermilion: AppColors.darkVermilion,
    vermilionText: AppColors.darkVermilionText,
    upcoming: AppColors.darkUpcoming,
    upcomingText: AppColors.darkUpcomingText,
    finished: AppColors.darkFinished,
    finishedText: AppColors.darkFinishedText,
  );

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? vermilion,
    Color? vermilionText,
    Color? upcoming,
    Color? upcomingText,
    Color? finished,
    Color? finishedText,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      vermilion: vermilion ?? this.vermilion,
      vermilionText: vermilionText ?? this.vermilionText,
      upcoming: upcoming ?? this.upcoming,
      upcomingText: upcomingText ?? this.upcomingText,
      finished: finished ?? this.finished,
      finishedText: finishedText ?? this.finishedText,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      vermilion: Color.lerp(vermilion, other.vermilion, t)!,
      vermilionText: Color.lerp(vermilionText, other.vermilionText, t)!,
      upcoming: Color.lerp(upcoming, other.upcoming, t)!,
      upcomingText: Color.lerp(upcomingText, other.upcomingText, t)!,
      finished: Color.lerp(finished, other.finished, t)!,
      finishedText: Color.lerp(finishedText, other.finishedText, t)!,
    );
  }
}

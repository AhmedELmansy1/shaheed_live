import 'package:flutter/material.dart';

/// Centralized "Royal Stadium" Color Design Tokens for Shoot Live.
/// Regal, energetic, prestigious, trustworthy.
/// - Primary: Royal Gold (#D4AF37 -> #F4D03F) for identity, CTAs, selected tabs, followed leagues.
/// - Secondary: Deep Royal Blue (#1E3A8A -> #2563EB) for secondary accents & info states.
/// - Live: Electric Vermilion Red (#EF4444) reserved exclusively for live-match states.
class AppColors {
  // Dark Palette ("Royal Stadium" - Default)
  static const Color darkBackground = Color(0xFF0A0E1A); // Deep navy undertone
  static const Color darkSurface = Color(0xFF12182A);
  static const Color darkSurfaceHigh = Color(0xFF1A2238);
  static const Color darkSurfaceLight = Color(0xFF222D4A);
  static const Color darkBorder = Color(0x1FFFFFFF);
  static const Color darkCardBorder = Color(0x1FFFFFFF);

  // Dark Typography (Warm Off-White)
  static const Color darkTextPrimary = Color(0xFFF5F0E8);
  static const Color darkTextSecondary = Color(0xFFA8A294);
  static const Color darkTextMuted = Color(0xFF6B6658);
  static const Color darkDivider = Color(0x1AFFFFFF);

  // Light Palette (Warm Cream Identity, WCAG AA Compliant)
  static const Color lightBackground = Color(0xFFFAF7F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFF4EEE4);
  static const Color lightSurfaceLight = Color(0xFFEAE2D5);
  static const Color lightBorder = Color(0xFFDDD4C7);
  static const Color lightCardBorder = Color(0xFFDDD4C7);

  // Light Typography
  static const Color lightTextPrimary = Color(0xFF1A1612);
  static const Color lightTextSecondary = Color(0xFF615B52);
  static const Color lightTextMuted = Color(0xFF8C8476);
  static const Color lightDivider = Color(0xFFE8DFD3);

  // PRIMARY: Royal Gold (Brand, CTAs, Selected States, Followed Badges)
  static const Color primary = Color(0xFFD4AF37); // Royal Gold
  static const Color primaryDeep = Color(0xFFB8860B); // Deep Goldenrod
  static const Color primaryLight = Color(0xFFF4D03F); // Radiant Light Gold
  static const Color primaryGlow = Color(0x40D4AF37); // rgba(212,175,55, 0.25)
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldGlow = Color(0x40D4AF37);

  // SECONDARY: Royal Blue (Secondary Accents, Information, Away Team)
  static const Color secondary = Color(0xFF2563EB); // Royal Blue
  static const Color secondaryDeep = Color(0xFF1E3A8A); // Deep Navy Blue
  static const Color secondaryLight = Color(0xFF3B82F6);
  static const Color secondaryGlow = Color(0x332563EB);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentCyan = Color(0xFF2563EB); // Backwards-compatible alias for secondary blue

  // LIVE: Pure Vermilion Red (Reserved strictly for live match state)
  static const Color live = Color(0xFFEF4444); // Live Red
  static const Color livePulse = Color(0xFFDC2626);
  static const Color liveIndicator = Color(0xFFEF4444);
  static const Color liveGlowColor = Color(0x40EF4444);

  // Tactical Pitch Navy (Replaces green grass on tactical pitch canvas)
  static const Color pitchNavy = Color(0xFF0C1929);
  static const Color pitchNavyLight = Color(0xFF132338);
  static const Color pitchGreen = Color(0xFF0C1929); // alias for backwards compatibility
  static const Color pitchGreenLight = Color(0xFF132338);

  // 135deg Brand Gradient: Royal Gold -> Radiant Gold
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment(-0.7, -0.7),
    end: Alignment(0.7, 0.7),
    colors: [Color(0xFFD4AF37), Color(0xFFF4D03F)],
  );

  // Hero Card Gradient: Gold glow -> Royal Blue shimmer -> Deep Navy
  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x33D4AF37), Color(0x1F2563EB), Color(0xFF12182A)],
    stops: [0.0, 0.5, 1.0],
  );

  // Backward-compatibility defaults (Dark Mode by default)
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color surfaceHigh = darkSurfaceHigh;
  static const Color surfaceLight = darkSurfaceLight;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;
  static const Color divider = darkDivider;
  static const Color cardBorder = darkCardBorder;

  // Context-aware dynamic theme getters
  static bool isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  static Color backgroundOf(BuildContext context) =>
      isLight(context) ? lightBackground : darkBackground;

  static Color surfaceOf(BuildContext context) =>
      isLight(context) ? lightSurface : darkSurface;

  static Color surfaceHighOf(BuildContext context) =>
      isLight(context) ? lightSurfaceHigh : darkSurfaceHigh;

  static Color surfaceLightOf(BuildContext context) =>
      isLight(context) ? lightSurfaceLight : darkSurfaceLight;

  static Color borderOf(BuildContext context) =>
      isLight(context) ? lightBorder : darkBorder;

  static Color cardBorderOf(BuildContext context) => borderOf(context);

  static Color dividerOf(BuildContext context) =>
      isLight(context) ? lightDivider : darkDivider;

  static Color textPrimaryOf(BuildContext context) =>
      isLight(context) ? lightTextPrimary : darkTextPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      isLight(context) ? lightTextSecondary : darkTextSecondary;

  static Color textMutedOf(BuildContext context) =>
      isLight(context) ? lightTextMuted : darkTextMuted;

  static Color primaryOf(BuildContext context) => primary;

  static Color secondaryOf(BuildContext context) =>
      isLight(context) ? secondaryDeep : secondary;
}

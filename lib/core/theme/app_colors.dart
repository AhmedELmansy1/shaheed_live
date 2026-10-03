import 'package:flutter/material.dart';

/// Centralized "Midnight Pitch" Color Tokens for Shoot Live.
/// Confident, energetic, premium, trustworthy. Stadium-at-night mood.
class AppColors {
  // Dark Palette ("Midnight Pitch" - Default)
  static const Color darkBackground = Color(0xFF070B10);
  static const Color darkSurface = Color(0xFF0E151D);
  static const Color darkSurfaceHigh = Color(0xFF15202B);
  static const Color darkSurfaceLight = Color(0xFF1B2735);
  static const Color darkBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color darkCardBorder = Color(0x14FFFFFF);

  // Dark Typography
  static const Color darkTextPrimary = Color(0xFFF2F6FA);
  static const Color darkTextSecondary = Color(0xFF9AA8B6);
  static const Color darkTextMuted = Color(0xFF5E6B78);
  static const Color darkDivider = Color(0x1FFFFFFF);

  // Light Palette (Adjusted for WCAG AA Contrast)
  static const Color lightBackground = Color(0xFFF4F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFE9EEF4);
  static const Color lightSurfaceLight = Color(0xFFDFE6F0);
  static const Color lightBorder = Color(0xFFD6E0EB);
  static const Color lightCardBorder = Color(0xFFD6E0EB);

  // Light Typography
  static const Color lightTextPrimary = Color(0xFF0B141C);
  static const Color lightTextSecondary = Color(0xFF4B5B6B);
  static const Color lightTextMuted = Color(0xFF7A8B9B);
  static const Color lightDivider = Color(0xFFE2E9F0);

  // Brand Accents & State Colors
  static const Color primary = Color(0xFF00E676);          // Electric Pitch Green
  static const Color primaryDeep = Color(0xFF00B85C);
  static const Color primaryGlow = Color(0x4000E676);      // rgba(0,230,118,0.25)
  static const Color liveIndicator = Color(0xFF00E676);

  static const Color accentCyan = Color(0xFF00B0FF);       // Cyan gradient endpoint
  static const Color gold = Color(0xFFFFC94D);             // Featured / Premium Gold
  static const Color goldGlow = Color(0x40FFC94D);

  static const Color live = Color(0xFFFF4D5E);             // Coral Red (ONLY for live state)
  static const Color livePulse = Color(0xFFFF4D5E);
  static const Color liveGlowColor = Color(0x40FF4D5E);

  static const Color pitchGreen = Color(0xFF0E2A1F);       // Tactical pitch green
  static const Color pitchGreenLight = Color(0xFF163E2E);

  // 135deg Brand Gradient: #00E676 -> #00B0FF (used sparingly: hero card, primary CTA, splash)
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment(-0.7, -0.7), // ~135 degrees
    end: Alignment(0.7, 0.7),
    colors: [
      Color(0xFF00E676),
      Color(0xFF00B0FF),
    ],
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x3300E676),
      Color(0x1A00B0FF),
      Color(0xFF0E151D),
    ],
    stops: [0.0, 0.45, 1.0],
  );

  // Backward-compatibility defaults (dark mode by default)
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color surfaceHigh = darkSurfaceHigh;
  static const Color surfaceLight = darkSurfaceLight;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;
  static const Color divider = darkDivider;
  static const Color cardBorder = darkCardBorder;
}

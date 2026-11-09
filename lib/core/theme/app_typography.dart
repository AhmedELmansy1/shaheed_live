import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design Token Typography scale for the "Paper × Ink × Vermilion" design system.
///
/// Features:
/// - Arabic-first with bundled 'Cairo' font family (zero runtime downloads).
/// - Tabular figures for score numerals and timestamps (no jitter during live updates).
/// - High legibility on both Paper (light) and Ink (dark) backgrounds.
class AppTypography {
  static const String fontFamily = 'Cairo';

  // Display Styles
  static TextStyle displayLarge({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.2,
      letterSpacing: -0.5,
    );
  }

  static TextStyle displayMedium({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.25,
      letterSpacing: -0.3,
    );
  }

  // Titles
  static TextStyle titleLarge({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.25,
      letterSpacing: 0.0,
    );
  }

  static TextStyle titleMedium({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.3,
      letterSpacing: 0.0,
    );
  }

  static TextStyle titleSmall({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.3,
      letterSpacing: 0.0,
    );
  }

  // Body
  static TextStyle bodyLarge({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.4,
      letterSpacing: 0.0,
    );
  }

  static TextStyle bodyMedium({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.35,
      letterSpacing: 0.0,
    );
  }

  static TextStyle bodySmall({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.35,
      letterSpacing: 0.0,
    );
  }

  // Labels & Badges
  static TextStyle labelLarge({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.2,
      letterSpacing: 0.1,
    );
  }

  static TextStyle labelSmall({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.2,
      letterSpacing: 0.2,
    );
  }

  // Score Numerals — Tabular figures prevent layout shifting during live score increments
  static TextStyle scoreHeadline({Color? color}) => scoreLarge(color: color);

  static TextStyle scoreLarge({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.1,
      letterSpacing: 0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle scoreMedium({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.15,
      letterSpacing: 0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle scoreSmall({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.2,
      letterSpacing: 0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // Backward compatibility alias for previous displayScore
  static TextStyle displayScore({
    Color color = AppColors.darkTextPrimary,
    double size = 30,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.2,
      letterSpacing: 0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // Backward compatibility aliases for existing screens
  static TextStyle caption({Color? color}) => bodySmall(color: color);
  static TextStyle label({Color? color}) => labelLarge(color: color);
  static TextStyle labelMedium({Color? color}) => labelLarge(color: color);

  // Material TextTheme generator
  static TextTheme textTheme(Color textPrimary, Color textSecondary) {
    return TextTheme(
      displayLarge: displayLarge(color: textPrimary),
      displayMedium: displayMedium(color: textPrimary),
      titleLarge: titleLarge(color: textPrimary),
      titleMedium: titleMedium(color: textPrimary),
      titleSmall: titleSmall(color: textPrimary),
      bodyLarge: bodyLarge(color: textPrimary),
      bodyMedium: bodyMedium(color: textSecondary),
      bodySmall: bodySmall(color: textSecondary),
      labelLarge: labelLarge(color: textPrimary),
      labelSmall: labelSmall(color: textSecondary),
    );
  }
}

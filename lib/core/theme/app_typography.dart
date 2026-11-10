import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design Token Typography — "Midnight Stadium".
///
/// Font: Cairo (variable, bundled). Arabic-first, full RTL.
/// Scale aligned to spec; tabular figures on score numerals prevent
/// layout jitter during live score updates.
class AppTypography {
  static const String fontFamily = 'Cairo';

  // ─── Display ──────────────────────────────────────────────────────────────

  /// 34sp / lh 1.17 / w800 — Hero titles.
  static TextStyle display({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.17,
      letterSpacing: -0.5,
    );
  }

  /// Alias kept for backward-compat.
  static TextStyle displayLarge({Color? color}) => display(color: color);

  // ─── Headline ─────────────────────────────────────────────────────────────

  /// 24sp / lh 1.33 / w700 — Section headers.
  static TextStyle headline({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.33,
      letterSpacing: -0.3,
    );
  }

  static TextStyle displayMedium({Color? color}) => headline(color: color);

  // ─── Title ────────────────────────────────────────────────────────────────

  /// 18sp / lh 1.44 / w700 — Card titles, screen titles.
  static TextStyle title({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.44,
      letterSpacing: 0.0,
    );
  }

  static TextStyle titleLarge({Color? color}) => title(color: color);

  static TextStyle titleMedium({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.38,
      letterSpacing: 0.0,
    );
  }

  static TextStyle titleSmall({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.36,
      letterSpacing: 0.0,
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  /// 15sp / lh 1.60 / w500 — Match rows, main text.
  static TextStyle body({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.60,
      letterSpacing: 0.0,
    );
  }

  static TextStyle bodyLarge({Color? color}) => body(color: color);

  static TextStyle bodyMedium({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.50,
      letterSpacing: 0.0,
    );
  }

  static TextStyle bodySmall({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.33,
      letterSpacing: 0.0,
    );
  }

  // ─── Label ────────────────────────────────────────────────────────────────

  /// 13sp / lh 1.38 / w600 — Badges, chips, button text.
  static TextStyle label({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.38,
      letterSpacing: 0.1,
    );
  }

  static TextStyle labelLarge({Color? color}) => label(color: color);

  static TextStyle labelMedium({Color? color}) => label(color: color);

  static TextStyle labelSmall({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.27,
      letterSpacing: 0.2,
    );
  }

  // ─── Caption ──────────────────────────────────────────────────────────────

  /// 12sp / lh 1.33 / w500 — Timestamps, meta info.
  static TextStyle caption({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.33,
      letterSpacing: 0.0,
    );
  }

  // ─── Score Numerals ───────────────────────────────────────────────────────

  /// 28sp / lh 1.14 / w800 / tabular figures — Live scores, never jitters.
  static TextStyle score({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.14,
      letterSpacing: 0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle scoreLarge({Color? color}) => score(color: color);
  static TextStyle scoreHeadline({Color? color}) => score(color: color);

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
      height: 1.25,
      letterSpacing: 0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Backward-compat alias.
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

  // ─── Material TextTheme ───────────────────────────────────────────────────

  static TextTheme textTheme(Color textPrimary, Color textSecondary) {
    return TextTheme(
      displayLarge: display(color: textPrimary),
      displayMedium: headline(color: textPrimary),
      displaySmall: title(color: textPrimary),
      headlineLarge: headline(color: textPrimary),
      headlineMedium: title(color: textPrimary),
      headlineSmall: titleMedium(color: textPrimary),
      titleLarge: title(color: textPrimary),
      titleMedium: titleMedium(color: textPrimary),
      titleSmall: titleSmall(color: textPrimary),
      bodyLarge: body(color: textPrimary),
      bodyMedium: bodyMedium(color: textSecondary),
      bodySmall: caption(color: textSecondary),
      labelLarge: label(color: textPrimary),
      labelMedium: label(color: textSecondary),
      labelSmall: labelSmall(color: textSecondary),
    );
  }
}

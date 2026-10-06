import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Design Token Typography scale for Shoot Live.
/// Cairo with strict scale: display 32/800, title 20/700, body 15/500, caption 12/500.
/// Tabular figures for scores and minutes.
class AppTypography {
  // Display Styles (Scores, Large Hero numbers: 28-32sp/800)
  static TextStyle displayScore({
    Color color = AppColors.darkTextPrimary,
    double size = 30,
  }) {
    return GoogleFonts.cairo(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.2,
      letterSpacing: 0.0,
    );
  }

  // Titles (20/700)
  static TextStyle titleLarge({Color color = AppColors.darkTextPrimary}) {
    return GoogleFonts.cairo(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.25,
      letterSpacing: 0.0,
    );
  }

  static TextStyle titleMedium({Color color = AppColors.darkTextPrimary}) {
    return GoogleFonts.cairo(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.25,
      letterSpacing: 0.0,
    );
  }

  static TextStyle titleSmall({Color color = AppColors.darkTextPrimary}) {
    return GoogleFonts.cairo(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.25,
      letterSpacing: 0.0,
    );
  }

  // Body Styles (15/500)
  static TextStyle bodyLarge({Color color = AppColors.darkTextPrimary}) {
    return GoogleFonts.cairo(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.35,
      letterSpacing: 0.0,
    );
  }

  static TextStyle bodyMedium({Color color = AppColors.darkTextSecondary}) {
    return GoogleFonts.cairo(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.3,
      letterSpacing: 0.0,
    );
  }

  static TextStyle bodySmall({Color color = AppColors.darkTextSecondary}) {
    return GoogleFonts.cairo(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.3,
      letterSpacing: 0.0,
    );
  }

  // Captions & Badges (12/500)
  static TextStyle caption({Color color = AppColors.darkTextMuted}) {
    return GoogleFonts.cairo(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.2,
      letterSpacing: 0.0,
    );
  }

  static TextStyle badge({Color color = Colors.white, double size = 11}) {
    return GoogleFonts.cairo(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.2,
      letterSpacing: 0.0,
    );
  }
}

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

/// Central theme configuration for "Paper × Ink × Vermilion".
class AppTheme {
  static ThemeData get lightTheme => getLightTheme();
  static ThemeData get darkTheme => getDarkTheme();

  static ThemeData getLightTheme({AppThemeColors? overrideColors}) {
    final colors = overrideColors ?? AppThemeColors.light;
    final textTheme = AppTypography.textTheme(
      colors.textPrimary,
      colors.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.vermilion,
      extensions: [colors],
      colorScheme: ColorScheme.light(
        primary: colors.vermilion,
        secondary: colors.upcoming,
        surface: colors.surface,
        error: colors.vermilion,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: colors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge(color: colors.textPrimary),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mdRadius,
          side: BorderSide(color: colors.border, width: 1.0),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1.0,
        space: 1.0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.vermilion,
        unselectedItemColor: colors.textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      iconTheme: IconThemeData(color: colors.textPrimary),
    );
  }

  static ThemeData getDarkTheme({AppThemeColors? overrideColors}) {
    final colors = overrideColors ?? AppThemeColors.dark;
    final textTheme = AppTypography.textTheme(
      colors.textPrimary,
      colors.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.vermilion,
      extensions: [colors],
      colorScheme: ColorScheme.dark(
        primary: colors.vermilion,
        secondary: colors.upcoming,
        surface: colors.surface,
        error: colors.vermilion,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: colors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge(color: colors.textPrimary),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mdRadius,
          side: BorderSide(color: colors.border, width: 1.0),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1.0,
        space: 1.0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.vermilion,
        unselectedItemColor: colors.textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      iconTheme: IconThemeData(color: colors.textPrimary),
    );
  }
}

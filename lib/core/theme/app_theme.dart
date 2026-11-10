import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_motion.dart';
import 'app_radii.dart';
import 'app_typography.dart';

/// Central theme configuration for "Midnight Stadium".
///
/// Dark-first. Primary = electric blue #3D7BFF (dark) / #1F5FE0 (light).
/// Live = red-orange #FF4D3D. No green anywhere.
/// System UI: edge-to-edge, adaptive status bar brightness.
class AppTheme {
  static ThemeData get lightTheme => getLightTheme();
  static ThemeData get darkTheme => getDarkTheme();

  // ─── Light Theme ──────────────────────────────────────────────────────────

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
      primaryColor: colors.primary,
      extensions: [colors],
      colorScheme: ColorScheme.light(
        primary: colors.primary,
        primaryContainer: colors.primaryContainer,
        secondary: colors.info,
        surface: colors.surface,
        error: colors.danger,
        onPrimary: colors.onPrimary,
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
        titleTextStyle: AppTypography.title(color: colors.textPrimary),
        iconTheme: IconThemeData(color: colors.textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
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
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        selectedLabelStyle: AppTypography.caption(color: colors.primary),
        unselectedLabelStyle: AppTypography.caption(color: colors.textSecondary),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      iconTheme: IconThemeData(color: colors.textPrimary),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceElevated,
        selectedColor: colors.primaryContainer,
        labelStyle: AppTypography.label(color: colors.textPrimary),
        side: BorderSide(color: colors.border, width: 1),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.fullRadius),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: AppRadii.mdRadius,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdRadius,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdRadius,
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeUpPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ─── Dark Theme ───────────────────────────────────────────────────────────

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
      primaryColor: colors.primary,
      extensions: [colors],
      colorScheme: ColorScheme.dark(
        primary: colors.primary,
        primaryContainer: colors.primaryContainer,
        secondary: colors.info,
        surface: colors.surface,
        error: colors.danger,
        onPrimary: colors.onPrimary,
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
        titleTextStyle: AppTypography.title(color: colors.textPrimary),
        iconTheme: IconThemeData(color: colors.textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
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
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        selectedLabelStyle: AppTypography.caption(color: colors.primary),
        unselectedLabelStyle: AppTypography.caption(color: colors.textSecondary),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      iconTheme: IconThemeData(color: colors.textPrimary),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceElevated,
        selectedColor: colors.primaryContainer,
        labelStyle: AppTypography.label(color: colors.textPrimary),
        side: BorderSide(color: colors.border, width: 1),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.fullRadius),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: AppRadii.mdRadius,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdRadius,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdRadius,
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeUpPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ─── Seasonal Preset Factories ────────────────────────────────────────────

  static ThemeData darkRamadan() =>
      getDarkTheme(overrideColors: AppThemeColors.ramadanDark);

  static ThemeData darkChampionsLeague() =>
      getDarkTheme(overrideColors: AppThemeColors.championsLeagueDark);

  static ThemeData darkGolden() =>
      getDarkTheme(overrideColors: AppThemeColors.goldenDark);
}

// ─── Custom Page Transition: fade + subtle slide up ──────────────────────────
// No new packages — in-house implementation using standard Flutter primitives.

class _FadeUpPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeUpPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasizedCurve,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}

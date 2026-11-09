import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Predefined seasonal theme presets supported by the dashboard and app.
enum SeasonalPreset {
  defaultDark,
  ramadan,
  championsLeague,
  classico,
  golden;

  static SeasonalPreset fromString(String? key) {
    switch (key?.trim().toLowerCase()) {
      case 'ramadan':
        return SeasonalPreset.ramadan;
      case 'champions_league':
      case 'championsleague':
        return SeasonalPreset.championsLeague;
      case 'classico':
      case 'el_clasico':
        return SeasonalPreset.classico;
      case 'golden':
        return SeasonalPreset.golden;
      case 'default_dark':
      default:
        return SeasonalPreset.defaultDark;
    }
  }

  String get key {
    switch (this) {
      case SeasonalPreset.ramadan:
        return 'ramadan';
      case SeasonalPreset.championsLeague:
        return 'champions_league';
      case SeasonalPreset.classico:
        return 'classico';
      case SeasonalPreset.golden:
        return 'golden';
      case SeasonalPreset.defaultDark:
        return 'default_dark';
    }
  }
}

/// Helper for WCAG 2.1 relative luminance and contrast ratio computation.
class WcagHelper {
  /// Computes relative luminance for a given [Color] per W3C specification.
  static double computeLuminance(Color color) {
    double transform(double channel) {
      if (channel <= 0.03928) {
        return channel / 12.92;
      } else {
        return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
      }
    }

    final r = transform(color.r);
    final g = transform(color.g);
    final b = transform(color.b);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Computes the contrast ratio between two colors (range: 1.0 to 21.0).
  static double computeContrastRatio(Color c1, Color c2) {
    final l1 = computeLuminance(c1);
    final l2 = computeLuminance(c2);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Determines whether two colors satisfy WCAG AA contrast for body text (>= 4.5:1).
  static bool meetsWcagAA(Color text, Color surface) {
    return computeContrastRatio(text, surface) >= 4.5;
  }

  /// Returns a high-contrast text color (either white or ink primary) for the given surface.
  static Color getReadableTextColor(Color surface) {
    final onWhite = computeContrastRatio(Colors.white, surface);
    final onInk = computeContrastRatio(AppColors.lightTextPrimary, surface);
    return onWhite >= onInk ? Colors.white : AppColors.lightTextPrimary;
  }
}

/// Model holding remote seasonal theme and kickoff offset configuration.
class ThemeConfigModel {
  final SeasonalPreset preset;
  final Color primaryColor;
  final Color accentColor;
  final String bannerUrl;
  final bool enabled;
  final int kickoffOffsetHours;

  const ThemeConfigModel({
    this.preset = SeasonalPreset.defaultDark,
    this.primaryColor = AppColors.darkVermilion,
    this.accentColor = AppColors.darkUpcoming,
    this.bannerUrl = '',
    this.enabled = true,
    this.kickoffOffsetHours = 0,
  });

  /// Safely parses a hex string into a [Color], returning null if invalid.
  static Color? parseHexColor(dynamic hexStr) {
    if (hexStr == null) return null;
    var str = hexStr.toString().trim();
    if (str.isEmpty || str == 'null') return null;

    if (str.startsWith('#')) {
      str = str.substring(1);
    } else if (str.startsWith('0x')) {
      str = str.substring(2);
    }

    if (str.length == 6) {
      str = 'FF$str'; // Add full opacity
    }

    if (str.length != 8) return null;

    final val = int.tryParse(str, radix: 16);
    if (val == null) return null;
    return Color(val);
  }

  /// Factory parser extracting from Firestore `config/app_settings`.
  /// Handles both nested `theme_config` map and root fallbacks, clamping offset to [-3, +3].
  factory ThemeConfigModel.fromMap(Map<String, dynamic>? rawMap) {
    if (rawMap == null || rawMap.isEmpty) {
      return const ThemeConfigModel();
    }

    final dynamic rawTheme = rawMap['theme_config'];
    final Map<String, dynamic> themeMap = (rawTheme is Map)
        ? Map<String, dynamic>.from(rawTheme)
        : rawMap;

    final enabled = (themeMap['enabled'] as bool?) ?? true;
    final preset = SeasonalPreset.fromString(themeMap['active_preset'] as String?);

    // Parse kickoff offset with fallback from nested to root
    dynamic rawOffset = themeMap['kickoff_offset_hours'] ?? rawMap['kickoff_offset_hours'];
    int offset = 0;
    if (rawOffset is num) {
      offset = rawOffset.toInt();
    } else if (rawOffset != null) {
      offset = int.tryParse(rawOffset.toString()) ?? 0;
    }
    // Hard clamp to [-3, +3]
    offset = offset.clamp(-3, 3);

    // Parse colors with fallback to preset safe defaults
    final parsedPrimary = parseHexColor(themeMap['primary_color']);
    final parsedAccent = parseHexColor(themeMap['accent_color']);

    Color safePrimary;
    Color safeAccent;

    switch (preset) {
      case SeasonalPreset.ramadan:
        safePrimary = parsedPrimary ?? const Color(0xFF8B5CF6);
        safeAccent = parsedAccent ?? const Color(0xFFF59E0B);
        break;
      case SeasonalPreset.championsLeague:
        safePrimary = parsedPrimary ?? const Color(0xFF1E40AF);
        safeAccent = parsedAccent ?? const Color(0xFFFBBF24);
        break;
      case SeasonalPreset.classico:
        safePrimary = parsedPrimary ?? const Color(0xFFDC2626);
        safeAccent = parsedAccent ?? const Color(0xFF2563EB);
        break;
      case SeasonalPreset.golden:
        safePrimary = parsedPrimary ?? const Color(0xFFD97706);
        safeAccent = parsedAccent ?? const Color(0xFFFEF08A);
        break;
      case SeasonalPreset.defaultDark:
        safePrimary = parsedPrimary ?? AppColors.darkVermilion;
        safeAccent = parsedAccent ?? AppColors.darkUpcoming;
        break;
    }

    // WCAG contrast validation: Ensure text on these colors remains readable
    // If parsed custom color has insufficient contrast against standard surfaces, revert to preset safe default
    final primaryContrastLight = WcagHelper.computeContrastRatio(safePrimary, AppColors.lightBackground);
    final primaryContrastDark = WcagHelper.computeContrastRatio(safePrimary, AppColors.darkBackground);
    if (primaryContrastLight < 3.0 && primaryContrastDark < 3.0) {
      safePrimary = AppColors.darkVermilion;
    }

    return ThemeConfigModel(
      preset: preset,
      primaryColor: safePrimary,
      accentColor: safeAccent,
      bannerUrl: (themeMap['banner_url'] as String?)?.trim() ?? '',
      enabled: enabled,
      kickoffOffsetHours: offset,
    );
  }

  /// Produces [AppThemeColors] overrides matching this seasonal theme.
  AppThemeColors toThemeColors({required bool isDark}) {
    if (!enabled) {
      return isDark ? AppThemeColors.dark : AppThemeColors.light;
    }

    final base = isDark ? AppThemeColors.dark : AppThemeColors.light;
    final primary = primaryColor;
    final accent = accentColor;

    return base.copyWith(
      vermilion: primary,
      vermilionText: isDark
          ? primary
          : (WcagHelper.meetsWcagAA(primary, base.background)
              ? primary
              : AppColors.lightVermilionText),
      upcoming: accent,
      upcomingText: isDark ? accent : AppColors.lightUpcomingText,
    );
  }
}

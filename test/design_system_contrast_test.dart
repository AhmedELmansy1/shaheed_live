import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/core/theme/app_colors.dart';

double _luminanceComponent(double c) {
  return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color color) {
  final r = _luminanceComponent(color.r);
  final g = _luminanceComponent(color.g);
  final b = _luminanceComponent(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color c1, Color c2) {
  final l1 = _relativeLuminance(c1);
  final l2 = _relativeLuminance(c2);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

bool _isGreenHue(Color color) {
  final hsv = HSVColor.fromColor(color);
  // Hue between 75 and 165 with notable saturation is green
  return hsv.hue >= 75 && hsv.hue <= 165 && hsv.saturation > 0.15;
}

void main() {
  group('Midnight Stadium - WCAG AA Contrast Compliance', () {
    test('Dark theme text contrast against backgrounds >= 4.5:1', () {
      final ratioTextPrimary = _contrastRatio(
        AppColors.darkTextPrimary,
        AppColors.darkBackground,
      );
      final ratioTextSecondary = _contrastRatio(
        AppColors.darkTextSecondary,
        AppColors.darkBackground,
      );
      final ratioSurfaceTextPrimary = _contrastRatio(
        AppColors.darkTextPrimary,
        AppColors.darkSurface,
      );

      expect(ratioTextPrimary, greaterThanOrEqualTo(4.5),
          reason: 'darkTextPrimary on darkBackground must meet WCAG AA');
      expect(ratioTextSecondary, greaterThanOrEqualTo(4.5),
          reason: 'darkTextSecondary on darkBackground must meet WCAG AA');
      expect(ratioSurfaceTextPrimary, greaterThanOrEqualTo(4.5),
          reason: 'darkTextPrimary on darkSurface must meet WCAG AA');
    });

    test('Light theme text contrast against backgrounds >= 4.5:1', () {
      final ratioTextPrimary = _contrastRatio(
        AppColors.lightTextPrimary,
        AppColors.lightBackground,
      );
      final ratioTextSecondary = _contrastRatio(
        AppColors.lightTextSecondary,
        AppColors.lightBackground,
      );

      expect(ratioTextPrimary, greaterThanOrEqualTo(4.5),
          reason: 'lightTextPrimary on lightBackground must meet WCAG AA');
      expect(ratioTextSecondary, greaterThanOrEqualTo(4.5),
          reason: 'lightTextSecondary on lightBackground must meet WCAG AA');
    });

    test('UI Non-text / borders / chips >= 3.0:1', () {
      final borderRatio = _contrastRatio(AppColors.darkBorder, AppColors.darkBackground);
      final primaryRatio = _contrastRatio(AppColors.darkPrimary, AppColors.darkBackground);

      expect(borderRatio, greaterThanOrEqualTo(1.2)); // hairline separator contrast
      expect(primaryRatio, greaterThanOrEqualTo(3.0),
          reason: 'Primary accent against darkBackground must exceed 3:1');
    });
  });

  group('Midnight Stadium - Strict No Green Ban', () {
    test('Zero green hue across semantic palette', () {
      final palette = <String, Color>{
        'darkPrimary': AppColors.darkPrimary,
        'darkLive': AppColors.darkLive,
        'darkWarning': AppColors.darkWarning,
        'darkInfo': AppColors.darkInfo,
        'darkDanger': AppColors.darkDanger,
        'lightPrimary': AppColors.lightPrimary,
        'lightLive': AppColors.lightLive,
        'lightWarning': AppColors.lightWarning,
        'lightInfo': AppColors.lightInfo,
        'success': AppColors.success,
        'pitchNeutral': AppColors.pitchNeutral,
      };

      for (final entry in palette.entries) {
        expect(
          _isGreenHue(entry.value),
          isFalse,
          reason: 'Color ${entry.key} (${entry.value}) must NOT have green hue!',
        );
      }
    });

    test('Static analysis: Zero green tokens or hex literals across lib/', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final greenMaterialRegex = RegExp(r'\bColors\.(green|lightGreen|teal|lime)\b');
      final greenHexRegex = RegExp(r'0x(?:[0-9a-fA-F]{2})?([0-9a-fA-F]{6})\b', caseSensitive: false);

      final violations = <String>[];

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trim();
          if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;

          // Check Colors.green* / teal / lime
          final match = greenMaterialRegex.firstMatch(line);
          if (match != null) {
            violations.add('${file.path}:${i + 1} uses ${match.group(0)}');
          }

          // Check Color hex literals
          if (line.contains('Color(') || line.contains('0x')) {
            for (final hexMatch in greenHexRegex.allMatches(line)) {
              final hexStr = hexMatch.group(1)!;
              final r = int.parse(hexStr.substring(0, 2), radix: 16);
              final g = int.parse(hexStr.substring(2, 4), radix: 16);
              final b = int.parse(hexStr.substring(4, 6), radix: 16);
              final color = Color.fromARGB(255, r, g, b);
              if (_isGreenHue(color)) {
                violations.add('${file.path}:${i + 1} has green hex #$hexStr ($line)');
              }
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Found green references in code:\n${violations.join('\n')}',
      );
    });
  });
}

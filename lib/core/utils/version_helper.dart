import 'package:package_info_plus/package_info_plus.dart';

/// Semantic version comparison utility.
class VersionHelper {
  /// Compares two semantic version strings (e.g., "1.2.3" vs "1.10.0").
  ///
  /// Returns:
  /// - Negative integer if [v1] < [v2]
  /// - Zero (0) if [v1] == [v2]
  /// - Positive integer if [v1] > [v2]
  ///
  /// Handles:
  /// - Build metadata (e.g. "1.0.0+1" -> "1.0.0")
  /// - Leading "v" prefixes (e.g. "v1.2.3" -> "1.2.3")
  /// - Variable segment lengths (e.g. "1.2" vs "1.2.0" -> equal)
  /// - Numerical comparison rather than lexicographical ("1.10.0" > "1.2.0")
  static int compare(String v1, String v2) {
    final segments1 = _parseSegments(v1);
    final segments2 = _parseSegments(v2);

    final maxLength = segments1.length > segments2.length
        ? segments1.length
        : segments2.length;

    for (int i = 0; i < maxLength; i++) {
      final num1 = i < segments1.length ? segments1[i] : 0;
      final num2 = i < segments2.length ? segments2[i] : 0;

      if (num1 < num2) return -1;
      if (num1 > num2) return 1;
    }

    return 0;
  }

  /// Returns `true` if [current] is strictly less than [target].
  static bool isLessThan(String current, String target) {
    return compare(current, target) < 0;
  }

  /// Returns `true` if [current] is greater than or equal to [target].
  static bool isAtLeast(String current, String target) {
    return compare(current, target) >= 0;
  }

  /// Returns `true` if [current] is strictly greater than [target].
  static bool isGreaterThan(String current, String target) {
    return compare(current, target) > 0;
  }

  /// Returns `true` if [v1] is semantically equal to [v2].
  static bool isEqual(String v1, String v2) {
    return compare(v1, v2) == 0;
  }

  /// Extracts clean integer segments from a version string.
  static List<int> _parseSegments(String version) {
    var clean = version.trim();
    if (clean.startsWith('v') || clean.startsWith('V')) {
      clean = clean.substring(1);
    }
    // Strip build numbers/metadata after '+' or '-'
    final plusIdx = clean.indexOf('+');
    if (plusIdx != -1) {
      clean = clean.substring(0, plusIdx);
    }
    final dashIdx = clean.indexOf('-');
    if (dashIdx != -1) {
      clean = clean.substring(0, dashIdx);
    }

    if (clean.isEmpty) return [0];

    return clean
        .split('.')
        .map((seg) => int.tryParse(seg.trim()) ?? 0)
        .toList();
  }

  /// Asynchronously fetches the current app version from [PackageInfo].
  static Future<String> getCurrentAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '1.0.0';
    }
  }
}

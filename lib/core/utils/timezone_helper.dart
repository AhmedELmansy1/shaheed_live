import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Utility for initializing time zone databases and converting match times to device local time.
class TimezoneHelper {
  static String _currentZoneIdentifier = 'Africa/Cairo';

  /// Returns the current active IANA identifier (e.g. "Africa/Cairo", "Asia/Riyadh").
  static String get currentZoneIdentifier => _currentZoneIdentifier;

  /// Returns user-friendly Arabic description of the device timezone.
  static String get deviceTimezoneDescription {
    final offset = DateTime.now().timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final offsetStr = 'UTC$sign$hours:$minutes';

    final loc = _currentZoneIdentifier;
    String regionName = 'توقيت جهازك';
    if (loc.contains('Cairo')) {
      regionName = 'توقيت القاهرة (مصر)';
    } else if (loc.contains('Riyadh')) {
      regionName = 'توقيت مكة المكرمة (السعودية)';
    } else if (loc.contains('Dubai')) {
      regionName = 'توقيت الإمارات';
    } else if (loc.contains('London') || loc.contains('UTC') || loc.contains('GMT')) {
      regionName = 'توقيت غرينتش (GMT)';
    } else if (loc.contains('Algiers') || loc.contains('Tunis')) {
      regionName = 'توقيت شمال أفريقيا';
    }

    return '$regionName ($offsetStr)';
  }

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String currentTimeZone = timezoneInfo.identifier;
      _currentZoneIdentifier = currentTimeZone;
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
      debugPrint(
        '[TimezoneHelper] Device timezone detected: "$currentTimeZone" -> tz.local set to: "${tz.local.name}"',
      );
    } catch (e) {
      // Robust fallback: resolve timezone according to the device system offset
      final offsetHours = DateTime.now().timeZoneOffset.inHours;
      final fallbackTz = _resolveTimezoneForOffset(offsetHours);
      _currentZoneIdentifier = fallbackTz;
      try {
        tz.setLocalLocation(tz.getLocation(fallbackTz));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
      }
      debugPrint(
        '[TimezoneHelper] Device timezone detection notice ($e) -> fallback tz.local set to: "${tz.local.name}" (offset ${offsetHours}h)',
      );
    }
  }

  static String _resolveTimezoneForOffset(int offsetHours) {
    switch (offsetHours) {
      case 2:
        return 'Africa/Cairo';
      case 3:
        return 'Asia/Riyadh';
      case 4:
        return 'Asia/Dubai';
      case 1:
        return 'Africa/Algiers';
      case 0:
        return 'UTC';
      default:
        return 'Africa/Cairo';
    }
  }

  static DateTime toLocalTime(DateTime dateTime) {
    final location = tz.local;
    return tz.TZDateTime.from(dateTime, location);
  }
}

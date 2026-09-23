import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Utility for initializing time zone databases and converting UTC match times to local time.
class TimezoneHelper {
  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String currentTimeZone = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (_) {
      // Fallback to UTC if timezone detection fails on desktop/emulator
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  static DateTime toLocalTime(DateTime dateTime) {
    final location = tz.local;
    return tz.TZDateTime.from(dateTime, location);
  }
}

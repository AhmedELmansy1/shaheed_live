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
      // ignore: avoid_print
      print(
        '[TimezoneHelper] Device timezone detected: "$currentTimeZone" -> tz.local set to: "${tz.local.name}"',
      );
    } catch (e) {
      // Fallback to UTC if timezone detection fails on desktop/emulator
      tz.setLocalLocation(tz.getLocation('UTC'));
      // ignore: avoid_print
      print(
        '[TimezoneHelper] Device timezone detection failed ($e) -> fallback tz.local set to: "${tz.local.name}"',
      );
    }
  }

  static DateTime toLocalTime(DateTime dateTime) {
    final location = tz.local;
    return tz.TZDateTime.from(dateTime, location);
  }
}

import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// Date and time formatting utility using IANA timezone database for Africa/Cairo.
///
/// API TIMEZONE NOTE (Empirically Verified):
/// Raw `match_date` (YYYY-MM-DD) and `match_time` (HH:mm:ss) values returned by the Worker matches API
/// (https://matches-api.edwardmitrovic.workers.dev/) are served in Cairo Local Time (Africa/Cairo).
///
/// IANA Timezone Resolution:
/// Conversion to device local time is performed via `tz.getLocation('Africa/Cairo')` and `tz.TZDateTime`,
/// avoiding any hardcoded fixed UTC offsets (+03:00). DST rule shifts for Africa/Cairo are resolved
/// automatically by the `timezone` package database initialized at app startup in `TimezoneHelper.init()`.
///
/// Day Bucketing Decision:
/// All home screen tabs (Yesterday, Today, Tomorrow, Custom Date) compute target date strings (YYYY-MM-DD)
/// locally in the device's current timezone using [toApiDateString], and fetch match data via
/// `MatchesRepository.getMatchesByDate`. This guarantees that users in any time zone see matches bucketed
/// according to their own local calendar day.
class DateFormatter {
  /// Converts any string containing English digits (0-9) to Eastern Arabic digits (٠-٩).
  static String toArabicNumerals(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = input;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }

  /// Parses raw match date (YYYY-MM-DD) and match time (HH:mm:ss) in `Africa/Cairo` timezone using IANA data,
  /// converts to the device's local timezone, and formats as Arabic time string (e.g., "٧:٣٠ م").
  static String formatMatchTime(String? rawDate, String? rawTime) {
    if (rawDate == null ||
        rawDate.isEmpty ||
        rawTime == null ||
        rawTime.isEmpty) {
      return '----';
    }

    try {
      final dateParts = rawDate.trim().split('-');
      final timeParts = rawTime.trim().split(':');

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

      // Construct Cairo TZDateTime using IANA location data (NO hardcoded offset)
      final cairoLocation = tz.getLocation('Africa/Cairo');
      final cairoTZDateTime = tz.TZDateTime(
        cairoLocation,
        year,
        month,
        day,
        hour,
        minute,
        second,
      );

      // Convert to local device timezone
      final localDateTime = cairoTZDateTime.toLocal();

      final formatted = DateFormat('h:mm a', 'ar').format(localDateTime);
      return toArabicNumerals(formatted);
    } catch (_) {
      return toArabicNumerals(rawTime.substring(0, 5));
    }
  }

  /// Parses raw match date (YYYY-MM-DD) and match time (HH:mm:ss) in `Africa/Cairo` timezone using IANA data,
  /// and returns the resolved local device [DateTime].
  static DateTime? parseCairoMatchDateTime(String? rawDate, String? rawTime) {
    if (rawDate == null ||
        rawDate.isEmpty ||
        rawTime == null ||
        rawTime.isEmpty) {
      return null;
    }

    try {
      final dateParts = rawDate.trim().split('-');
      final timeParts = rawTime.trim().split(':');

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

      final cairoLocation = tz.getLocation('Africa/Cairo');
      final cairoTZDateTime = tz.TZDateTime(
        cairoLocation,
        year,
        month,
        day,
        hour,
        minute,
        second,
      );

      return cairoTZDateTime.toLocal();
    } catch (_) {
      try {
        return DateTime.parse('${rawDate.trim()} ${rawTime.trim()}');
      } catch (_) {
        return null;
      }
    }
  }

  /// Formats a [DateTime] into API date string format (`YYYY-MM-DD`).
  static String toApiDateString(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd', 'en').format(dateTime);
  }

  /// Formats a [DateTime] for screen header display (e.g. "الثلاثاء، ٢٢ سبتمبر ٢٠٢٦").
  static String formatDisplayDate(DateTime dateTime) {
    final formatted = DateFormat('EEEE، d MMMM yyyy', 'ar').format(dateTime);
    return toArabicNumerals(formatted);
  }

  /// Formats a [DateTime] for compact date tab display (e.g. "٢٢ سبتمبر").
  static String formatShortDate(DateTime dateTime) {
    final formatted = DateFormat('d MMMM', 'ar').format(dateTime);
    return toArabicNumerals(formatted);
  }
}

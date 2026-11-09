import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../data/api/match_score_api.dart';

/// Date and time formatting utility using IANA timezone database.
///
/// API TIMEZONE NOTE:
/// Raw `match_date` (YYYY-MM-DD) and `match_time` (HH:mm:ss) values returned by the Worker matches API
/// (https://matches-api.edwardmitrovic.workers.dev/) are served in the timezone defined by
/// [ApiConfig.sourceTimezone] (currently 'Asia/Riyadh', fixed UTC+3, no DST).
///
/// Use [ApiConfig.sourceTimezone] everywhere as the single source-timezone constant.
/// Converting the source instant to device-local is correct for every country; real kickoff
/// times can be verified against the debug log.
///
/// IANA Timezone Resolution:
/// Conversion to device local time is performed via [ApiConfig.sourceTimezone] and `tz.TZDateTime`,
/// avoiding any hardcoded fixed UTC offsets (+03:00). DST rule shifts are resolved
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

  /// Parses raw match date (YYYY-MM-DD) and match time (HH:mm:ss) in source timezone ([ApiConfig.sourceTimezone])
  /// using IANA data, converts to the device's local timezone, and formats as Arabic time string (e.g., "٧:٣٠ م").
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

      // Construct TZDateTime using the single source timezone constant (NO hardcoded offset)
      final sourceLocation = tz.getLocation(ApiConfig.sourceTimezone);
      final cairoTZDateTime = tz.TZDateTime(
        sourceLocation,
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

  /// Parses raw match date (YYYY-MM-DD) and match time (HH:mm:ss) in [ApiConfig.sourceTimezone]
  /// using IANA data, and returns the resolved local device [DateTime].
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

      final sourceLocation = tz.getLocation(ApiConfig.sourceTimezone);
      final sourceTZDateTime = tz.TZDateTime(
        sourceLocation,
        year,
        month,
        day,
        hour,
        minute,
        second,
      );

      return sourceTZDateTime.toLocal();
    } catch (_) {
      try {
        return DateTime.parse('${rawDate.trim()} ${rawTime.trim()}');
      } catch (_) {
        return null;
      }
    }
  }

  /// Debug-only helper: logs kickoff in source timezone vs device local.
  /// Call for the first 3 matches to verify timezone conversion is correct.
  static void debugLogKickoff(String matchId, String? rawDate, String? rawTime) {
    assert(() {
      if (rawDate == null || rawTime == null) return true;
      try {
        final sourceLocation = tz.getLocation(ApiConfig.sourceTimezone);
        final dateParts = rawDate.trim().split('-');
        final timeParts = rawTime.trim().split(':');
        final sourceDt = tz.TZDateTime(
          sourceLocation,
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          timeParts.length > 1 ? int.parse(timeParts[1]) : 0,
        );
        final localDt = sourceDt.toLocal();
        // ignore: avoid_print
        print(
          '[TZ-DEBUG] Match #$matchId | '
          'Source (${ApiConfig.sourceTimezone}): $sourceDt | '
          'Device local: $localDt',
        );
      } catch (e) {
        // ignore: avoid_print
        print('[TZ-DEBUG] Match #$matchId | Error: $e');
      }
      return true;
    }());
  }

  /// Formats a [DateTime] into API date string format (`YYYY-MM-DD`).
  static String toApiDateString(DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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

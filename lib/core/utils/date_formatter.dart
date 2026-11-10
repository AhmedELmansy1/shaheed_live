import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../data/api/match_score_api.dart';
import 'app_number_format.dart';

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
  /// Global kickoff offset hours dynamically synced with dashboard theme/DST configuration.
  static int globalKickoffOffsetHours = 0;

  /// Formats string to ensure standard Latin/Western digits (0-9).
  /// Enforces crisp tabular numerals across all sports times, dates, and metrics.
  static String toArabicNumerals(String input) {
    return AppNumberFormat.toLatinNumerals(input);
  }

  /// Parses raw match date (YYYY-MM-DD) and match time (HH:mm:ss) in source timezone ([ApiConfig.sourceTimezone])
  /// using IANA data, converts to the device's local timezone, and formats as Arabic time string with Western numerals (e.g., "7:30 م").
  /// An optional [offsetHours] (clamped to [-3, +3]) adjusts for remote timezone/DST overrides without shifting date tabs.
  static String formatMatchTime(String? rawDate, String? rawTime, {int offsetHours = 0}) {
    if (rawDate == null ||
        rawDate.isEmpty ||
        rawTime == null ||
        rawTime.isEmpty) {
      return '----';
    }

    final effectiveOffset = offsetHours != 0 ? offsetHours : globalKickoffOffsetHours;

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
      var localDateTime = cairoTZDateTime.toLocal();

      if (effectiveOffset != 0) {
        final clamped = effectiveOffset.clamp(-3, 3);
        localDateTime = localDateTime.add(Duration(hours: clamped));
      }

      final formatted = DateFormat('h:mm a', 'ar').format(localDateTime);
      return AppNumberFormat.toLatinNumerals(formatted);
    } catch (_) {
      try {
        var hour = int.tryParse(rawTime.substring(0, 2)) ?? 0;
        final minute = rawTime.substring(2, 5);
        if (effectiveOffset != 0) {
          hour = (hour + effectiveOffset.clamp(-3, 3)) % 24;
          if (hour < 0) hour += 24;
        }
        final hourStr = hour.toString().padLeft(2, '0');
        return AppNumberFormat.toLatinNumerals('$hourStr$minute');
      } catch (_) {
        return AppNumberFormat.toLatinNumerals(rawTime.substring(0, 5));
      }
    }
  }

  /// Parses raw match date (YYYY-MM-DD) and match time (HH:mm:ss) in [ApiConfig.sourceTimezone]
  /// using IANA data, and returns the resolved local device [DateTime].
  /// An optional [offsetHours] (clamped to [-3, +3]) applies remote timezone/DST adjustment.
  static DateTime? parseCairoMatchDateTime(String? rawDate, String? rawTime, {int offsetHours = 0}) {
    if (rawDate == null ||
        rawDate.isEmpty ||
        rawTime == null ||
        rawTime.isEmpty) {
      return null;
    }

    final effectiveOffset = offsetHours != 0 ? offsetHours : globalKickoffOffsetHours;

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

      var localDateTime = sourceTZDateTime.toLocal();
      if (effectiveOffset != 0) {
        final clamped = effectiveOffset.clamp(-3, 3);
        localDateTime = localDateTime.add(Duration(hours: clamped));
      }
      return localDateTime;
    } catch (_) {
      try {
        var dt = DateTime.parse('${rawDate.trim()} ${rawTime.trim()}');
        if (offsetHours != 0) {
          dt = dt.add(Duration(hours: offsetHours.clamp(-3, 3)));
        }
        return dt;
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

  /// Formats a [DateTime] for screen header display (e.g. "الثلاثاء، 22 سبتمبر 2026").
  static String formatDisplayDate(DateTime dateTime) {
    final formatted = DateFormat('EEEE، d MMMM yyyy', 'ar').format(dateTime);
    return AppNumberFormat.toLatinNumerals(formatted);
  }

  /// Formats a [DateTime] for compact date tab display (e.g. "22 سبتمبر").
  static String formatShortDate(DateTime dateTime) {
    final formatted = DateFormat('d MMMM', 'ar').format(dateTime);
    return AppNumberFormat.toLatinNumerals(formatted);
  }
}

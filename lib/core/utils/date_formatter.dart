import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../data/api/match_score_api.dart';
import 'app_number_format.dart';

/// Date and time formatting utility using IANA timezone database.
///
/// API TIMEZONE NOTE:
/// Raw `match_date` (YYYY-MM-DD) and `match_time` (HH:mm:ss) values returned by the Worker matches API
/// are served in the timezone defined by [ApiConfig.sourceTimezone] ('Africa/Cairo').
///
/// Use [KickoffTime] and [ApiConfig.sourceTimezone] everywhere as the single source-timezone constant.
/// Converting the source instant to device-local is correct for every country.
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

  /// Extracts (hour, minute, second) components defensively from any 12h or 24h string.
  /// Handles: "20:00:00", "08:00 م", "08:00 ص", "08:00 PM", "08:00 AM", "08:00", `<i class="mb-meridiem">م</i>`
  static (int hour, int minute, int second) parseTimeComponents(String rawTime) {
    final clean = rawTime.trim();
    final isPM = clean.contains('م') || clean.toLowerCase().contains('pm');
    final isAM = clean.contains('ص') || clean.toLowerCase().contains('am');

    final match = RegExp(r'(\d{1,2}):(\d{2})(?::(\d{2}))?').firstMatch(clean);
    if (match == null) {
      return (0, 0, 0);
    }

    var hour = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final second = int.tryParse(match.group(3) ?? '0') ?? 0;

    if (isPM) {
      if (hour < 12) hour += 12;
    } else if (isAM) {
      if (hour == 12) hour = 0;
    }

    return (hour, minute, second);
  }

  /// Parses raw match date (YYYY-MM-DD) and match time (HH:mm:ss or 12h with meridiem) in source timezone ([ApiConfig.sourceTimezone])
  /// using IANA data, converts to the device's local timezone, and formats as Arabic time string with Western numerals (e.g., "7:30 م").
  /// An optional [offsetHours] (clamped to [-3, +3]) adjusts for remote timezone/DST overrides without shifting date tabs.
  static String formatMatchTime(String? rawDate, String? rawTime, {int offsetHours = 0}) {
    return KickoffTime.format(rawDate, rawTime, offsetHours: offsetHours);
  }

  /// Parses raw match date (YYYY-MM-DD) and match time (HH:mm:ss) in [ApiConfig.sourceTimezone]
  /// using IANA data, and returns the resolved local device [DateTime].
  /// An optional [offsetHours] (clamped to [-3, +3]) applies remote timezone/DST adjustment.
  static DateTime? parseCairoMatchDateTime(String? rawDate, String? rawTime, {int offsetHours = 0}) {
    return KickoffTime.toLocal(rawDate, rawTime, offsetHours: offsetHours);
  }

  /// Formats remaining time until kickoff into concise Arabic text:
  /// - e.g. "متبقي 2 س و 15 د"
  /// - e.g. "متبقي 45 دقيقة"
  /// - e.g. "متبقي 4 س"
  /// - e.g. "متبقي 1 يوم و 3 س"
  /// Returns empty string if match has already started or datetime is null.
  static String formatRemainingKickoff(DateTime? kickoff, {DateTime? now}) {
    return KickoffTime.formatRemainingKickoff(kickoff, now: now);
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

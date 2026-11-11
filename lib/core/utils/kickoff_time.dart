import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'app_number_format.dart';
import 'date_formatter.dart';

/// Single authoritative service for all match kickoff time parsing, timezone conversion,
/// admin offset application, countdown formatting, and reminder calculations.
///
/// Upstream Architecture:
/// - Upstream feeds (YsScores / Worker API) serve match times in Egyptian local wall time (`Africa/Cairo`).
/// - Egypt observes Daylight Saving Time (UTC+3 in summer: last Friday of April through last Thursday of October;
///   UTC+2 in winter: November through April).
/// - The `timezone` package IANA database initialized at startup (`TimezoneHelper.init()`) automatically resolves
///   DST transitions without fragile hardcoded UTC offsets.
///
/// Conversion Pipeline:
/// 1. Parse raw date (YYYY-MM-DD) and raw time (12h/24h with Arabic/Latin meridiem) in `Africa/Cairo`.
/// 2. Convert to UTC instant (`toUtc()`).
/// 3. Convert to target/device local timezone (`toLocal()`).
/// 4. Apply admin `kickoff_offset_hours` (clamped [-3, +3]) consistently.
/// 5. Day bucketing decision: Date tabs and repository queries ALWAYS use the original calendar date
///    and are never corrupted or shifted across midnight by display offsets.
class KickoffTime {
  KickoffTime._();

  /// Authoritative upstream feed timezone constant ('Africa/Cairo').
  static const String upstreamFeedTimeZone = 'Africa/Cairo';

  /// Authoritative source timezone constant matching upstream provider.
  static const String sourceTimezone = upstreamFeedTimeZone;

  /// The sole trusted upstream source for absolute kickoff timestamp (proven YsScores match details).
  /// Any other source (e.g. 'cairo_riyadh_feed_utc3') or absent source cannot be trusted as absolute UTC.
  static const String trustedKickoffTzSource = 'ys_match_datetime_input';

  /// Evaluates whether [source] is proven and trusted to provide an absolute kickoff timestamp.
  static bool isTrustedKickoffSource(String? source) {
    if (source == null) return false;
    return source.trim().toLowerCase() == trustedKickoffTzSource;
  }

  static bool _timezonesInitialized = false;

  static void _ensureTimezonesInitialized() {
    if (_timezonesInitialized) return;
    try {
      tz.getLocation(sourceTimezone);
      _timezonesInitialized = true;
    } catch (_) {
      try {
        tz_data.initializeTimeZones();
        _timezonesInitialized = true;
      } catch (_) {}
    }
  }

  /// Global admin offset in hours dynamically synced with dashboard theme/DST config.
  static int get globalOffsetHours => DateFormatter.globalKickoffOffsetHours;
  static set globalOffsetHours(int val) {
    DateFormatter.globalKickoffOffsetHours = val;
  }

  /// Determines if a raw time string denotes an unconfirmed/TBD time (e.g. '00:00:00', '00:00', empty).
  static bool isTimeTbd(String? rawTime) {
    if (rawTime == null) return true;
    final clean = rawTime.trim();
    if (clean.isEmpty || clean == '----') return true;
    if (clean == '00:00:00' || clean == '00:00' || clean == '0:00') return true;
    return false;
  }

  /// Parses raw match date and time into a timezone-aware [tz.TZDateTime] located in `Africa/Cairo`.
  /// Returns `null` if unparsable or if the date/time is missing/TBD.
  static tz.TZDateTime? parseCairo(String? rawDate, String? rawTime) {
    if (rawDate == null || rawDate.trim().isEmpty) return null;
    if (isTimeTbd(rawTime)) return null;

    _ensureTimezonesInitialized();

    try {
      final dateParts = rawDate.trim().split('-');
      if (dateParts.length < 3) return null;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final (hour, minute, second) = DateFormatter.parseTimeComponents(rawTime!);

      final cairoLocation = tz.getLocation(sourceTimezone);
      return tz.TZDateTime(
        cairoLocation,
        year,
        month,
        day,
        hour,
        minute,
        second,
      );
    } catch (e) {
      debugPrint('[KickoffTime] Failed to parse Cairo kickoff: date=$rawDate, time=$rawTime: $e');
      return null;
    }
  }

  /// Parses raw match date and time in US Eastern Time (`America/New_York`).
  /// Used when upstream feed originates from Vercel US-East hosting.
  static tz.TZDateTime? parseUsEast(String? rawDate, String? rawTime) {
    if (rawDate == null || rawDate.trim().isEmpty) return null;
    if (isTimeTbd(rawTime)) return null;

    _ensureTimezonesInitialized();

    try {
      final dateParts = rawDate.trim().split('-');
      if (dateParts.length < 3) return null;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final (hour, minute, second) = DateFormatter.parseTimeComponents(rawTime!);

      final usEastLocation = tz.getLocation('America/New_York');
      return tz.TZDateTime(
        usEastLocation,
        year,
        month,
        day,
        hour,
        minute,
        second,
      );
    } catch (e) {
      debugPrint('[KickoffTime] Failed to parse US East kickoff: date=$rawDate, time=$rawTime: $e');
      return null;
    }
  }

  /// Converts the match kickoff time to a true UTC instant.
  /// If [kickoffAt] is provided, it is trusted ONLY when [kickoffTzSource] equals 'ys_match_datetime_input'.
  /// When [kickoffTzSource] equals 'feed_local_africa_cairo', the feed originates from Vercel US-East
  /// where YsScores returns times in US Eastern Time (America/New_York), so it is parsed accordingly.
  /// For any other source or missing source, [kickoffAt] is ignored and date+time is parsed in Africa/Cairo.
  static DateTime? toUtc(
    String? rawDate,
    String? rawTime, {
    String? kickoffAt,
    String? kickoffTzSource,
  }) {
    if (isTrustedKickoffSource(kickoffTzSource) &&
        kickoffAt != null &&
        kickoffAt.trim().isNotEmpty) {
      try {
        final parsed = DateTime.tryParse(kickoffAt.trim());
        if (parsed != null) {
          return parsed.toUtc();
        }
      } catch (_) {}
    }

    if (kickoffTzSource != null &&
        kickoffTzSource.trim().toLowerCase() == 'feed_local_africa_cairo') {
      final usEastDt = parseUsEast(rawDate, rawTime);
      if (usEastDt != null) {
        return usEastDt.toUtc();
      }
    }

    final cairoDt = parseCairo(rawDate, rawTime);
    if (cairoDt == null) return null;
    return cairoDt.toUtc();
  }

  /// Converts the match kickoff time to the device's local [DateTime],
  /// applying the optional [offsetHours] (or [globalOffsetHours] if 0).
  /// Respects [kickoffTzSource] trust rules.
  static DateTime? toLocal(
    String? rawDate,
    String? rawTime, {
    String? kickoffAt,
    String? kickoffTzSource,
    int offsetHours = 0,
  }) {
    final utc = toUtc(
      rawDate,
      rawTime,
      kickoffAt: kickoffAt,
      kickoffTzSource: kickoffTzSource,
    );
    if (utc == null) return null;

    var localDt = utc.toLocal();

    final effectiveOffset = offsetHours != 0 ? offsetHours : globalOffsetHours;
    if (effectiveOffset != 0) {
      localDt = localDt.add(Duration(hours: effectiveOffset.clamp(-3, 3)));
    }

    return localDt;
  }

  /// Converts the kickoff time to a [tz.TZDateTime] in the specified target timezone
  /// (defaults to [tz.local]), incorporating the admin offset.
  /// Respects [kickoffTzSource] trust rules.
  /// Used for accurate [FlutterLocalNotificationsPlugin] scheduling.
  static tz.TZDateTime? toTargetTZ(
    String? rawDate,
    String? rawTime, {
    String? kickoffAt,
    String? kickoffTzSource,
    tz.Location? targetLocation,
    int offsetHours = 0,
  }) {
    final utc = toUtc(
      rawDate,
      rawTime,
      kickoffAt: kickoffAt,
      kickoffTzSource: kickoffTzSource,
    );
    if (utc == null) return null;

    final loc = targetLocation ?? tz.local;
    var targetDt = tz.TZDateTime.from(utc, loc);

    final effectiveOffset = offsetHours != 0 ? offsetHours : globalOffsetHours;
    if (effectiveOffset != 0) {
      targetDt = targetDt.add(Duration(hours: effectiveOffset.clamp(-3, 3)));
    }

    return targetDt;
  }

  /// Formats the kickoff time into a localized Arabic string with standard Latin numerals (e.g. "4:00 م").
  /// Returns "غير محدد" if time is TBD or unparsable.
  static String format(
    String? rawDate,
    String? rawTime, {
    String? kickoffAt,
    String? kickoffTzSource,
    int offsetHours = 0,
  }) {
    final trustedKickoff =
        isTrustedKickoffSource(kickoffTzSource) ? kickoffAt : null;
    if ((rawDate == null || rawDate.isEmpty) &&
        (trustedKickoff == null || trustedKickoff.isEmpty)) {
      return '----';
    }
    if (isTimeTbd(rawTime) &&
        (trustedKickoff == null || trustedKickoff.isEmpty)) {
      return 'غير محدد';
    }

    final localDt = toLocal(
      rawDate,
      rawTime,
      kickoffAt: trustedKickoff,
      kickoffTzSource: kickoffTzSource,
      offsetHours: offsetHours,
    );
    if (localDt != null) {
      try {
        final formatted = DateFormat('h:mm a', 'ar').format(localDt);
        return AppNumberFormat.toLatinNumerals(formatted);
      } catch (_) {
        final hour = localDt.hour;
        final minute = localDt.minute;
        final period = hour >= 12 ? 'م' : 'ص';
        final displayHour = hour % 12 == 0 ? 12 : hour % 12;
        final minStr = minute.toString().padLeft(2, '0');
        return AppNumberFormat.toLatinNumerals('$displayHour:$minStr $period');
      }
    }

    // Defensive fallback formatting if timezone resolution fails
    try {
      final (hour, minute, _) = DateFormatter.parseTimeComponents(rawTime!);
      final effectiveOffset = (offsetHours != 0 ? offsetHours : globalOffsetHours).clamp(-3, 3);
      var adjustedHour = (hour + effectiveOffset) % 24;
      if (adjustedHour < 0) adjustedHour += 24;

      final period = adjustedHour >= 12 ? 'م' : 'ص';
      final displayHour = adjustedHour % 12 == 0 ? 12 : adjustedHour % 12;
      final minStr = minute.toString().padLeft(2, '0');
      return AppNumberFormat.toLatinNumerals('$displayHour:$minStr $period');
    } catch (_) {
      return AppNumberFormat.toLatinNumerals(rawTime?.trim().substring(0, 5) ?? '----');
    }
  }

  /// Computes the elapsed minutes since kickoff (positive = started, negative = not yet started).
  /// Returns `null` if the time is unannounced (TBD) or unparsable.
  /// Unannounced matches must NEVER be treated as elapsed or finished.
  static int? minutesSinceKickoff(
    String? rawDate,
    String? rawTime, {
    String? kickoffAt,
    String? kickoffTzSource,
    DateTime? now,
    int offsetHours = 0,
  }) {
    final trustedKickoff =
        isTrustedKickoffSource(kickoffTzSource) ? kickoffAt : null;
    if (isTimeTbd(rawTime) && (trustedKickoff == null || trustedKickoff.isEmpty)) return null;

    final kickoffLocal = toLocal(
      rawDate,
      rawTime,
      kickoffAt: trustedKickoff,
      kickoffTzSource: kickoffTzSource,
      offsetHours: offsetHours,
    );
    if (kickoffLocal == null) return null;

    final current = now ?? DateTime.now();
    return current.difference(kickoffLocal).inMinutes;
  }

  /// Formats human-friendly Arabic countdown string until kickoff (e.g. "متبقي 2 س و 15 د").
  /// Returns empty string if the match has already started, time is TBD, or unparsable.
  static String formatRemainingKickoff(DateTime? kickoffTime, {DateTime? now}) {
    if (kickoffTime == null) return '';

    final current = now ?? DateTime.now();
    final difference = kickoffTime.difference(current);

    if (difference.isNegative || difference == Duration.zero) {
      return '';
    }

    final totalHours = difference.inHours;
    final totalMinutes = difference.inMinutes;
    final remMinutes = totalMinutes % 60;

    if (totalHours >= 24) {
      final days = difference.inDays;
      final remHours = totalHours % 24;
      if (remHours == 0) {
        return AppNumberFormat.toLatinNumerals('بعد $days أيام');
      }
      return AppNumberFormat.toLatinNumerals('متبقي $days يوم و $remHours س');
    }

    if (totalHours > 0) {
      if (remMinutes == 0) {
        return AppNumberFormat.toLatinNumerals('متبقي $totalHours س');
      }
      return AppNumberFormat.toLatinNumerals('متبقي $totalHours س و $remMinutes د');
    }

    if (totalMinutes > 0) {
      return AppNumberFormat.toLatinNumerals('متبقي $totalMinutes دقيقة');
    }

    return 'تبدأ خلال لحظات';
  }

  /// Standardized YYYY-MM-DD representation for API queries.
  static String apiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

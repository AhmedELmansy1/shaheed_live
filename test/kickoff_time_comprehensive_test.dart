import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shoot_live/core/utils/timezone_helper.dart';
import 'package:shoot_live/data/api/match_score_api.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/tv_channel_model.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('ar', null);
    await TimezoneHelper.init();
  });

  group('1. Real Match Evidence (Africa/Cairo Upstream -> UTC Instant)', () {
    test('Match #1 (5795507): Crystal Palace vs Liverpool in Premier League', () {
      // Upstream HTML: 'الأحد 08-11-2026 · 04:00 م' (Winter: Cairo UTC+2)
      // Feed: date=2026-11-08, time=16:00:00 or 04:00 م
      const date = '2026-11-08';
      const time24 = '16:00:00';
      const time12Arabic = '04:00 م';

      final utcFrom24 = KickoffTime.toUtc(date, time24);
      final utcFrom12 = KickoffTime.toUtc(date, time12Arabic);

      expect(utcFrom24, isNotNull);
      expect(utcFrom12, isNotNull);
      expect(utcFrom24, equals(utcFrom12));

      // 16:00 Cairo in winter (UTC+2) is exactly 14:00 UTC
      expect(utcFrom24!.year, equals(2026));
      expect(utcFrom24.month, equals(11));
      expect(utcFrom24.day, equals(8));
      expect(utcFrom24.hour, equals(14));
      expect(utcFrom24.minute, equals(0));
    });

    test('Match #2 (6539338): Vietnam vs Chinese Taipei Friendly', () {
      // Upstream HTML: '02:00 م' (Winter: Cairo UTC+2)
      // 14:00 Cairo is exactly 12:00 UTC (19:00 ICT Vietnam local kickoff)
      const date = '2026-11-18';
      const time = '02:00 م';

      final utc = KickoffTime.toUtc(date, time);
      expect(utc, isNotNull);
      expect(utc!.hour, equals(12));
      expect(utc.minute, equals(0));
    });

    test('Match #3 (6386040): Anaitasuna vs Alaves in Copa del Rey', () {
      // Upstream HTML: '08:00 م' (Winter: Cairo UTC+2)
      // 20:00 Cairo is exactly 18:00 UTC (19:00 CET Spain local kickoff)
      const date = '2026-11-05';
      const time = '08:00 م';

      final utc = KickoffTime.toUtc(date, time);
      expect(utc, isNotNull);
      expect(utc!.hour, equals(18));
      expect(utc.minute, equals(0));
    });
  });

  group('2. Cross-Timezone Conversion (Cairo, Riyadh, London, New York)', () {
    test('Converts Cairo 16:00 winter kickoff accurately across target timezones', () {
      const date = '2026-11-08';
      const time = '16:00:00'; // 14:00 UTC

      final cairoLoc = tz.getLocation('Africa/Cairo');
      final riyadhLoc = tz.getLocation('Asia/Riyadh');
      final londonLoc = tz.getLocation('Europe/London');
      final newYorkLoc = tz.getLocation('America/New_York');

      final cairoTz = KickoffTime.toTargetTZ(date, time, targetLocation: cairoLoc);
      final riyadhTz = KickoffTime.toTargetTZ(date, time, targetLocation: riyadhLoc);
      final londonTz = KickoffTime.toTargetTZ(date, time, targetLocation: londonLoc);
      final nyTz = KickoffTime.toTargetTZ(date, time, targetLocation: newYorkLoc);

      // Cairo (UTC+2 in winter): 16:00
      expect(cairoTz!.hour, equals(16));

      // Riyadh (UTC+3 year-round): 17:00
      expect(riyadhTz!.hour, equals(17));

      // London (GMT / UTC+0 in November): 14:00
      expect(londonTz!.hour, equals(14));

      // New York (EST / UTC-5 in November): 09:00
      expect(nyTz!.hour, equals(9));
    });
  });

  group('3. Egypt DST Transitions (Summer UTC+3 vs Winter UTC+2)', () {
    test('Egypt on Summer DST (July): Cairo equals Riyadh (both UTC+3)', () {
      const summerDate = '2026-07-15';
      const time = '20:00:00';

      final utc = KickoffTime.toUtc(summerDate, time);
      expect(utc, isNotNull);
      // In July, Cairo is UTC+3 -> 20:00 Cairo is 17:00 UTC
      expect(utc!.hour, equals(17));

      final riyadhTz = KickoffTime.toTargetTZ(
        summerDate,
        time,
        targetLocation: tz.getLocation('Asia/Riyadh'),
      );
      // In summer, both Cairo and Riyadh are 20:00
      expect(riyadhTz!.hour, equals(20));
    });

    test('Egypt on Winter Standard Time (November): Cairo is UTC+2, Riyadh is UTC+3', () {
      const winterDate = '2026-11-15';
      const time = '20:00:00';

      final utc = KickoffTime.toUtc(winterDate, time);
      expect(utc, isNotNull);
      // In November, Cairo is UTC+2 -> 20:00 Cairo is 18:00 UTC
      expect(utc!.hour, equals(18));

      final riyadhTz = KickoffTime.toTargetTZ(
        winterDate,
        time,
        targetLocation: tz.getLocation('Asia/Riyadh'),
      );
      // In winter, Riyadh is 1 hour ahead of Cairo (21:00 vs 20:00)
      expect(riyadhTz!.hour, equals(21));
    });
  });

  group('4. Admin Kickoff Offset (+1, -1, 0, Clamping & Tab Integrity)', () {
    test('Offset adjusts formatted time cleanly without changing date tabs', () {
      const date = '2026-11-08';
      const time = '16:00:00';

      final formattedBase = KickoffTime.format(date, time, offsetHours: 0);
      final formattedPlus1 = KickoffTime.format(date, time, offsetHours: 1);
      final formattedMinus1 = KickoffTime.format(date, time, offsetHours: -1);

      expect(formattedBase, isNotEmpty);
      expect(formattedPlus1, isNotEmpty);
      expect(formattedMinus1, isNotEmpty);
      expect(formattedBase, isNot(equals(formattedPlus1)));

      // Original date string for API query remains unchanged
      final apiQueryDate = KickoffTime.apiDate(DateTime.parse('$date 00:00:00'));
      expect(apiQueryDate, equals('2026-11-08'));
    });

    test('Extreme offsets outside [-3, +3] are safely clamped', () {
      const date = '2026-11-08';
      const time = '16:00:00';

      final clampedPlus3 = KickoffTime.format(date, time, offsetHours: 3);
      final extremePlus10 = KickoffTime.format(date, time, offsetHours: 10);
      expect(extremePlus10, equals(clampedPlus3));

      final clampedMinus3 = KickoffTime.format(date, time, offsetHours: -3);
      final extremeMinus10 = KickoffTime.format(date, time, offsetHours: -10);
      expect(extremeMinus10, equals(clampedMinus3));
    });
  });

  group('5. Midnight Boundary Edge Cases', () {
    test('Kickoff at 23:45 with +1h offset rolls time into next day without breaking parser', () {
      const date = '2026-11-08';
      const lateTime = '23:45:00';

      final localTime = KickoffTime.toLocal(date, lateTime, offsetHours: 1);
      expect(localTime, isNotNull);

      // Formats as 00:45 ص (or 12:45 ص)
      final formatted = KickoffTime.format(date, lateTime, offsetHours: 1);
      expect(formatted.contains('45'), isTrue);
      expect(formatted.contains('ص'), isTrue);
    });
  });

  group('6. Unannounced / TBD Match Time & Status Resolution Bug Fix', () {
    test('Match with "00:00:00" or empty time is recognized as TBD', () {
      expect(KickoffTime.isTimeTbd('00:00:00'), isTrue);
      expect(KickoffTime.isTimeTbd('00:00'), isTrue);
      expect(KickoffTime.isTimeTbd(''), isTrue);
      expect(KickoffTime.isTimeTbd(null), isTrue);
      expect(KickoffTime.isTimeTbd('16:00:00'), isFalse);
      expect(KickoffTime.isTimeTbd('04:00 م'), isFalse);

      expect(KickoffTime.format('2026-11-08', '00:00:00'), equals('غير محدد'));
      expect(KickoffTime.minutesSinceKickoff('2026-11-08', '00:00:00'), isNull);
    });

    test('Unannounced (00:00:00) match is NEVER assumed finished by MatchStatusResolver', () {
      final unannouncedMatchMap = {
        'match_id': 991,
        'match_date': '2026-11-08',
        'match_time': '00:00:00',
        'status': 0,
        'event_status': 'not_started',
        'home_scores': 0,
        'away_scores': 0,
        'championship': {'id': 1, 'title': 'كأس ملك إسبانيا'},
        'home_team': {'row_id': 10, 'title': 'أنايتاسونا'},
        'away_team': {'row_id': 20, 'title': 'ألافيس'},
      };

      // Pretend current time is 10 hours past midnight
      final fakeNow = DateTime(2026, 11, 8, 15, 30);
      final statusInfo = MatchStatusResolver.resolve(unannouncedMatchMap, now: fakeNow);

      expect(statusInfo.state, equals(MatchState.notStarted));

      final matchModel = MatchModel.fromMap(unannouncedMatchMap);
      expect(matchModel.status, equals(MatchStatus.notStarted));
      expect(matchModel.isFinished, isFalse);
      expect(matchModel.homeScore, isNull); // Must be null, NOT 0 : 0
      expect(matchModel.awayScore, isNull);
      expect(matchModel.formattedLocalTime, equals('غير محدد'));
    });

    test('Explicitly unstarted match (status: 0, status_text: "لم تبدأ") is NEVER forced to finished', () {
      final unstartedMap = {
        'match_id': 992,
        'match_date': '2026-11-08',
        'match_time': '08:00:00',
        'status': '0',
        'event_status': 'not_started',
        'status_text': 'لم تبدأ',
        'home_scores': 0,
        'away_scores': 0,
      };

      // Current time is 10 hours past kickoff
      final fakeNow = DateTime(2026, 11, 8, 18, 00);
      final statusInfo = MatchStatusResolver.resolve(unstartedMap, now: fakeNow);

      expect(statusInfo.state, equals(MatchState.notStarted));
    });
  });

  group('7. Notification Reminders & TV Channel Model Fixes', () {
    test('KickoffTime.toTargetTZ handles Arabic meridiem without split errors', () {
      const date = '2026-11-08';
      const arabicTime = '04:00 م';

      final targetTz = KickoffTime.toTargetTZ(date, arabicTime);
      expect(targetTz, isNotNull);
    });

    test('TvChannelModel parses stream_url and url fallbacks', () {
      final channelMap1 = {
        'id': 'bein_1',
        'name': 'beIN Sports 1',
        'default_stream_url': 'https://example.com/stream1.m3u8',
      };
      final ch1 = TvChannelModel.fromMap(channelMap1, 'bein_1');
      expect(ch1.defaultStreamUrl, equals('https://example.com/stream1.m3u8'));

      final channelMap2 = {
        'id': 'bein_2',
        'name': 'beIN Sports 2',
        'stream_url': 'https://example.com/stream2.m3u8',
      };
      final ch2 = TvChannelModel.fromMap(channelMap2, 'bein_2');
      expect(ch2.defaultStreamUrl, equals('https://example.com/stream2.m3u8'));

      final channelMap3 = {
        'id': 'ssc_1',
        'name': 'SSC 1',
        'url': 'https://example.com/stream3.m3u8',
      };
      final ch3 = TvChannelModel.fromMap(channelMap3, 'ssc_1');
      expect(ch3.defaultStreamUrl, equals('https://example.com/stream3.m3u8'));
    });
  });

  group('8. Task 2 Kickoff Time & kickoff_known Matrix Verification', () {
    test('kickoff_known = true: correctly maps to matchModel.kickoffKnown and isKickoffTimeKnown', () {
      final match = MatchModel.fromMap({
        'id': 101,
        'match_date': '2026-11-15',
        'match_time': '16:00:00',
        'status': '0',
        'kickoff_known': true,
      });

      expect(match.kickoffKnown, isTrue);
      expect(match.isKickoffTimeKnown, isTrue);
      expect(match.formattedLocalTime, isNot('غير محدد'));
    });

    test('kickoff_known = false: unstarted match displays "غير محدد"', () {
      final match = MatchModel.fromMap({
        'id': 102,
        'match_date': '2026-11-15',
        'match_time': '16:00:00',
        'status': '0',
        'kickoff_known': false,
      });

      expect(match.kickoffKnown, isFalse);
      expect(match.isKickoffTimeKnown, isFalse);
      expect(match.formattedLocalTime, equals('غير محدد'));
    });

    test('kickoff_known missing: falls back to KickoffTime.isTimeTbd(matchTime)', () {
      final matchWithTime = MatchModel.fromMap({
        'id': 103,
        'match_date': '2026-11-15',
        'match_time': '16:00:00',
        'status': '0',
      });
      expect(matchWithTime.kickoffKnown, isNull);
      expect(matchWithTime.isKickoffTimeKnown, isTrue);

      final matchTbd = MatchModel.fromMap({
        'id': 104,
        'match_date': '2026-11-15',
        'match_time': '00:00:00',
        'status': '0',
      });
      expect(matchTbd.kickoffKnown, isNull);
      expect(matchTbd.isKickoffTimeKnown, isFalse);
    });

    test('finished match with 00:00:00: preserves score and displays date instead of "غير محدد"', () {
      final finishedMatch = MatchModel.fromMap({
        'id': 105,
        'match_date': '2026-11-08',
        'match_time': '00:00:00',
        'status': '4',
        'event_status': 'finished',
        'home_scores': 1,
        'away_scores': 3,
      });

      expect(finishedMatch.status, equals(MatchStatus.finished));
      expect(finishedMatch.homeScore, equals('1'));
      expect(finishedMatch.awayScore, equals('3'));
      expect(finishedMatch.formattedLocalTime, isNot('غير محدد'));
      expect(finishedMatch.formattedLocalTime, contains('نوفمبر'));
    });

    test('live match with unknown kickoff: preserves live state and score, does not crash on minute calculation', () {
      final liveMatch = MatchModel.fromMap({
        'id': 106,
        'match_date': '2026-11-11',
        'match_time': '00:00:00',
        'status': '1',
        'live': 1,
        'event_status': 'live',
        'home_scores': 0,
        'away_scores': 0,
        'admin_title': 'مباشر',
      });

      expect(liveMatch.isLive, isTrue);
      expect(liveMatch.status, equals(MatchStatus.live));
      expect(liveMatch.homeScore, equals('0'));
      expect(liveMatch.awayScore, equals('0'));
      expect(liveMatch.statusName, equals('مباشر'));
    });

    test('upcoming match with unknown kickoff: displays "غير محدد" and null scores', () {
      final upcoming = MatchModel.fromMap({
        'id': 107,
        'match_date': '2026-11-20',
        'match_time': '00:00:00',
        'status': '0',
        'event_status': 'not_started',
        'home_scores': 0,
        'away_scores': 0,
      });

      expect(upcoming.status, equals(MatchStatus.notStarted));
      expect(upcoming.homeScore, isNull);
      expect(upcoming.awayScore, isNull);
      expect(upcoming.formattedLocalTime, equals('غير محدد'));
    });

    test('postponed match: resolved cleanly as postponed with "تأجلت"', () {
      final postponed = MatchModel.fromMap({
        'id': 108,
        'match_date': '2026-11-15',
        'match_time': '18:00:00',
        'event_status': 'postponed',
        'admin_badge': 'postponed',
      });

      expect(postponed.status, equals(MatchStatus.postponed));
      expect(postponed.statusName, equals('تأجلت'));
    });

    test('Egypt DST Transitions: verified against IANA database', () {
      final cairo = tz.getLocation('Africa/Cairo');

      // 1. Summer DST active (e.g. June 15, 2026): UTC+3 (offset = 3 hours = 10800000 ms)
      final summerInstant = tz.TZDateTime(cairo, 2026, 6, 15, 12, 0);
      expect(summerInstant.timeZoneOffset, equals(const Duration(hours: 3)));

      // 2. Winter standard time active (e.g. December 15, 2026): UTC+2 (offset = 2 hours = 7200000 ms)
      final winterInstant = tz.TZDateTime(cairo, 2026, 12, 15, 12, 0);
      expect(winterInstant.timeZoneOffset, equals(const Duration(hours: 2)));

      // 3. Verification of exact transition boundaries for 2026:
      // In 2026, Egypt transitions to DST on Friday, April 24 at 00:00 -> 01:00.
      final beforeSummer = tz.TZDateTime(cairo, 2026, 4, 23, 12, 0);
      expect(beforeSummer.timeZoneOffset, equals(const Duration(hours: 2)));

      final afterSummer = tz.TZDateTime(cairo, 2026, 4, 25, 12, 0);
      expect(afterSummer.timeZoneOffset, equals(const Duration(hours: 3)));

      // In 2026, Egypt transitions back to standard time on Thursday, October 29 at 24:00 (Oct 30 00:00).
      final beforeWinter = tz.TZDateTime(cairo, 2026, 10, 28, 12, 0);
      expect(beforeWinter.timeZoneOffset, equals(const Duration(hours: 3)));

      final afterWinter = tz.TZDateTime(cairo, 2026, 10, 31, 12, 0);
      expect(afterWinter.timeZoneOffset, equals(const Duration(hours: 2)));
    });
  });
}

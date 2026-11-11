import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/services/notification_deduplicator.dart';
import 'package:shoot_live/data/api/match_score_api.dart';
import 'package:shoot_live/data/models/league_model.dart';
import 'package:shoot_live/data/models/match_info_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/match_stream_model.dart';
import 'package:shoot_live/data/models/poll_model.dart';
import 'package:shoot_live/data/models/sponsorship_model.dart';
import 'package:shoot_live/data/models/team_model.dart';
import 'package:shoot_live/data/models/ticker_config_model.dart';
import 'package:shoot_live/data/models/tv_channel_model.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar', null);
  });

  group('1. Schema Alignment Tests (Matching Canonical Dashboard Formats)', () {
    test('match_streams reads is_enabled, is_featured, stream_url, player_type with fallbacks', () {
      final canonicalDoc = {
        'is_enabled': true,
        'is_featured': true,
        'stream_url': 'https://stream.example.com/live.m3u8',
        'servers': [
          {
            'name': 'سيرفر رئيسي',
            'url': 'https://stream.example.com/hls.m3u8',
            'player_type': 'hls',
            'quality': '1080p',
          }
        ],
      };

      final model = MatchStreamModel.fromMap(canonicalDoc, 999);
      expect(model.isEnabled, isTrue);
      expect(model.isFeatured, isTrue);
      expect(model.streamUrl, 'https://stream.example.com/live.m3u8');
      expect(model.servers.length, 1);
      expect(model.servers.first.type, 'hls');

      // Legacy fallback doc
      final legacyDoc = {
        'is_stream_enabled': true,
        'type': 'embed',
        'servers': [
          {
            'name': 'سيرفر بديل',
            'stream_url': 'https://stream.example.com/embed',
            'type': 'embed',
          }
        ],
      };
      final legacyModel = MatchStreamModel.fromMap(legacyDoc, 999);
      expect(legacyModel.isEnabled, isTrue);
      expect(legacyModel.isFeatured, isFalse);
      expect(legacyModel.servers.first.type, 'embed');
      expect(legacyModel.servers.first.url, 'https://stream.example.com/embed');
    });

    test('sponsorships reads banner_url, click_url, enabled, and placement with fallbacks', () {
      final canonicalDoc = {
        'id': 'sp_123',
        'title': 'عرض خاص',
        'banner_url': 'https://ads.example.com/banner.png',
        'click_url': 'https://ads.example.com/click',
        'enabled': true,
        'start_date': '2026-11-01',
        'end_date': '2026-11-30',
        'placement': 'home_top_banner',
      };

      final campaign = SponsorshipCampaign.fromMap(canonicalDoc);
      expect(campaign.bannerUrl, 'https://ads.example.com/banner.png');
      expect(campaign.clickUrl, 'https://ads.example.com/click');
      expect(campaign.enabled, isTrue);
      expect(campaign.placement, SponsorshipPlacement.homeTopBanner);

      // Legacy fallback doc
      final legacyDoc = {
        'id': 'sp_legacy',
        'image_url': 'https://ads.example.com/legacy.png',
        'target_url': 'https://ads.example.com/target',
        'is_active': true,
        'placement': 'banner_home',
      };
      final legacyCampaign = SponsorshipCampaign.fromMap(legacyDoc);
      expect(legacyCampaign.bannerUrl, 'https://ads.example.com/legacy.png');
      expect(legacyCampaign.clickUrl, 'https://ads.example.com/target');
      expect(legacyCampaign.enabled, isTrue);
      expect(legacyCampaign.placement, SponsorshipPlacement.homeTopBanner);
    });

    test('ticker_config supports alert type and falls back unknown types to info', () {
      final alertConfig = TickerConfigModel.fromMap({
        'enabled': true,
        'text': 'تحذير هام لجميع المستخدمين',
        'type': 'alert',
      });
      expect(alertConfig.type, 'alert');
      expect(alertConfig.isValid, isTrue);

      final unknownConfig = TickerConfigModel.fromMap({
        'enabled': true,
        'text': 'نص تجريبي',
        'type': 'custom_unknown_type',
      });
      expect(unknownConfig.type, 'info');
    });

    test('tv_channels reads is_active, default_stream_url, and stream_url fallback', () {
      final canonicalDoc = {
        'name': 'beIN Sports 1',
        'logo_url': 'https://imgs.ysscores.com/championship/48/logo.png',
        'default_stream_url': 'https://stream.example.com/bein1.m3u8',
        'default_player_type': 'hls',
        'default_quality': 'fhd',
        'is_active': true,
        'order': 1,
      };

      final channel = TvChannelModel.fromMap(canonicalDoc, 'ch_1');
      expect(channel.name, 'beIN Sports 1');
      expect(channel.defaultStreamUrl, 'https://stream.example.com/bein1.m3u8');
      expect(channel.isActive, isTrue);

      // Legacy fallback with stream_url and enabled
      final fallbackDoc = {
        'name': 'SSC 1',
        'stream_url': 'https://stream.example.com/ssc1.m3u8',
        'enabled': false,
        'order': 2,
      };
      final fallbackChannel = TvChannelModel.fromMap(fallbackDoc, 'ch_2');
      expect(fallbackChannel.defaultStreamUrl, 'https://stream.example.com/ssc1.m3u8');
      expect(fallbackChannel.isActive, isFalse);
    });
  });

  group('2. Match Polls Tests', () {
    test('PollModel requires explicit enabled == true and non-empty options', () {
      final disabledDoc = {
        'question': 'من تتوقع أن يفوز؟',
        'enabled': false,
        'options': [
          {'id': 'opt_1', 'label': 'الفريق أ', 'votes': 10},
        ],
      };
      final poll = PollModel.fromMap(disabledDoc, 'match_100');
      expect(poll.enabled, isFalse);

      final missingEnabledDoc = {
        'question': 'من تتوقع أن يفوز؟',
        'options': [
          {'id': 'opt_1', 'label': 'الفريق أ', 'votes': 10},
        ],
      };
      final defaultDisabledPoll = PollModel.fromMap(missingEnabledDoc, 'match_100');
      expect(defaultDisabledPoll.enabled, isFalse);

      final validDoc = {
        'question': 'من تتوقع أن يفوز؟',
        'enabled': true,
        'options': [
          {'id': 'opt_a', 'label': 'أرسنال', 'votes': 50},
          {'id': 'opt_b', 'label': 'تشيلسي', 'votes': 30},
        ],
      };
      final validPoll = PollModel.fromMap(validDoc, 'match_100');
      expect(validPoll.enabled, isTrue);
      expect(validPoll.options.length, 2);
      expect(validPoll.options.first.id, 'opt_a');
    });
  });

  group('3. Notification Deduplication Tests', () {
    test('FCM-first delivery accepts FCM and suppresses subsequent Firestore broadcast', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dedupe = NotificationDeduplicator(prefs);

      // 1. FCM arrives first
      final fcmAllowed = await dedupe.shouldDisplay(
        id: 'msg_fcm_100',
        title: 'هدف لريال مدريد!',
        body: 'فينيسيوس جونيور يسجل الهدف الأول',
        matchId: '12345',
      );
      expect(fcmAllowed, isTrue);

      // 2. Firestore dual-delivery arrives second with the exact same ID
      final firestoreAllowed = await dedupe.shouldDisplay(
        id: 'msg_fcm_100',
        title: 'هدف لريال مدريد!',
        body: 'فينيسيوس جونيور يسجل الهدف الأول',
        matchId: '12345',
      );
      expect(firestoreAllowed, isFalse);
    });

    test('Firestore-first delivery accepts Firestore and suppresses subsequent FCM message', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dedupe = NotificationDeduplicator(prefs);

      // 1. Firestore arrives first with Admin SDK full message ID
      final fsAllowed = await dedupe.shouldDisplay(
        id: 'projects/shoot-live/messages/fcm_msg_200',
        title: 'بداية الشوط الثاني',
        body: 'الأهلي × الزمالك',
        matchId: '998877',
      );
      expect(fsAllowed, isTrue);

      // 2. Client FCM arrives second with normalized message ID
      final fcmAllowed = await dedupe.shouldDisplay(
        id: 'fcm_msg_200',
        title: 'بداية الشوط الثاني',
        body: 'الأهلي × الزمالك',
        matchId: '998877',
      );
      expect(fcmAllowed, isFalse);
    });

    test('Duplicate content suppression with different/empty IDs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dedupe = NotificationDeduplicator(prefs);

      final first = await dedupe.shouldDisplay(
        id: 'auto_id_1',
        title: 'تنبيه مباراة',
        body: 'ليفربول × مانشستر سيتي تبدأ بعد قليل',
        matchId: '554433',
      );
      expect(first, isTrue);

      // Re-delivery of identical notification content without matching ID
      final second = await dedupe.shouldDisplay(
        id: 'auto_id_2',
        title: 'تنبيه مباراة',
        body: 'ليفربول × مانشستر سيتي تبدأ بعد قليل',
        matchId: '554433',
      );
      expect(second, isFalse);
    });

    test('App-killed persistence test: SharedPreferences retains seen notification', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs1 = await SharedPreferences.getInstance();
      final dedupe1 = NotificationDeduplicator(prefs1);

      await dedupe1.shouldDisplay(
        id: 'persisted_msg_300',
        title: 'تنبيه عاجل',
        body: 'مباراة اليوم',
      );

      // Simulate app kill and fresh startup with fresh deduplicator instance
      final dedupe2 = NotificationDeduplicator(prefs1);
      final duplicateOnColdStart = await dedupe2.shouldDisplay(
        id: 'persisted_msg_300',
        title: 'تنبيه عاجل',
        body: 'مباراة اليوم',
      );
      expect(duplicateOnColdStart, isFalse);
    });
  });

  group('4. Match Status Resolution Tests (Feed Trust & 6-Hour Fallback)', () {
    test('Delayed match with status=0 or "لم تبدأ" is NEVER marked finished after elapsed time', () {
      final now = DateTime(2026, 11, 11, 23, 0); // 11 PM
      final delayedMatch = {
        'match_date': '2026-11-11',
        'match_time': '18:00:00', // 6 PM (5 hours ago)
        'status': 0,
        'event_status': 'not_started',
        'status_text': 'لم تبدأ',
      };

      final statusInfo = MatchStatusResolver.resolve(delayedMatch, now: now);
      expect(statusInfo.state, MatchState.notStarted);
    });

    test('Postponed match is resolved as postponed regardless of kickoff time', () {
      final now = DateTime(2026, 11, 11, 23, 0);
      final postponedMatch = {
        'match_date': '2026-11-11',
        'match_time': '15:00:00',
        'status': 0,
        'event_status': 'postponed',
        'admin_badge': 'postponed',
      };

      final statusInfo = MatchStatusResolver.resolve(postponedMatch, now: now);
      expect(statusInfo.state, MatchState.postponed);
    });

    test('Live overrun with extra time (status=5,6) or penalties (status=7,8) is resolved as live', () {
      final now = DateTime(2026, 11, 11, 23, 30);
      final extraTimeMatch = {
        'match_date': '2026-11-11',
        'match_time': '20:00:00', // 3.5 hours ago
        'status': 5,
        'admin_title': "105'",
      };

      final statusInfo = MatchStatusResolver.resolve(extraTimeMatch, now: now);
      expect(statusInfo.state, MatchState.live);
      expect(statusInfo.isLive, isTrue);

      final penaltyMatch = {
        'match_date': '2026-11-11',
        'match_time': '20:00:00',
        'status': 7,
        'admin_title': 'ركلات الترجيح',
      };
      final penStatus = MatchStatusResolver.resolve(penaltyMatch, now: now);
      expect(penStatus.state, MatchState.live);
    });

    test('TBD match (match_time=00:00:00 or empty) is resolved as notStarted', () {
      final tbdMatch = {
        'match_date': '2026-11-11',
        'match_time': '00:00:00',
      };
      final statusInfo = MatchStatusResolver.resolve(tbdMatch);
      expect(statusInfo.state, MatchState.notStarted);
    });

    test('Match with NO status fields at all: finished only after 6 hours (> 360 mins)', () {
      // 4 hours after kickoff -> notStarted
      final fourHoursAgo = DateTime(2026, 11, 11, 20, 0);
      final matchNoStatus = {
        'match_date': '2026-11-11',
        'match_time': '16:00:00',
      };
      final res4h = MatchStatusResolver.resolve(matchNoStatus, now: fourHoursAgo);
      expect(res4h.state, MatchState.notStarted);

      // 7 hours after kickoff (420 mins) -> finished (last-resort fallback)
      final sevenHoursAgo = DateTime(2026, 11, 11, 23, 0);
      final res7h = MatchStatusResolver.resolve(matchNoStatus, now: sevenHoursAgo);
      expect(res7h.state, MatchState.finished);
    });
  });

  group('5. Kickoff Time & kickoff_at Tests', () {
    test('kickoff_at ISO 8601 string is used when proven with ys_match_datetime_input', () {
      // ISO 8601 string with UTC Z
      const kickoffAtUtc = '2026-11-11T18:00:00Z';
      final utcInstant = KickoffTime.toUtc(
        null,
        null,
        kickoffAt: kickoffAtUtc,
        kickoffTzSource: 'ys_match_datetime_input',
      );
      expect(utcInstant, isNotNull);
      expect(utcInstant!.toIso8601String(), '2026-11-11T18:00:00.000Z');

      // ISO 8601 string with offset (e.g. UTC+3)
      const kickoffAtOffset = '2026-11-11T21:00:00+03:00';
      final parsedWithOffset = KickoffTime.toUtc(
        null,
        null,
        kickoffAt: kickoffAtOffset,
        kickoffTzSource: 'ys_match_datetime_input',
      );
      expect(parsedWithOffset, isNotNull);
      expect(parsedWithOffset!.toIso8601String(), '2026-11-11T18:00:00.000Z');

      // Local conversion
      final localDt = KickoffTime.toLocal(
        null,
        null,
        kickoffAt: kickoffAtUtc,
        kickoffTzSource: 'ys_match_datetime_input',
      );
      expect(localDt, isNotNull);
      expect(localDt!.toUtc(), DateTime.utc(2026, 11, 11, 18, 0, 0));
    });

    test('Without kickoff_at, parses in upstreamFeedTimeZone (Africa/Cairo)', () {
      final utcInstant = KickoffTime.toUtc('2026-11-11', '18:00:00');
      expect(utcInstant, isNotNull);
      // In November, Cairo is UTC+2
      expect(utcInstant!.hour, 16);
      expect(utcInstant.minute, 0);
    });

    test('KickoffTime toLocal with offset calculation', () {
      final base = KickoffTime.toLocal('2026-11-11', '18:00:00', offsetHours: 0)!;
      final plusOne = KickoffTime.toLocal('2026-11-11', '18:00:00', offsetHours: 1)!;
      final minusOne = KickoffTime.toLocal('2026-11-11', '18:00:00', offsetHours: -1)!;

      expect(plusOne.difference(base), const Duration(hours: 1));
      expect(base.difference(minusOne), const Duration(hours: 1));
    });

    test('MatchModel forwards kickoffAt when kickoff_tz_source is ys_match_datetime_input', () {
      final matchMap = {
        'id': 12345,
        'match_date': '2026-11-11',
        'match_time': '18:00:00',
        'kickoff_at': '2026-11-11T17:30:00Z',
        'kickoff_tz_source': 'ys_match_datetime_input',
        'home_team': {'name': 'ريال مدريد'},
        'away_team': {'name': 'برشلونة'},
      };

      final match = MatchModel.fromMap(matchMap);
      expect(match.kickoffAt, '2026-11-11T17:30:00Z');
      expect(match.kickoffTzSource, 'ys_match_datetime_input');
      expect(match.kickoffUtcDateTime, DateTime.utc(2026, 11, 11, 17, 30, 0));
      expect(match.formattedLocalTime, isNotEmpty);
      expect(match.formattedLocalTime, isNot('غير محدد'));
    });
  });

  group('5. Trust kickoff_at only when proven (kickoff_tz_source tests)', () {
    test('1. Trusted source "ys_match_datetime_input": accepts kickoff_at as absolute UTC', () {
      const kickoffAt = '2026-11-11T15:00:00Z';
      const tzSource = 'ys_match_datetime_input';

      // 18:00 Cairo in winter (Nov) is 16:00 UTC. But kickoff_at is 15:00 UTC.
      final utc = KickoffTime.toUtc(
        '2026-11-11',
        '18:00:00',
        kickoffAt: kickoffAt,
        kickoffTzSource: tzSource,
      );

      expect(utc, equals(DateTime.utc(2026, 11, 11, 15, 0, 0)));
    });

    test('2. Unproven source "cairo_riyadh_feed_utc3": ignores kickoff_at, parses Cairo date+time', () {
      const kickoffAt = '2026-11-11T15:00:00Z'; // Emitted with assumed UTC+3
      const tzSource = 'cairo_riyadh_feed_utc3';

      // Cairo in winter (Nov) is UTC+2: 18:00 Cairo -> 16:00 UTC.
      final utc = KickoffTime.toUtc(
        '2026-11-11',
        '18:00:00',
        kickoffAt: kickoffAt,
        kickoffTzSource: tzSource,
      );

      // kickoff_at is ignored! Parsed Cairo is 16:00 UTC.
      expect(utc, equals(DateTime.utc(2026, 11, 11, 16, 0, 0)));
    });

    test('3. Missing or unknown kickoff_tz_source: ignores kickoff_at, parses Cairo date+time', () {
      const kickoffAt = '2026-11-11T15:00:00Z';

      final utcWithoutSource = KickoffTime.toUtc(
        '2026-11-11',
        '18:00:00',
        kickoffAt: kickoffAt,
      );
      expect(utcWithoutSource, equals(DateTime.utc(2026, 11, 11, 16, 0, 0)));

      final utcWithUnknown = KickoffTime.toUtc(
        '2026-11-11',
        '18:00:00',
        kickoffAt: kickoffAt,
        kickoffTzSource: 'some_arbitrary_source',
      );
      expect(utcWithUnknown, equals(DateTime.utc(2026, 11, 11, 16, 0, 0)));
    });

    test('4. Case-insensitive and trimmed source recognition', () {
      expect(KickoffTime.isTrustedKickoffSource('  YS_MATCH_DATETIME_INPUT  '), isTrue);
      expect(KickoffTime.isTrustedKickoffSource('ys_match_datetime_input'), isTrue);
      expect(KickoffTime.isTrustedKickoffSource('cairo_riyadh_feed_utc3'), isFalse);
      expect(KickoffTime.isTrustedKickoffSource(null), isFalse);
    });

    test('5. MatchModel Diagnostics fields: computes difference between raw and Cairo UTC', () {
      final match = MatchModel.fromMap({
        'id': 777,
        'match_date': '2026-11-11',
        'match_time': '18:00:00',
        'kickoff_at': '2026-11-11T15:00:00Z',
        'kickoff_tz_source': 'cairo_riyadh_feed_utc3',
      });

      expect(match.rawKickoffAtUtcDateTime, equals(DateTime.utc(2026, 11, 11, 15, 0, 0)));
      expect(match.cairoParsedUtcDateTime, equals(DateTime.utc(2026, 11, 11, 16, 0, 0)));

      final diffMinutes = match.rawKickoffAtUtcDateTime!.difference(match.cairoParsedUtcDateTime!).inMinutes;
      expect(diffMinutes, equals(-60)); // Disagrees by 1 hour (60 minutes)

      // Verified: effective kickoffUtcDateTime ignores the unproven source
      expect(match.kickoffUtcDateTime, equals(match.cairoParsedUtcDateTime));
    });
  });

  group('6. TBD Must Never Hide A Real Result Tests', () {
    test('1. Finished match from dashboard fixture (5795507 with time 00:00:00 and score 1-3)', () {
      final fixtureFile = File('test/fixtures/dashboard_matches_by_date_sample.json');
      expect(fixtureFile.existsSync(), isTrue);

      final decoded = jsonDecode(fixtureFile.readAsStringSync()) as List<dynamic>;
      final matchRaw = decoded.firstWhere((m) => m['match_id'] == 5795507) as Map<String, dynamic>;

      final match = MatchModel.fromMap(matchRaw);

      // Must be finished
      expect(match.status, equals(MatchStatus.finished));
      expect(match.isFinished, isTrue);

      // Score must be preserved and never hidden
      expect(match.homeScore, equals('1'));
      expect(match.awayScore, equals('3'));

      // For finished match with unknown/00:00:00 time, formattedLocalTime displays the date
      expect(match.formattedLocalTime, isNot('غير محدد'));
      expect(match.formattedLocalTime, contains('نوفمبر')); // 8 نوفمبر
    });

    test('2. Finished match 5795506 (Brighton vs Brentford, 2-0, 00:00:00)', () {
      final fixtureFile = File('test/fixtures/dashboard_matches_by_date_sample.json');
      final decoded = jsonDecode(fixtureFile.readAsStringSync()) as List<dynamic>;
      final matchRaw = decoded.firstWhere((m) => m['match_id'] == 5795506) as Map<String, dynamic>;

      final match = MatchModel.fromMap(matchRaw);

      expect(match.status, equals(MatchStatus.finished));
      expect(match.homeScore, equals('2'));
      expect(match.awayScore, equals('0'));
      expect(match.formattedLocalTime, isNot('غير محدد'));
    });

    test('3. Not-started match with 00:00:00 time shows "غير محدد" and no scores', () {
      final match = MatchModel.fromMap({
        'id': 8881,
        'match_date': '2026-11-15',
        'match_time': '00:00:00',
        'status': '0',
        'event_status': 'not_started',
        'home_scores': 0,
        'away_scores': 0,
      });

      expect(match.status, equals(MatchStatus.notStarted));
      expect(match.homeScore, isNull);
      expect(match.awayScore, isNull);
      expect(match.formattedLocalTime, equals('غير محدد'));
    });

    test('4. kickoff_known flag handling', () {
      // kickoff_known == false on not-started match
      final unstartedUnknown = MatchModel.fromMap({
        'id': 8882,
        'match_date': '2026-11-15',
        'match_time': '16:00:00',
        'status': '0',
        'kickoff_known': false,
      });
      expect(unstartedUnknown.isKickoffTimeKnown, isFalse);
      expect(unstartedUnknown.formattedLocalTime, equals('غير محدد'));

      // kickoff_known == false on finished match -> shows date, never "غير محدد"
      final finishedUnknown = MatchModel.fromMap({
        'id': 8883,
        'match_date': '2026-11-15',
        'match_time': '16:00:00',
        'status': '4',
        'home_scores': 2,
        'away_scores': 1,
        'kickoff_known': false,
      });
      expect(finishedUnknown.isKickoffTimeKnown, isFalse);
      expect(finishedUnknown.homeScore, equals('2'));
      expect(finishedUnknown.awayScore, equals('1'));
      expect(finishedUnknown.formattedLocalTime, isNot('غير محدد'));
      expect(finishedUnknown.formattedLocalTime, contains('نوفمبر'));
    });
  });

  group('7. Tolerant Parsing of API Shapes (Leagues & Teams)', () {
    test('1. Leagues from dashboard fixture (wrapped envelope with "leagues")', () {
      final fixtureFile = File('test/fixtures/dashboard_leagues_sample.json');
      expect(fixtureFile.existsSync(), isTrue);

      final decoded = jsonDecode(fixtureFile.readAsStringSync());
      final leagues = LeagueModel.fromListOrMap(decoded);

      expect(leagues.length, equals(2));
      expect(leagues[0].id, equals('943009'));
      expect(leagues[0].name, equals('الدوري المصري'));
      expect(leagues[0].country, equals('مصر'));
      expect(leagues[0].logoUrl, isNull); // Empty logo in sample

      expect(leagues[1].id, equals('937599'));
      expect(leagues[1].name, equals('الدوري الإنجليزي الممتاز'));
      expect(leagues[1].logoUrl, equals('https://imgs.ysscores.com/championship/48/3411694791422.png'));
    });

    test('2. Leagues from plain array with title/image variations', () {
      final plainList = [
        {
          'id': 100,
          'title': 'دوري أبطال أوروبا',
          'image': 'https://imgs.ysscores.com/ucl.png',
        },
        {
          'id': 200,
          'name': 'الدوري الإسباني',
          'logo': 'https://imgs.ysscores.com/laliga.png',
        }
      ];

      final leagues = LeagueModel.fromListOrMap(plainList);
      expect(leagues.length, equals(2));
      expect(leagues[0].id, equals('100'));
      expect(leagues[0].name, equals('دوري أبطال أوروبا'));
      expect(leagues[0].logoUrl, equals('https://imgs.ysscores.com/ucl.png'));

      expect(leagues[1].id, equals('200'));
      expect(leagues[1].name, equals('الدوري الإسباني'));
      expect(leagues[1].logoUrl, equals('https://imgs.ysscores.com/laliga.png'));
    });

    test('3. Teams from dashboard fixture (wrapped envelope with "teams")', () {
      final fixtureFile = File('test/fixtures/dashboard_teams_sample.json');
      expect(fixtureFile.existsSync(), isTrue);

      final decoded = jsonDecode(fixtureFile.readAsStringSync());
      final teams = TeamModel.fromListOrMap(decoded);

      expect(teams.length, equals(2));
      expect(teams[0].id, equals('293352'));
      expect(teams[0].name, equals('آنسي'));
      expect(teams[0].logoUrl, equals('https://imgs.ysscores.com/teams/64/5121690370573.png'));
      expect(teams[0].leagueId, equals('952414'));

      expect(teams[1].id, equals('8640'));
      expect(teams[1].name, equals('آيندهوفن'));
      expect(teams[1].leagueId, equals('937276'));
    });

    test('4. Teams from plain array with title/image/team_name variations', () {
      final plainList = [
        {
          'row_id': 99,
          'title': 'ريال مدريد',
          'image': 'https://imgs.ysscores.com/rm.png',
          'champ_id': 43,
        },
        {
          'team_id': 88,
          'team_name': 'برشلونة',
          'logo': 'https://imgs.ysscores.com/fcb.png',
          'league_id': 43,
        }
      ];

      final teams = TeamModel.fromListOrMap(plainList);
      expect(teams.length, equals(2));
      expect(teams[0].id, equals('99'));
      expect(teams[0].name, equals('ريال مدريد'));
      expect(teams[0].logoUrl, equals('https://imgs.ysscores.com/rm.png'));
      expect(teams[0].leagueId, equals('43'));

      expect(teams[1].id, equals('88'));
      expect(teams[1].name, equals('برشلونة'));
      expect(teams[1].logoUrl, equals('https://imgs.ysscores.com/fcb.png'));
      expect(teams[1].leagueId, equals('43'));
    });
  });

  group('8. match_info Placeholder Filtering Tests', () {
    test('1. Dashboard match_info sample: filters "غير محدد", "التفاصيل", and empty strings', () {
      final fixtureFile = File('test/fixtures/dashboard_match_info_sample.json');
      expect(fixtureFile.existsSync(), isTrue);

      final decoded = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
      final info = MatchInfoModel.fromMap(decoded);

      expect(info.matchId, equals(5795507));
      // In fixture: "stadium": "غير محدد"
      expect(info.stadium, isNull);
      // In fixture: "commentator": "التفاصيل"
      expect(info.commentator, isNull);
      // In fixture: "referee": ""
      expect(info.refereeName, isNull);
      // In fixture: "channel": "بي إن سبورت 1"
      expect(info.channel, equals('بي إن سبورت 1'));
    });

    test('2. Exhaustive placeholder filtering in MatchInfoModel', () {
      for (final ph in ['-', '--', '---', '----', '—', 'null', 'undefined', 'غير محدد', 'التفاصيل', 'تفاصيل', 'معلومات', 'لا يوجد', 'لم يحدد']) {
        expect(MatchInfoModel.isPlaceholder(ph), isTrue, reason: 'Failed for placeholder "$ph"');
        expect(MatchInfoModel.isPlaceholder('  $ph  '), isTrue, reason: 'Failed for trimmed placeholder "$ph"');
      }

      // Valid names must not be treated as placeholders
      expect(MatchInfoModel.isPlaceholder('عصام الشوالي'), isFalse);
      expect(MatchInfoModel.isPlaceholder('استاد القاهرة الدولي'), isFalse);
      expect(MatchInfoModel.isPlaceholder('محمد عادل'), isFalse);
      expect(MatchInfoModel.isPlaceholder('beIN Sports 1'), isFalse);
    });

    test('3. MatchModel filters channel and commentator placeholders on construction', () {
      final match = MatchModel.fromMap({
        'id': 1001,
        'channel': 'التفاصيل',
        'commentator': 'غير محدد',
      });

      expect(match.channel, isNull);
      expect(match.commentator, isNull);

      final validMatch = MatchModel.fromMap({
        'id': 1002,
        'channel': 'SSC Extra 1',
        'commentator': 'فارس عوض',
      });

      expect(validMatch.channel, equals('SSC Extra 1'));
      expect(validMatch.commentator, equals('فارس عوض'));
    });
  });
}

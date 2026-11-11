import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/services/notification_deduplicator.dart';
import 'package:shoot_live/data/api/match_score_api.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/match_stream_model.dart';
import 'package:shoot_live/data/models/poll_model.dart';
import 'package:shoot_live/data/models/sponsorship_model.dart';
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
    test('kickoff_at ISO 8601 string is used as authoritative single source of truth', () {
      // ISO 8601 string with UTC Z
      const kickoffAtUtc = '2026-11-11T18:00:00Z';
      final utcInstant = KickoffTime.toUtc(null, null, kickoffAt: kickoffAtUtc);
      expect(utcInstant, isNotNull);
      expect(utcInstant!.toIso8601String(), '2026-11-11T18:00:00.000Z');

      // ISO 8601 string with offset (e.g. UTC+3)
      const kickoffAtOffset = '2026-11-11T21:00:00+03:00';
      final parsedWithOffset = KickoffTime.toUtc(null, null, kickoffAt: kickoffAtOffset);
      expect(parsedWithOffset, isNotNull);
      expect(parsedWithOffset!.toIso8601String(), '2026-11-11T18:00:00.000Z');

      // Local conversion
      final localDt = KickoffTime.toLocal(null, null, kickoffAt: kickoffAtUtc);
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

    test('Offsets +1, -1, 0 are applied accurately to local time', () {
      const kickoffAt = '2026-11-11T18:00:00Z';
      final base = KickoffTime.toLocal(null, null, kickoffAt: kickoffAt, offsetHours: 0)!;
      final plusOne = KickoffTime.toLocal(null, null, kickoffAt: kickoffAt, offsetHours: 1)!;
      final minusOne = KickoffTime.toLocal(null, null, kickoffAt: kickoffAt, offsetHours: -1)!;

      expect(plusOne.difference(base), const Duration(hours: 1));
      expect(base.difference(minusOne), const Duration(hours: 1));
    });

    test('MatchModel forwards kickoffAt to kickoffDateTime and formattedLocalTime', () {
      final matchMap = {
        'id': 12345,
        'match_date': '2026-11-11',
        'match_time': '18:00:00',
        'kickoff_at': '2026-11-11T17:30:00Z',
        'home_team': {'name': 'ريال مدريد'},
        'away_team': {'name': 'برشلونة'},
      };

      final match = MatchModel.fromMap(matchMap);
      expect(match.kickoffAt, '2026-11-11T17:30:00Z');
      expect(match.kickoffUtcDateTime, DateTime.utc(2026, 11, 11, 17, 30, 0));
      expect(match.formattedLocalTime, isNotEmpty);
      expect(match.formattedLocalTime, isNot('غير محدد'));
    });
  });
}

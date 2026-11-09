import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/config/app_constants.dart';
import 'package:shoot_live/data/models/match_event_model.dart';
import 'package:shoot_live/data/models/match_info_model.dart';
import 'package:shoot_live/data/models/match_lineup_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/match_statistics_model.dart';
import 'package:shoot_live/data/models/match_stream_model.dart';
import 'package:shoot_live/data/repositories/matches_repository.dart';
import 'package:shoot_live/presentation/home/providers/matches_provider.dart';
import 'package:shoot_live/presentation/match_details/match_details_screen.dart';
import 'package:shoot_live/presentation/match_details/providers/match_details_providers.dart';
import 'package:shoot_live/presentation/match_details/providers/match_stream_provider.dart';
import 'package:shoot_live/presentation/match_details/services/stream_player.dart';
import 'package:shoot_live/presentation/match_details/tabs/events_tab.dart';
import 'package:shoot_live/presentation/settings/settings_screen.dart';

class _FakeMatchesRepo implements MatchesRepository {
  @override
  Future<List<MatchModel>> getMatchesByDate(String date, {bool forceRefresh = false}) async => [];
  @override
  Future<List<MatchModel>> getMatchesToday({bool forceRefresh = false}) async => [];
  @override
  Future<List<MatchModel>> getMatchesTomorrow({bool forceRefresh = false}) async => [];
  @override
  Future<List<MatchModel>> getMatchesYesterday({bool forceRefresh = false}) async => [];
  @override
  Future<MatchInfoModel?> getMatchInfo(String matchId, {bool forceRefresh = false}) async => null;
  @override
  Future<MatchStatisticsModel?> getMatchStatistics(String matchId, {required dynamic homeTeamId, required dynamic awayTeamId, bool forceRefresh = false}) async => null;
  @override
  Future<List<MatchEventModel>> getMatchEvents(String matchId, {bool forceRefresh = false}) async => [];
  @override
  Future<MatchLineupModel?> getMatchLineup(String matchId, {required dynamic homeTeamId, required dynamic awayTeamId, bool forceRefresh = false}) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Match Events & Timeline Tests (raw_matches_event_5795507.json)', () {
    late List<MatchEventModel> parsedEvents;

    setUp(() {
      final file = File('test/fixtures/raw_matches_event_5795507.json');
      expect(file.existsSync(), isTrue, reason: 'Raw events fixture must exist');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final rawList = json['events'] as List<dynamic>;

      parsedEvents = rawList
          .map((e) => MatchEventModel.fromMap(e as Map<String, dynamic>))
          .toList();
    });

    test('Parses raw feed containing type 100 events with team_id 0', () {
      expect(parsedEvents, isNotEmpty);

      // Verify presence of type 100 period marker "انتهت المباراة"
      final matchEndEvents = parsedEvents
          .where((e) => e.statusName == 'انتهت المباراة' && e.teamId == 0)
          .toList();
      expect(matchEndEvents, isNotEmpty);
      expect(matchEndEvents.first.eventType, equals(MatchEventType.periodMarker));

      // Verify other period markers
      final halfTimeEvents = parsedEvents
          .where((e) => e.statusName == 'نهاية الشوط الأول' && e.teamId == 0)
          .toList();
      expect(halfTimeEvents, isNotEmpty);

      // Verify regular match events are also correctly parsed
      final goalEvents = parsedEvents
          .where((e) => e.eventType == MatchEventType.goal || e.eventType == MatchEventType.penaltyScored)
          .toList();
      expect(goalEvents.length, equals(4)); // Mac Allister, Wirtz, Isak, Nketiah (pen)
    });

    testWidgets('EventsTab renders "انتهت المباراة" as neutral centered marker', (tester) async {
      const homeTeamId = 9826; // Crystal Palace
      const awayTeamId = 8650; // Liverpool
      final params = MatchDetailsParams(
        matchId: '5795507',
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
      );

      final container = ProviderContainer(
        overrides: [
          matchEventsProvider(params).overrideWith((ref) => Future.value(parsedEvents)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: EventsTab(
                params: params,
                homeTeamId: homeTeamId,
                awayTeamId: awayTeamId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find all widgets displaying "انتهت المباراة"
      expect(find.text('انتهت المباراة'), findsWidgets);

      // Find period markers rendered with horizontal Dividers (neutral centered rows)
      expect(find.byType(Divider), findsWidgets);
    });

    testWidgets('EventsTab handles team_id 0 and unknown event types gracefully without crashing', (tester) async {
      const homeTeamId = 100;
      const awayTeamId = 200;
      final params = MatchDetailsParams(
        matchId: '9999',
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
      );

      // Construct exotic / unknown events
      final exoticEvents = [
        const MatchEventModel(
          eventId: 901,
          teamId: 0,
          eventType: MatchEventType.unknown,
          statusName: 'توقف مؤقت للطقس',
          minute: 33,
        ),
        const MatchEventModel(
          eventId: 902,
          teamId: 100,
          eventType: MatchEventType.unknown,
          statusName: 'حدث غير معروف في النظام',
          minute: 44,
          playerName: 'لاعب تجريبي',
        ),
        const MatchEventModel(
          eventId: 903,
          teamId: '0',
          eventType: MatchEventType.periodMarker,
          statusName: 'انتهت المباراة',
          minute: 90,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          matchEventsProvider(params).overrideWith((ref) => Future.value(exoticEvents)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: EventsTab(
                params: params,
                homeTeamId: homeTeamId,
                awayTeamId: awayTeamId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both events should render without throw
      expect(find.text('توقف مؤقت للطقس'), findsOneWidget);
      expect(find.text('حدث غير معروف في النظام'), findsOneWidget);
      expect(find.text('انتهت المباراة'), findsOneWidget);
    });
  });

  group('StreamPlayer Abstraction & Match Details Watch Button Tests', () {
    final sampleMatch = MatchModel(
      matchId: 5795507,
      matchDate: '2026-11-08',
      matchTime: '16:00',
      isLive: true,
      status: MatchStatus.live,
      championship: const ChampionshipInfo(id: 1, title: 'الدوري الإنجليزي الممتاز'),
      homeTeam: const TeamInfo(rowId: 9826, title: 'كريستال بالاس'),
      awayTeam: const TeamInfo(rowId: 8650, title: 'ليفربول'),
      homeScore: '1',
      awayScore: '3',
    );

    const activeStream = MatchStreamModel(
      matchId: 5795507,
      isEnabled: true,
      servers: [
        StreamServerModel(
          id: 'srv_1',
          name: 'سيرفر البث 1',
          streamUrl: 'https://example.com/embed/5795507',
          playerType: PlayerType.embed,
          priority: 1,
          isActive: true,
        ),
      ],
    );

    test('StreamPlayerResolver resolves appropriate player implementations', () {
      final embedPlayer = StreamPlayerResolver.resolve(PlayerType.embed);
      expect(embedPlayer, isA<EmbedStreamPlayer>());

      final hlsPlayer = StreamPlayerResolver.resolve(PlayerType.hls);
      expect(hlsPlayer, isA<HlsStreamPlayer>());

      final externalPlayer = StreamPlayerResolver.resolve(PlayerType.external);
      expect(externalPlayer, isA<ExternalStreamPlayer>());
    });

    testWidgets('Prominent "مشاهدة المباراة" button renders when ENABLE_STREAMING=true and stream active', (tester) async {
      AppConstants.enableStreaming = true;
      addTearDown(() => AppConstants.enableStreaming = false);

      final container = ProviderContainer(
        overrides: [
          matchesRepositoryProvider.overrideWithValue(_FakeMatchesRepo()),
          matchStreamProvider(5795507).overrideWith((ref) => Stream.value(activeStream)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MatchDetailsScreen(
              matchId: '5795507',
              initialMatch: sampleMatch,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Prominent button must be visible
      expect(find.text('مشاهدة المباراة'), findsOneWidget);
      // TV icon in AppBar must also be visible
      expect(find.byIcon(Icons.tv_rounded), findsOneWidget);
    });

    testWidgets('Prominent "مشاهدة المباراة" button is NOT rendered when ENABLE_STREAMING=false', (tester) async {
      AppConstants.enableStreaming = false;

      final container = ProviderContainer(
        overrides: [
          matchesRepositoryProvider.overrideWithValue(_FakeMatchesRepo()),
          matchStreamProvider(5795507).overrideWith((ref) => Stream.value(activeStream)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MatchDetailsScreen(
              matchId: '5795507',
              initialMatch: sampleMatch,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Neither button nor TV action must be visible
      expect(find.text('مشاهدة المباراة'), findsNothing);
      expect(find.byIcon(Icons.tv_rounded), findsNothing);
    });
  });

  group('Clean Settings Screen Redesign Tests', () {
    testWidgets('SettingsScreen renders strictly wired controls and no debug junk', (tester) async {
      SharedPreferences.setMockInitialValues({
        'pref_notify_match_start': true,
        'pref_notify_goal_alerts': false,
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sections (found in list, including offstage before scroll)
      expect(find.text('المظهر العام', skipOffstage: false), findsOneWidget);
      expect(find.text('الإشعارات والتنبيهات', skipOffstage: false), findsOneWidget);
      expect(find.text('المفضلة والمتابعة', skipOffstage: false), findsOneWidget);
      expect(find.text('الذاكرة المؤقتة', skipOffstage: false), findsOneWidget);
      expect(find.text('حول التطبيق', skipOffstage: false), findsOneWidget);

      // Notification toggles
      expect(find.text('تنبيه قبل بدء المباراة', skipOffstage: false), findsOneWidget);
      expect(find.text('تنبيهات الأهداف والأحداث المباشرة', skipOffstage: false), findsOneWidget);

      // Cache clear action
      expect(find.text('مساحة التخزين المؤقت', skipOffstage: false), findsOneWidget);
      expect(find.text('مسح', skipOffstage: false), findsOneWidget);

      // Legal & About links
      expect(find.text('سياسة الخصوصية', skipOffstage: false), findsOneWidget);
      expect(find.text('شروط الاستخدام والخدمة', skipOffstage: false), findsOneWidget);

      // Debug junk should NOT exist
      expect(find.text('اختبار تذكير مجدول (بعد دقيقة واحدة)'), findsNothing);
      expect(find.text('معرف الجلسة السحابية (Firebase UID):'), findsNothing);
      expect(find.text('فحص إشعارات FCM الحقيقية (Test Mode)'), findsNothing);
    });
  });
}

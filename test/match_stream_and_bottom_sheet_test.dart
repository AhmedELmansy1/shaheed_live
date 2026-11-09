import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/config/app_constants.dart';
import 'package:shoot_live/core/localization/app_strings.dart';
import 'package:shoot_live/core/utils/date_formatter.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/match_stream_model.dart';
import 'package:shoot_live/data/repositories/match_stream_repository.dart';
import 'package:shoot_live/presentation/match_details/providers/match_stream_provider.dart';
import 'package:shoot_live/presentation/widgets/bottom_sheets/watch_match_bottom_sheet.dart';

class FakeStreamRepository implements MatchStreamRepository {
  final StreamController<MatchStreamModel?> controller;

  FakeStreamRepository(this.controller);

  @override
  Stream<MatchStreamModel?> listenToMatchStream(int matchId) {
    return controller.stream;
  }

  @override
  Future<MatchStreamModel?> getMatchStreamOnce(int matchId) async {
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppConstants.enableStreaming = true;
  });

  tearDown(() {
    AppConstants.enableStreaming = false;
  });

  group('MatchStreamModel Unit Tests', () {
    test('parses valid document with numeric match_id and active servers', () {
      final json = {
        'match_id': 123456,
        'is_enabled': true,
        'servers': [
          {
            'id': 'srv_2',
            'name': 'Server 2 - SD',
            'stream_url': 'https://authorized.example/live_sd.m3u8',
            'player_type': 'hls',
            'is_active': true,
            'priority': 2,
          },
          {
            'id': 'srv_1',
            'name': 'Server 1 - HD',
            'stream_url': 'https://authorized.example/live_hd.m3u8',
            'player_type': 'hls',
            'is_active': true,
            'priority': 1,
          },
        ],
      };

      final model = MatchStreamModel.fromMap(json);
      expect(model.matchId, 123456);
      expect(model.isEnabled, isTrue);
      expect(model.servers.length, 2);
      expect(model.hasActiveServers, isTrue);

      // Verify sorted strictly by priority ascending (priority 1 then priority 2)
      final sorted = model.activeServersSorted;
      expect(sorted[0].id, 'srv_1');
      expect(sorted[0].priority, 1);
      expect(sorted[1].id, 'srv_2');
      expect(sorted[1].priority, 2);
    });

    test('handles missing document (null) safely without crashing', () {
      final model = MatchStreamModel.fromMap(null, 9999);
      expect(model.matchId, 9999);
      expect(model.isEnabled, isFalse);
      expect(model.servers, isEmpty);
      expect(model.hasActiveServers, isFalse);
      expect(model.activeServersSorted, isEmpty);
    });

    test('parses string match_id and string priority gracefully', () {
      final json = {
        'match_id': '78910',
        'is_enabled': 'true' == 'true',
        'servers': [
          {
            'id': 'srv_str',
            'name': 'String Priority Server',
            'stream_url': 'https://authorized.example/live.m3u8',
            'player_type': 'embed',
            'is_active': true,
            'priority': '1',
          },
        ],
      };

      final model = MatchStreamModel.fromMap(json);
      expect(model.matchId, 78910);
      expect(model.servers.first.priority, 1);
      expect(model.servers.first.playerType, PlayerType.embed);
    });

    test('filters out inactive servers, invalid URL schemes, and respects is_enabled=false', () {
      final json = {
        'match_id': 555,
        'is_enabled': true,
        'servers': [
          {
            'id': 'srv_inactive',
            'name': 'Inactive Server',
            'stream_url': 'https://authorized.example/live.m3u8',
            'is_active': false,
            'priority': 1,
          },
          {
            'id': 'srv_bad_scheme',
            'name': 'Dangerous Scheme Server',
            'stream_url': 'javascript:alert(1)',
            'is_active': true,
            'priority': 2,
          },
          {
            'id': 'srv_valid',
            'name': 'Valid HTTPS Server',
            'stream_url': 'https://authorized.example/live.m3u8',
            'is_active': true,
            'priority': 3,
          },
        ],
      };

      final enabledModel = MatchStreamModel.fromMap(json);
      expect(enabledModel.servers.length, 3);
      // Only srv_valid passes both isActive and isValidUrl
      expect(enabledModel.activeServersSorted.length, 1);
      expect(enabledModel.activeServersSorted.first.id, 'srv_valid');

      // Disabled configuration returns empty active servers
      final disabledJson = Map<String, dynamic>.from(json)..['is_enabled'] = false;
      final disabledModel = MatchStreamModel.fromMap(disabledJson);
      expect(disabledModel.hasActiveServers, isFalse);
      expect(disabledModel.activeServersSorted, isEmpty);
    });
  });

  group('WatchMatchBottomSheet Widget Tests', () {
    const dummyChampionship = ChampionshipInfo(id: 1933, title: 'الدوري الإسباني');
    const dummyHomeTeam = TeamInfo(rowId: 1, title: 'ريال مدريد');
    const dummyAwayTeam = TeamInfo(rowId: 2, title: 'برشلونة');

    testWidgets('Displays pre-match countdown waiting UI when match is > 5 minutes away', (tester) async {
      final controller = StreamController<MatchStreamModel?>.broadcast();
      addTearDown(controller.close);

      final repo = FakeStreamRepository(controller);

      final futureKickoff = DateTime.now().add(const Duration(hours: 1, minutes: 24));
      final futureMatchDate = DateFormatter.toApiDateString(futureKickoff);
      final futureMatchTime = '${futureKickoff.hour.toString().padLeft(2, '0')}:${futureKickoff.minute.toString().padLeft(2, '0')}:00';

      final testMatch = MatchModel(
        matchId: 1001,
        matchDate: futureMatchDate,
        matchTime: futureMatchTime,
        isLive: false,
        status: MatchStatus.notStarted,
        championship: dummyChampionship,
        homeTeam: dummyHomeTeam,
        awayTeam: dummyAwayTeam,
        homeScore: null,
        awayScore: null,
        adminBadge: null,
        adminTitle: null,
        eventStatus: null,
      );

      final container = ProviderContainer(
        overrides: [
          matchStreamRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: WatchMatchBottomSheet(
                matchId: 1001,
                match: testMatch,
              ),
            ),
          ),
        ),
      );

      // Emit null (no stream configured in Firestore)
      controller.add(null);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.liveStreamComingSoon), findsOneWidget);
      expect(find.text(AppStrings.streamNotPreparedYet), findsOneWidget);
      expect(find.text(AppStrings.playerAddedBeforeKickoff), findsOneWidget);
      expect(find.text(AppStrings.matchStartsIn), findsOneWidget);
      expect(find.text(AppStrings.friendlyFooter), findsOneWidget);
    });

    testWidgets('Displays imminent preparation waiting UI when match starts within 5 minutes', (tester) async {
      final controller = StreamController<MatchStreamModel?>.broadcast();
      addTearDown(controller.close);

      final repo = FakeStreamRepository(controller);

      final imminentKickoff = DateTime.now().add(const Duration(minutes: 3));
      final matchDate = DateFormatter.toApiDateString(imminentKickoff);
      final matchTime = '${imminentKickoff.hour.toString().padLeft(2, '0')}:${imminentKickoff.minute.toString().padLeft(2, '0')}:00';

      final testMatch = MatchModel(
        matchId: 1002,
        matchDate: matchDate,
        matchTime: matchTime,
        isLive: false,
        status: MatchStatus.notStarted,
        championship: dummyChampionship,
        homeTeam: dummyHomeTeam,
        awayTeam: dummyAwayTeam,
        homeScore: null,
        awayScore: null,
        adminBadge: null,
        adminTitle: null,
        eventStatus: null,
      );

      final container = ProviderContainer(
        overrides: [
          matchStreamRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: WatchMatchBottomSheet(
                matchId: 1002,
                match: testMatch,
              ),
            ),
          ),
        ),
      );

      controller.add(null);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.playerPreparingNow), findsOneWidget);
      expect(find.text(AppStrings.gettingReadyToStream), findsOneWidget);
      expect(find.text(AppStrings.playerWillAppearMoments), findsOneWidget);
      expect(find.text(AppStrings.friendlyFooter), findsOneWidget);
    });

    testWidgets('Displays started/live match waiting UI with Retry action when stream is missing', (tester) async {
      final controller = StreamController<MatchStreamModel?>.broadcast();
      addTearDown(controller.close);

      final repo = FakeStreamRepository(controller);

      final testMatch = MatchModel(
        matchId: 1003,
        matchDate: DateFormatter.toApiDateString(DateTime.now()),
        matchTime: '12:00:00',
        isLive: true,
        status: MatchStatus.live,
        championship: dummyChampionship,
        homeTeam: dummyHomeTeam,
        awayTeam: dummyAwayTeam,
        homeScore: '1',
        awayScore: '0',
        adminBadge: null,
        adminTitle: '45\'',
        eventStatus: null,
      );

      final container = ProviderContainer(
        overrides: [
          matchStreamRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: WatchMatchBottomSheet(
                matchId: 1003,
                match: testMatch,
              ),
            ),
          ),
        ),
      );

      controller.add(null);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.streamPreparingStarted), findsOneWidget);
      expect(find.text(AppStrings.matchStartedWorkingOnPlayer), findsOneWidget);
      expect(find.text(AppStrings.pleaseTryAgainShortly), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
      expect(find.text(AppStrings.friendlyFooter), findsOneWidget);
    });

    testWidgets('Automatically updates to Server List in REAL TIME when Firestore stream is added while sheet is open', (tester) async {
      final controller = StreamController<MatchStreamModel?>.broadcast();
      addTearDown(controller.close);

      final repo = FakeStreamRepository(controller);

      final container = ProviderContainer(
        overrides: [
          matchStreamRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: WatchMatchBottomSheet(
                matchId: 1004,
              ),
            ),
          ),
        ),
      );

      // Step 1: Document does not exist in Firestore -> waiting UI is shown
      controller.add(null);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.liveStreamComingSoon), findsOneWidget);
      expect(find.text('سيرفر 1 — Full HD'), findsNothing);

      // Step 2: Administrator adds stream in Firestore Dashboard -> real-time snapshot arrives!
      controller.add(
        const MatchStreamModel(
          matchId: 1004,
          isEnabled: true,
          servers: [
            StreamServerModel(
              id: 'srv_1',
              name: 'سيرفر 1 — Full HD',
              streamUrl: 'https://authorized.example/live_hd.m3u8',
              playerType: PlayerType.hls,
              isActive: true,
              priority: 1,
            ),
            StreamServerModel(
              id: 'srv_2',
              name: 'سيرفر 2 — SD',
              streamUrl: 'https://authorized.example/live_sd.m3u8',
              playerType: PlayerType.hls,
              isActive: true,
              priority: 2,
            ),
          ],
        ),
      );

      // Widget rebuilds automatically on stream snapshot!
      await tester.pumpAndSettle();

      // Waiting UI is replaced with Available Servers list without user action!
      expect(find.text(AppStrings.liveStreamsTitle), findsOneWidget);
      expect(find.text(AppStrings.chooseServer), findsOneWidget);
      expect(find.text('سيرفر 1 — Full HD'), findsOneWidget);
      expect(find.text('سيرفر 2 — SD'), findsOneWidget);
      expect(find.text('مباشر'), findsNWidgets(2));
    });
  });
}


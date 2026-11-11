import 'dart:async';

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
import 'package:shoot_live/data/repositories/match_stream_repository.dart';
import 'package:shoot_live/data/repositories/matches_repository.dart';
import 'package:shoot_live/presentation/home/providers/matches_provider.dart';
import 'package:shoot_live/presentation/match_details/match_details_screen.dart';
import 'package:shoot_live/presentation/match_details/providers/match_stream_provider.dart';
import 'package:shoot_live/presentation/match_details/screens/embed_player_screen.dart';

class MockStreamRepository implements MatchStreamRepository {
  final StreamController<MatchStreamModel?> controller;
  MatchStreamModel? currentModel;

  MockStreamRepository(this.controller, [this.currentModel]);

  @override
  Stream<MatchStreamModel?> listenToMatchStream(int matchId) {
    return controller.stream;
  }

  @override
  Future<MatchStreamModel?> getMatchStreamOnce(int matchId) async {
    return currentModel;
  }

  @override
  Stream<int?> listenToFeaturedMatchId() => Stream.value(null);
}

class FakeMatchesRepo implements MatchesRepository {
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
  Future<MatchStatisticsModel?> getMatchStatistics(
    String matchId, {
    required dynamic homeTeamId,
    required dynamic awayTeamId,
    bool forceRefresh = false,
  }) async => null;
  @override
  Future<List<MatchEventModel>> getMatchEvents(String matchId, {bool forceRefresh = false}) async => [];
  @override
  Future<MatchLineupModel?> getMatchLineup(
    String matchId, {
    required dynamic homeTeamId,
    required dynamic awayTeamId,
    bool forceRefresh = false,
  }) async => null;
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

  const testChampionship = ChampionshipInfo(id: 1, title: 'الدوري الإنجليزي الممتاز');
  const testHomeTeam = TeamInfo(rowId: 10, title: 'ليفربول');
  const testAwayTeam = TeamInfo(rowId: 20, title: 'مانشستر سيتي');

  final testMatch = MatchModel(
    matchId: 4732635,
    matchDate: '2026-11-08',
    matchTime: '20:00:00',
    isLive: false,
    status: MatchStatus.notStarted,
    championship: testChampionship,
    homeTeam: testHomeTeam,
    awayTeam: testAwayTeam,
    homeScore: null,
    awayScore: null,
    adminBadge: null,
    adminTitle: null,
    eventStatus: 'not_started',
  );

  group('Stream Model Canonical Schema Compatibility Tests', () {
    test('Parses suggested Firestore document structure {match_id, stream_url, enabled}', () {
      final json = {
        'match_id': '4732635',
        'stream_url': 'https://912acsss8af382.sirtv.top/playerv5.php?match=4732635',
        'enabled': true,
      };

      final model = MatchStreamModel.fromMap(json);

      expect(model.matchId, equals(4732635));
      expect(model.isEnabled, isTrue);
      expect(model.streamUrl, equals('https://912acsss8af382.sirtv.top/playerv5.php?match=4732635'));
      expect(model.hasActiveStream, isTrue);
      expect(model.hasActiveServers, isTrue);
      expect(model.activeServersSorted.first.streamUrl, equals('https://912acsss8af382.sirtv.top/playerv5.php?match=4732635'));
      expect(model.activeServersSorted.first.playerType, equals(PlayerType.embed));
    });

    test('Disabling stream via enabled=false hides active stream', () {
      final json = {
        'match_id': 4732635,
        'stream_url': 'https://912acsss8af382.sirtv.top/playerv5.php?match=4732635',
        'enabled': false,
      };

      final model = MatchStreamModel.fromMap(json);

      expect(model.isEnabled, isFalse);
      expect(model.hasActiveStream, isFalse);
      expect(model.hasActiveServers, isFalse);
    });
  });

  group('MatchDetailsScreen Stream Integration Tests', () {
    testWidgets('Watch Match button and AppBar TV action are NOT shown when no stream document exists in Firestore', (tester) async {
      final controller = StreamController<MatchStreamModel?>.broadcast();
      addTearDown(controller.close);

      final repo = MockStreamRepository(controller, null);

      final container = ProviderContainer(
        overrides: [
          matchStreamRepositoryProvider.overrideWithValue(repo),
          matchesRepositoryProvider.overrideWithValue(FakeMatchesRepo()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MatchDetailsScreen(
              matchId: '4732635',
              initialMatch: testMatch,
            ),
          ),
        ),
      );

      controller.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify the AppBar action does NOT appear
      expect(find.byIcon(Icons.tv_rounded), findsNothing);

      // Switch to Info Tab to verify body button does NOT appear
      await tester.tap(find.widgetWithText(Tab, 'معلومات'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('شاهد البث المباشر للمباراة ⚽'), findsNothing);
    });

    testWidgets('Watch Match button appears and launches EmbedPlayerScreen when stream is enabled', (tester) async {
      final controller = StreamController<MatchStreamModel?>.broadcast();
      addTearDown(controller.close);

      const streamUrl = 'https://912acsss8af382.sirtv.top/playerv5.php?match=4732635';

      final streamModel = MatchStreamModel.fromMap({
        'match_id': '4732635',
        'stream_url': streamUrl,
        'enabled': true,
      });

      final repo = MockStreamRepository(controller, streamModel);

      final container = ProviderContainer(
        overrides: [
          matchStreamRepositoryProvider.overrideWithValue(repo),
          matchesRepositoryProvider.overrideWithValue(FakeMatchesRepo()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MatchDetailsScreen(
              matchId: '4732635',
              initialMatch: testMatch,
            ),
          ),
        ),
      );

      // Emit active stream from Firestore
      controller.add(streamModel);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify TV action icon in AppBar is visible!
      expect(find.byIcon(Icons.tv_rounded), findsOneWidget);

      // Tap TV icon in AppBar
      await tester.tap(find.byIcon(Icons.tv_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify EmbedPlayerScreen is opened with the exact stored stream_url
      expect(find.byType(EmbedPlayerScreen), findsOneWidget);
      final embedScreen = tester.widget<EmbedPlayerScreen>(find.byType(EmbedPlayerScreen));
      expect(embedScreen.streamUrl, equals(streamUrl));
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/theme/app_theme.dart';
import 'package:shoot_live/data/cache/matches_cache_service.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/presentation/widgets/hero_match_card.dart';
import 'package:shoot_live/presentation/widgets/match_card.dart';

void main() {
  late Map<String, dynamic> cupFixtureMap;

  setUpAll(() {
    final file = File('test/fixtures/cup_match_11920752.json');
    expect(file.existsSync(), isTrue);
    cupFixtureMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  });

  group('2. Local Cache Round-Trip Tests (MatchesCacheService & SharedPreferences)', () {
    test('stores and restores team names and scores correctly without loss or corruption', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cacheService = MatchesCacheService(prefs: prefs);

      const testDate = '2026-11-09';
      // Save raw data list containing the cup fixture
      await cacheService.saveMatches(testDate, [cupFixtureMap]);

      // Retrieve cached matches
      final cachedResult = cacheService.getCachedMatches(testDate);
      expect(cachedResult, isNotNull);
      expect(cachedResult!.matches.length, equals(1));

      final restoredMatch = cachedResult.matches.first;
      expect(restoredMatch.matchId, equals(11920752));
      expect(restoredMatch.homeTeamName, equals('وادي دجلة'));
      expect(restoredMatch.awayTeamName, equals('كهرباء الإسماعيلية'));
      expect(restoredMatch.homeTeamId, equals(205190));
      expect(restoredMatch.awayTeamId, equals(316480));
      expect(restoredMatch.homeScore, isNotNull);
      expect(restoredMatch.awayScore, isNotNull);
      expect(restoredMatch.isFinished, isTrue);
    });

    test('recovers gracefully from stale cached models with empty title string', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cacheService = MatchesCacheService(prefs: prefs);

      const testDate = '2026-11-09';
      // Simulate an old/stale cached payload where title was empty string ""
      final stalePayload = Map<String, dynamic>.from(cupFixtureMap);
      stalePayload['home_team'] = {'row_id': 205190, 'title': '', 'image': ''};
      stalePayload['away_team'] = {'row_id': 316480, 'title': '   ', 'image': ''};

      await cacheService.saveMatches(testDate, [stalePayload]);

      final cachedResult = cacheService.getCachedMatches(testDate);
      expect(cachedResult, isNotNull);
      final restoredMatch = cachedResult!.matches.first;

      // Modern MatchModel must NOT return empty string to presentation layer
      expect(restoredMatch.homeTeamName, equals('فريق غير محدد'));
      expect(restoredMatch.awayTeamName, equals('فريق غير محدد'));
      expect(restoredMatch.homeTeamName.isNotEmpty, isTrue);
      expect(restoredMatch.awayTeamName.isNotEmpty, isTrue);
    });
  });

  group('3. Rendering Current MatchCard & HeroMatchCard (Light & Dark, 360dp, TextScale 1.3)', () {
    Future<void> set360dpViewport(WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
    }

    tearDown(() {
      // Reset view after each test
    });

    for (final isDark in [false, true]) {
      final themeName = isDark ? 'Dark' : 'Light';
      final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;

      testWidgets('MatchCard ($themeName mode, 360dp, textScale 1.3) renders team names without overflow', (tester) async {
        await set360dpViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        final match = MatchModel.fromMap(cupFixtureMap);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: theme,
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(360, 800),
                  textScaler: TextScaler.linear(1.3),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: MatchCard(match: match),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Assert team names are found
        expect(find.text('وادي دجلة'), findsOneWidget);
        expect(find.text('كهرباء الإسماعيلية'), findsOneWidget);

        // 2. Assert league title is found
        expect(find.text('كأس مصر'), findsOneWidget);

        // 3. Assert finished score is found
        expect(find.text('0'), findsNWidgets(2));

        // 4. Assert no overflow error widgets
        expect(tester.takeException(), isNull);
      });

      testWidgets('HeroMatchCard ($themeName mode, 360dp, textScale 1.3) renders team names without overflow', (tester) async {
        await set360dpViewport(tester);
        addTearDown(() => tester.view.resetPhysicalSize());

        final match = MatchModel.fromMap(cupFixtureMap);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: theme,
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(360, 800),
                  textScaler: TextScaler.linear(1.3),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: HeroMatchCard(match: match),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Assert team names are found
        expect(find.text('وادي دجلة'), findsOneWidget);
        expect(find.text('كهرباء الإسماعيلية'), findsOneWidget);

        // 2. Assert league title is found
        expect(find.text('كأس مصر'), findsOneWidget);

        // 3. Assert finished score is found
        expect(find.text('0'), findsNWidgets(2));

        // 4. Assert no overflow error widgets
        expect(tester.takeException(), isNull);
      });
    }
  });
}

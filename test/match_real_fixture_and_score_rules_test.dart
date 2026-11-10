import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/core/theme/app_theme.dart';
import 'package:shoot_live/core/utils/app_number_format.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/presentation/widgets/match_card.dart';
import 'package:shoot_live/presentation/widgets/score_view.dart';

void main() {
  group('1. Real Cup Match Fixture Tests (test/fixtures/cup_match_11920752.json)', () {
    test('Parses real كأس مصر match fixture without empty team names and formatted scores', () {
      final file = File('test/fixtures/cup_match_11920752.json');
      expect(file.existsSync(), isTrue, reason: 'Real fixture file must exist');

      final jsonStr = file.readAsStringSync();
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      final match = MatchModel.fromMap(map);

      // Verify exact keys holding team names/ids/logos
      expect(match.matchId, equals(11920752));
      expect(match.leagueName, equals('كأس مصر'));
      expect(match.homeTeamName, equals('وادي دجلة'));
      expect(match.awayTeamName, equals('كهرباء الإسماعيلية'));
      expect(match.homeTeamId, equals(205190));
      expect(match.awayTeamId, equals(316480));
      expect(match.homeTeamLogo, isNotNull);
      expect(match.awayTeamLogo, isNotNull);
      expect(match.isFinished, isTrue);

      // Verify 0 - 0 finished match is parsed cleanly
      expect(match.homeScore, isNotNull);
      expect(match.awayScore, isNotNull);
      expect(AppNumberFormat.formatScorePair(match.homeScore, match.awayScore), equals('0 - 0'));
    });

    test('Fallback to "فريق غير محدد" is only used as a last resort', () {
      // With root home_name fallback
      final matchWithRootNames = MatchModel.fromMap({
        'match_id': 99991,
        'home_team': {'title': ''}, // empty title
        'away_team': {'title': '   '}, // whitespace title
        'home_name': 'الأهلي',
        'away_name': 'الزمالك',
        'championship': {'title': 'كأس مصر'},
      });
      expect(matchWithRootNames.homeTeamName, equals('الأهلي'));
      expect(matchWithRootNames.awayTeamName, equals('الزمالك'));

      // Last resort fallback
      final matchCompletelyBlank = MatchModel.fromMap({
        'match_id': 99992,
        'home_team': null,
        'away_team': null,
        'championship': {'title': 'كأس مصر'},
      });
      expect(matchCompletelyBlank.homeTeamName, equals('فريق غير محدد'));
      expect(matchCompletelyBlank.awayTeamName, equals('فريق غير محدد'));
    });
  });

  group('2. Score Display Rules (ScoreView & MatchCard)', () {
    testWidgets('Finished 0-0 match displays "0 : 0" with real Latin numerals', (tester) async {
      final finishedZeroMatch = MatchModel.fromMap({
        'match_id': 101,
        'status': 4,
        'event_status': 'finished',
        'home_scores': 0,
        'away_scores': 0,
        'home_team': {'title': 'فريق أ'},
        'away_team': {'title': 'فريق ب'},
        'championship': {'title': 'كأس مصر'},
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: MatchCard(match: finishedZeroMatch),
            ),
          ),
        ),
      );
      await tester.pump();

      // Must find real Latin digits 0
      expect(find.text('0'), findsNWidgets(2));
      expect(find.text(':'), findsOneWidget);
      // Never placeholder dots
      expect(find.text('· : ·'), findsNothing);
      expect(find.text('— : —'), findsNothing);
    });

    testWidgets('Live and Half-time match displays real numbers including 0', (tester) async {
      final liveMatch = MatchModel.fromMap({
        'match_id': 102,
        'status': 1,
        'live': 1,
        'event_status': 'live',
        'home_scores': 1,
        'away_scores': 0,
        'home_team': {'title': 'ليفربول'},
        'away_team': {'title': 'مانشستر سيتي'},
        'championship': {'title': 'الدوري الإنجليزي الممتاز'},
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: MatchCard(match: liveMatch),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('Upcoming / Not started match displays kickoff time (never 0:0 or dots)', (tester) async {
      final upcomingMatch = MatchModel.fromMap({
        'match_id': 103,
        'status': 0,
        'event_status': 'not_started',
        'match_date': '2026-11-10',
        'match_time': '20:45:00',
        'home_scores': 0, // Even if raw feed had 0 for upcoming
        'away_scores': 0,
        'home_team': {'title': 'ريال مدريد'},
        'away_team': {'title': 'برشلونة'},
        'championship': {'title': 'الدوري الإسباني'},
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: MatchCard(match: upcomingMatch),
            ),
          ),
        ),
      );
      await tester.pump();

      // Must NOT show 0 : 0
      expect(find.text('0'), findsNothing);
      expect(find.text('· : ·'), findsNothing);
      // Must show formatted kickoff time (found in center and status chip)
      expect(find.text(upcomingMatch.formattedLocalTime), findsAtLeastNWidgets(1));
    });

    testWidgets('Postponed match displays status text "تأجلت"', (tester) async {
      final postponedMatch = MatchModel.fromMap({
        'match_id': 104,
        'status': 14,
        'event_status': 'postponed',
        'home_team': {'title': 'فريق أ'},
        'away_team': {'title': 'فريق ب'},
        'championship': {'title': 'الدوري'},
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: MatchCard(match: postponedMatch),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('تأجلت'), findsWidgets);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('Cancelled match displays status text "ألغيت"', (tester) async {
      final cancelledMatch = MatchModel.fromMap({
        'match_id': 105,
        'status': 12,
        'event_status': 'cancelled',
        'home_team': {'title': 'فريق أ'},
        'away_team': {'title': 'فريق ب'},
        'championship': {'title': 'الدوري'},
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: MatchCard(match: cancelledMatch),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ألغيت'), findsWidgets);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('Live / Finished match with missing score displays "—" with semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Center(
              child: ScoreView(
                homeScore: null,
                awayScore: null,
                isFinished: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('—'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'النتيجة غير متوفرة بعد',
        ),
        findsOneWidget,
      );
    });
  });
}

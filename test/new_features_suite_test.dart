import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/services/floating_score_manager.dart';
import 'package:shoot_live/data/cache/matches_cache_service.dart';
import 'package:shoot_live/data/models/match_event_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/presentation/match_details/widgets/live_match_reactions_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Match Real Minute & Status Parsing', () {
    test('currentMinute extracts minute from adminTitle when live', () {
      final match = MatchModel(
        matchId: 101,
        isLive: true,
        status: MatchStatus.live,
        adminTitle: "38'",
        championship: const ChampionshipInfo(id: 1, title: 'الدوري المصري'),
        homeTeam: const TeamInfo(rowId: 1, title: 'الأهلي'),
        awayTeam: const TeamInfo(rowId: 2, title: 'الزمالك'),
      );

      expect(match.currentMinute, equals("38'"));
    });

    test('currentMinute returns "استراحة" when status is paused (halftime)', () {
      final match = MatchModel(
        matchId: 102,
        isLive: true,
        status: MatchStatus.paused,
        adminTitle: 'استراحة',
        championship: const ChampionshipInfo(id: 1, title: 'الدوري المصري'),
        homeTeam: const TeamInfo(rowId: 1, title: 'الأهلي'),
        awayTeam: const TeamInfo(rowId: 2, title: 'الزمالك'),
      );

      expect(match.currentMinute, equals('استراحة'));
    });

    test('MatchModel.fromMap populates resolvedAdminTitle from live_minute', () {
      final map = {
        'id': 103,
        'live': 1,
        'status': '1',
        'event_status': 'live',
        'live_minute': 67,
        'home_scores': 2,
        'away_scores': 1,
        'home_team': {'row_id': 1, 'title': 'الأهلي'},
        'away_team': {'row_id': 2, 'title': 'الزمالك'},
        'championship': {'id': 1, 'title': 'الدوري'},
      };

      final match = MatchModel.fromMap(map);
      expect(match.isLive, isTrue);
      expect(match.currentMinute, equals("67'"));
    });
  });

  group('Match Event Model & Goal Video Highlights', () {
    test('MatchEventModel parses videoUrl and identifies goal correctly', () {
      final map = {
        'id': 501,
        'team_id': 1,
        'type': 1, // Goal
        'time_minute': 23,
        'player': 'محمد صلاح',
        'video_url': 'https://example.com/clips/goal_salah.mp4',
      };

      final event = MatchEventModel.fromMap(map);
      expect(event.isGoal, isTrue);
      expect(event.playerName, equals('محمد صلاح'));
      expect(event.minute, equals(23));
      expect(event.videoUrl, equals('https://example.com/clips/goal_salah.mp4'));
    });
  });

  group('MatchesCacheService Standings Storage', () {
    test('saveStandings and getCachedStandings stores and restores rows round-trip', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = MatchesCacheService(prefs: prefs);

      final mockRankResponse = {
        'list_match': [
          {
            'team_id': 1,
            'name': 'الأهلي',
            'team_name': {'title': 'الأهلي', 'image': 'https://example.com/ahly.png'},
            'standing': 1,
            'play': 10,
            'wins': 8,
            'draw': 2,
            'lose': 0,
            'points': 26,
            'diff': 18,
          },
        ],
      };

      await cache.saveStandings(999, mockRankResponse);
      final cachedRows = cache.getCachedStandings(999);

      expect(cachedRows, isNotNull);
      expect(cachedRows!.length, equals(1));
      expect(cachedRows.first.teamName, equals('الأهلي'));
      expect(cachedRows.first.points, equals(26));
    });
  });

  group('Floating Score Manager & Live Match Reactions Widget', () {
    test('FloatingScoreManager toggles match state cleanly', () {
      final match = MatchModel(
        matchId: 777,
        isLive: true,
        status: MatchStatus.live,
        homeScore: '1',
        awayScore: '0',
        championship: const ChampionshipInfo(id: 1, title: 'الدوري الإنجليزي'),
        homeTeam: const TeamInfo(rowId: 1, title: 'ليفربول'),
        awayTeam: const TeamInfo(rowId: 2, title: 'أرسنال'),
      );

      expect(FloatingScoreManager.instance.isPinned, isFalse);
      expect(FloatingScoreManager.instance.pinnedMatchId, isNull);
      expect(match.id, equals('777'));
    });

    testWidgets('LiveMatchReactionsBar renders reaction emojis and counters', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveMatchReactionsBar(matchId: '12345'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('⚽'), findsOneWidget);
      expect(find.text('👏'), findsOneWidget);

      // Tap on fire reaction
      await tester.tap(find.text('🔥'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Assert count incremented from initial 124 to 125
      expect(find.text('125'), findsOneWidget);
    });
  });
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/data/api/match_score_api.dart' as api;
import 'package:shoot_live/data/models/match_event_model.dart';
import 'package:shoot_live/data/models/match_lineup_model.dart';
import 'package:shoot_live/data/models/match_statistics_model.dart';

void main() {
  group('LineupParser & MatchLineupModel with real fixtures', () {
    test('parses real YsScores lineup JSON (info, position groups G/D/M/F, substitutions)', () {
      final file = File('test/fixtures/lineup_finished_5795507.json');
      expect(file.existsSync(), isTrue, reason: 'lineup fixture must exist');

      final rawJson = jsonDecode(file.readAsStringSync());
      final parsed = api.LineupParser.parse(rawJson, homeId: 9826, awayId: 8650);

      expect(parsed, isNotNull);
      expect(parsed!.home.teamId, 9826);
      expect(parsed.away.teamId, 8650);
      expect(parsed.home.formation, isNotEmpty);
      expect(parsed.away.formation, isNotEmpty);

      // Starters must be 11 players each
      expect(parsed.home.starters.length, 11);
      expect(parsed.away.starters.length, 11);

      // Verify goalkeeper exists and is normalised to 'G'
      final homeGk = parsed.home.starters.firstWhere((p) => p.position == 'G');
      expect(homeGk.name, isNotEmpty);
      final awayGk = parsed.away.starters.firstWhere((p) => p.position == 'G');
      expect(awayGk.name, isNotEmpty);

      // Verify substitutions are parsed
      expect(parsed.home.substitutes, isNotEmpty);
      expect(parsed.away.substitutes, isNotEmpty);

      // Test delegation via MatchLineupModel.fromResponse
      final model = MatchLineupModel.fromResponse(rawJson, 9826, 8650);
      expect(model, isNotNull);
      expect(model!.homeLineup.startingXI.length, 11);
      expect(model.awayLineup.startingXI.length, 11);
      expect(model.homeLineup.substitutes, isNotEmpty);
      expect(model.awayLineup.substitutes, isNotEmpty);
    });

    test('returns null gracefully when lineup data is empty', () {
      expect(api.LineupParser.parse({}), isNull);
      expect(api.LineupParser.parse({'info': {}, 'lineup': {}}), isNull);
      expect(MatchLineupModel.fromResponse(null, 1, 2), isNull);
    });
  });

  group('Statistics parser with dashboard output', () {
    test('parses statistics correctly into MatchStatisticsModel and StatsParser', () {
      final payload = {
        'statics': {
          '9826': {
            'team_id': 9826,
            'ball_possession': 53,
            'total_shots': 19,
            'shots_on_goal': 7,
            'corner_kicks': 4,
            'yellow_cards': 2,
            'goalkeeper_saves': 5,
          },
          '8650': {
            'team_id': 8650,
            'ball_possession': 47,
            'total_shots': 20,
            'shots_on_goal': 8,
            'corner_kicks': 7,
            'yellow_cards': 4,
            'goalkeeper_saves': 6,
          },
        }
      };

      // Test StatsParser
      final statsMap = api.StatsParser.parse(payload);
      expect(statsMap[9826]!['ball_possession'], 53);
      expect(statsMap[8650]!['total_shots'], 20);

      // Test MatchStatisticsModel
      final model = MatchStatisticsModel.fromResponse(payload, 9826, 8650);
      expect(model, isNotNull);
      expect(model!.homeStats.possession, 53);
      expect(model.homeStats.totalShots, 19);
      expect(model.homeStats.shotsOnGoal, 7);
      expect(model.homeStats.corners, 4);
      expect(model.awayStats.possession, 47);
      expect(model.awayStats.totalShots, 20);
      expect(model.awayStats.shotsOnGoal, 8);
      expect(model.awayStats.corners, 7);
    });

    test('returns null safely for empty statistics', () {
      expect(MatchStatisticsModel.fromResponse({'statics': {}}, 1, 2), isNull);
      expect(MatchStatisticsModel.fromResponse(null, 1, 2), isNull);
      expect(api.StatsParser.parse({'statics': {}}), isEmpty);
    });
  });

  group('Events parser with dashboard output', () {
    test('parses timeline events into MatchEventModel', () {
      final payload = [
        {
          'event_id': 72223190,
          'type': 1,
          'status': 1,
          'status_name': 'هدف',
          'time_minute': 89,
          'time_plus': 0,
          'team_id': 8650,
          'player_name': 'ألكسندر إيساك',
          'assist_player_name': 'فلوريان فيرتز',
        },
        {
          'event_id': 72223222,
          'type': 5,
          'status': 5,
          'status_name': 'ضربة جزاء',
          'time_minute': 90,
          'time_plus': 5,
          'team_id': 9826,
          'player_name': 'إيدي نيكيتاه',
          'assist_player_name': '',
        },
      ];

      final events = payload.map((e) => MatchEventModel.fromMap(e)).toList();
      expect(events.length, 2);

      final goal = events[0];
      expect(goal.eventId, 72223190);
      expect(goal.eventType, MatchEventType.goal);
      expect(goal.minute, 89);
      expect(goal.playerName, 'ألكسندر إيساك');
      expect(goal.assistPlayerName, 'فلوريان فيرتز');

      final penalty = events[1];
      expect(penalty.eventId, 72223222);
      expect(penalty.eventType, MatchEventType.penaltyScored);
      expect(penalty.minute, 90);
      expect(penalty.stoppageMinute, 5);
      expect(penalty.formattedMinute, contains('٩٠+٥'));
    });
  });
}


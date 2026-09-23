import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/data/models/match_lineup_model.dart';

void main() {
  group('MatchLineupModel & LineupPlayer Parsing Tests', () {
    test('LineupPlayer.fromMap parses real player names from short_title correctly', () {
      final samplePlayer = {
        'player_id': 10543,
        'short_title': 'محمد صلاح',
        'shirt_number': 11,
        'pos': 'F',
        'pos_title': 'مهاجم',
      };

      final player = LineupPlayer.fromMap(samplePlayer);
      expect(player.id, 10543);
      expect(player.name, 'محمد صلاح');
      expect(player.number, 11);
      expect(player.position, 'F');
      expect(player.positionTitle, 'مهاجم');
      expect(player.isSubstitute, false);
    });

    test('LineupPlayer.fromMap falls back correctly across various name keys', () {
      final player1 = LineupPlayer.fromMap({
        'player_id': 1,
        'player_name': 'إيرلينغ هالاند',
        'number': '9',
      });
      expect(player1.name, 'إيرلينغ هالاند');
      expect(player1.number, 9);

      final player2 = LineupPlayer.fromMap({
        'id': 2,
        'title': 'كيفين دي بروين',
        'shirt_no': 17,
      });
      expect(player2.name, 'كيفين دي بروين');
      expect(player2.number, 17);

      final player3 = LineupPlayer.fromMap({
        'id': 3,
        'name': 'فينيسيوس جونيور',
        'jersey_number': 7,
      });
      expect(player3.name, 'فينيسيوس جونيور');
      expect(player3.number, 7);

      final player4 = LineupPlayer.fromMap({
        'id': 4,
        'player': {'short_title': 'كيليان مبابي'},
        'num': '10',
      });
      expect(player4.name, 'كيليان مبابي');
      expect(player4.number, 10);

      // Default fallback when no name is provided
      final emptyPlayer = LineupPlayer.fromMap({});
      expect(emptyPlayer.name, 'لاعب');
      expect(emptyPlayer.number, 0);
    });

    test('MatchLineupModel.fromResponse parses full response with starting XI and substitutes', () {
      final mockApiResponse = {
        '0': {
          'home_formation': '4-3-3',
          'away_formation': '4-2-3-1',
          'home_coach': {'title': 'كارلو أنشيلوتي'},
          'away_coach': 'بيب غوارديولا',
        },
        'lineup': {
          '101': {
            'lineup': [
              {'player_id': 1, 'short_title': 'تيبو كورتوا', 'shirt_number': 1, 'pos': 'G'},
              {'player_id': 2, 'short_title': 'داني كارفاخال', 'shirt_number': 2, 'pos': 'D'},
              {'player_id': 3, 'short_title': 'أنطونيو روديغر', 'shirt_number': 22, 'pos': 'D'},
              {'player_id': 4, 'short_title': 'إيدير ميليتاو', 'shirt_number': 3, 'pos': 'D'},
              {'player_id': 5, 'short_title': 'فيرلاند ميندي', 'shirt_number': 23, 'pos': 'D'},
              {'player_id': 6, 'short_title': 'فيديريكو فالفيردي', 'shirt_number': 8, 'pos': 'M'},
              {'player_id': 7, 'short_title': 'أوريليان تشواميني', 'shirt_number': 14, 'pos': 'M'},
              {'player_id': 8, 'short_title': 'جود بيلينغهام', 'shirt_number': 5, 'pos': 'M'},
              {'player_id': 9, 'short_title': 'رودريغو غوس', 'shirt_number': 11, 'pos': 'F'},
              {'player_id': 10, 'short_title': 'كيليان مبابي', 'shirt_number': 9, 'pos': 'F'},
              {'player_id': 11, 'short_title': 'فينيسيوس جونيور', 'shirt_number': 7, 'pos': 'F'},
            ],
            'substitutions': [
              {'player_id': 12, 'short_title': 'أندري لونين', 'shirt_number': 13, 'pos': 'G'},
              {'player_id': 13, 'short_title': 'لوكا مودريتش', 'shirt_number': 10, 'pos': 'M'},
            ],
          },
          '102': {
            'lineup': [
              {'player_id': 20, 'short_title': 'إيدرسون', 'shirt_number': 31, 'pos': 'G'},
              {'player_id': 21, 'short_title': 'كايل ووكر', 'shirt_number': 2, 'pos': 'D'},
              {'player_id': 22, 'short_title': 'روبن دياز', 'shirt_number': 3, 'pos': 'D'},
              {'player_id': 23, 'short_title': 'مانويل أكانجي', 'shirt_number': 25, 'pos': 'D'},
              {'player_id': 24, 'short_title': 'يوشكو غفارديول', 'shirt_number': 24, 'pos': 'D'},
              {'player_id': 25, 'short_title': 'رودري', 'shirt_number': 16, 'pos': 'M'},
              {'player_id': 26, 'short_title': 'ماتيو كوفاسيتش', 'shirt_number': 8, 'pos': 'M'},
              {'player_id': 27, 'short_title': 'برناردو سيلفا', 'shirt_number': 20, 'pos': 'M'},
              {'player_id': 28, 'short_title': 'كيفين دي بروين', 'shirt_number': 17, 'pos': 'M'},
              {'player_id': 29, 'short_title': 'فيل فودين', 'shirt_number': 47, 'pos': 'F'},
              {'player_id': 30, 'short_title': 'إيرلينغ هالاند', 'shirt_number': 9, 'pos': 'F'},
            ],
            'substitutions': [
              {'player_id': 31, 'short_title': 'ستيفان أورتيغا', 'shirt_number': 18, 'pos': 'G'},
              {'player_id': 32, 'short_title': 'جيريمي دوكو', 'shirt_number': 11, 'pos': 'F'},
            ],
          },
        },
      };

      final lineup = MatchLineupModel.fromResponse(mockApiResponse, 101, 102);

      expect(lineup, isNotNull);
      expect(lineup!.homeLineup.formation, '4-3-3');
      expect(lineup.homeLineup.coach, 'كارلو أنشيلوتي');
      expect(lineup.homeLineup.startingXI.length, 11);
      expect(lineup.homeLineup.startingXI.first.name, 'تيبو كورتوا');
      expect(lineup.homeLineup.startingXI.last.name, 'فينيسيوس جونيور');
      expect(lineup.homeLineup.substitutes.length, 2);
      expect(lineup.homeLineup.substitutes.last.name, 'لوكا مودريتش');

      expect(lineup.awayLineup.formation, '4-2-3-1');
      expect(lineup.awayLineup.coach, 'بيب غوارديولا');
      expect(lineup.awayLineup.startingXI.length, 11);
      expect(lineup.awayLineup.startingXI.first.name, 'إيدرسون');
      expect(lineup.awayLineup.startingXI.last.name, 'إيرلينغ هالاند');
      expect(lineup.awayLineup.substitutes.length, 2);
    });

    test('MatchLineupModel.fromResponse handles empty/null responses gracefully', () {
      expect(MatchLineupModel.fromResponse(null, 1, 2), isNull);
      expect(MatchLineupModel.fromResponse({}, 1, 2), isNull);
      expect(MatchLineupModel.fromResponse({'lineup': null}, 1, 2), isNull);
    });
  });
}

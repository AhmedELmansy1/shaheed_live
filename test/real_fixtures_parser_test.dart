import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/data/api/match_score_api.dart' as api;
import 'package:shoot_live/data/models/match_event_model.dart';
import 'package:shoot_live/data/models/match_info_model.dart';
import 'package:shoot_live/data/models/match_lineup_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/match_statistics_model.dart';

void main() {
  group('Real Dashboard & Upstream Raw Fixtures Verification', () {
    test('1. raw_matches_today.json parses 13 matches with real score/status', () {
      final file = File('test/fixtures/raw_matches_today.json');
      expect(file.existsSync(), isTrue);

      final jsonString = file.readAsStringSync();
      final List<dynamic> rawList = jsonDecode(jsonString) as List<dynamic>;
      expect(rawList.length, 13);

      final matches = rawList
          .map((m) => MatchModel.fromMap(m as Map<String, dynamic>))
          .toList();
      expect(matches.length, 13);

      // Verify finished match 5116103 (Cordoba vs Lanus, status 4)
      final finishedMatch = matches.firstWhere((m) => m.id == '5116103');
      expect(finishedMatch.homeTeamName, 'كوردوبا');
      expect(finishedMatch.awayTeamName, 'لانوس');
      expect(finishedMatch.isFinished, isTrue);

      // Verify upcoming match 5105046 (Kristiansund vs Valerenga, status 0)
      final upcomingMatch = matches.firstWhere((m) => m.id == '5105046');
      expect(upcomingMatch.homeTeamName, 'كريستيانسوند');
      expect(upcomingMatch.awayTeamName, 'فاليرينغا');
      expect(upcomingMatch.status, MatchStatus.notStarted);
    });

    test('2. raw_match_info_5795507.json & 5105046.json parse correctly', () {
      final f1 = File('test/fixtures/raw_match_info_5795507.json');
      final f2 = File('test/fixtures/raw_match_info_5105046.json');
      expect(f1.existsSync(), isTrue);
      expect(f2.existsSync(), isTrue);

      final info1 = MatchInfoModel.fromMap(jsonDecode(f1.readAsStringSync()) as Map<String, dynamic>);
      expect(info1.channel, 'بي إن سبورت 1');
      expect(info1.commentator, 'التفاصيل');

      final info2 = MatchInfoModel.fromMap(jsonDecode(f2.readAsStringSync()) as Map<String, dynamic>);
      expect(info2.stadium, isNull); // 'غير محدد' is properly cleaned to null
      expect(info2.channel, isNull);
    });

    test('3. raw_statics_match_5795507.json parses real match stats', () {
      final file = File('test/fixtures/raw_statics_match_5795507.json');
      expect(file.existsSync(), isTrue);

      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final stats = MatchStatisticsModel.fromResponse(data, 'home', 'away');

      expect(stats, isNotNull);
      expect(stats!.homeStats.possession, 53);
      expect(stats.homeStats.totalShots, 19);
      expect(stats.homeStats.shotsOnGoal, 7);
      expect(stats.homeStats.corners, 4);
      expect(stats.homeStats.saves, 5);
      expect(stats.homeStats.yellowCards, 2);

      expect(stats.awayStats.possession, 47);
      expect(stats.awayStats.totalShots, 20);
      expect(stats.awayStats.shotsOnGoal, 8);
      expect(stats.awayStats.corners, 7);
      expect(stats.awayStats.saves, 6);
      expect(stats.awayStats.yellowCards, 4);
    });

    test('3b. raw_statics_match_5105046.json (empty for upcoming) fails safe', () {
      final file = File('test/fixtures/raw_statics_match_5105046.json');
      expect(file.existsSync(), isTrue);

      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final stats = MatchStatisticsModel.fromResponse(data, 'home', 'away');
      expect(stats, isNull);
    });

    test('4. raw_matches_event_5795507.json parses 27 events with real goals & cards', () {
      final file = File('test/fixtures/raw_matches_event_5795507.json');
      expect(file.existsSync(), isTrue);

      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final rawEvents = (data['events'] as List<dynamic>?) ?? [];
      expect(rawEvents.length, 27);

      final events = rawEvents
          .map((e) => MatchEventModel.fromMap(e as Map<String, dynamic>))
          .toList();
      expect(events.length, 27);

      // Verify penalty goal: Eddie Nketiah at 90+5 for team 9826 (Crystal Palace)
      final penaltyGoal = events.firstWhere(
        (e) => e.eventType == MatchEventType.penaltyScored,
      );
      expect(penaltyGoal.playerName, 'إيدي نيكيتاه');
      expect(penaltyGoal.minute, 90);
      expect(penaltyGoal.stoppageMinute, 5);
      expect(penaltyGoal.formattedMinute, '٩٠+٥\'');

      // Verify regular goals: Alexander Isak (89') and Alexis Mac Allister (40')
      final goals = events.where((e) => e.eventType == MatchEventType.goal).toList();
      expect(goals.length, 3);

      final isakGoal = goals.firstWhere((g) => g.playerName == 'ألكسندر إيساك');
      expect(isakGoal.minute, 89);
      expect(isakGoal.assistPlayerName, 'فلوريان فيرتز');

      final wirtzGoal = goals.firstWhere((g) => g.playerName == 'فلوريان فيرتز');
      expect(wirtzGoal.minute, 54);
      expect(wirtzGoal.assistPlayerName, 'برادلي باركولا');

      final macGoal = goals.firstWhere((g) => g.playerName == 'ألكسيس ماك اليستير');
      expect(macGoal.minute, 40);
      expect(macGoal.assistPlayerName, 'دومينيك سوبوسلاي');
    });

    test('5. raw_matches_lineup_5795507.json parses 11 starters & 9 subs per team', () {
      final file = File('test/fixtures/raw_matches_lineup_5795507.json');
      expect(file.existsSync(), isTrue);

      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      // Parse via LineupParser
      final parsed = api.LineupParser.parse(data, homeId: 9826, awayId: 8650);
      expect(parsed, isNotNull);

      // Home: Crystal Palace (9826)
      expect(parsed!.home.formation, '3-4-2-1');
      expect(parsed.home.coach, 'بيار ساج');
      expect(parsed.home.starters.length, 11, reason: 'Expected 11 starters (1 GK + 3 DEF + 4 MID + 2 FWD + 1 STR)');
      expect(parsed.home.substitutes.length, 9, reason: 'Expected 9 substitutes');

      // Away: Liverpool (8650)
      expect(parsed.away.formation, '4-2-3-1');
      expect(parsed.away.coach, 'أندوني إيراولا');
      expect(parsed.away.starters.length, 11, reason: 'Expected 11 starters (1 GK + 4 DEF + 2 MID + 3 FWD + 1 STR)');
      expect(parsed.away.substitutes.length, 9, reason: 'Expected 9 substitutes');

      // Also parse through high-level MatchLineupModel
      final model = MatchLineupModel.fromResponse(data, 9826, 8650);
      expect(model, isNotNull);
      expect(model!.homeLineup.startingXI.length, 11);
      expect(model.homeLineup.substitutes.length, 9);
      expect(model.awayLineup.startingXI.length, 11);
      expect(model.awayLineup.substitutes.length, 9);
    });

    test('5b. raw_matches_lineup_5105046.json (upcoming match) parses safely', () {
      final file = File('test/fixtures/raw_matches_lineup_5105046.json');
      expect(file.existsSync(), isTrue);

      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final parsed = api.LineupParser.parse(data);
      if (parsed != null) {
        expect(parsed.home.starters, isA<List>());
        expect(parsed.away.starters, isA<List>());
      }
    });
  });
}

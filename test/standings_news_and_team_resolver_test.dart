import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/services/team_resolver_service.dart';
import 'package:shoot_live/data/models/match_event_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/match_news_model.dart';
import 'package:shoot_live/data/models/standings_model.dart';
import 'package:shoot_live/data/models/team_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StandingsModel real JSON parsing', () {
    test('parses real get_league_rank response structure', () {
      final sampleJson = {
        "list_match": [
          {
            "1": {
              "row": 2024,
              "name": "برشلونة",
              "team_name": {
                "row_id": 8634,
                "title": "برشلونة",
                "short_title": "برشلونة",
                "full_title": "برشلونة",
                "status": 1,
                "image": "https://imgs.ysscores.com/teams/64/9541690196746.png",
                "link": "https://www.ysscores.com/ar/team/8634/FC-Barcelona"
              },
              "team_id": 8634,
              "round": 38,
              "play": 9,
              "remaining": 29,
              "wins": 9,
              "draw": 0,
              "lose": 0,
              "for": 39,
              "against": 9,
              "diff": 30,
              "points": 27,
              "last_stand": 1,
              "color": "#4986e7"
            },
            "2": {
              "row": 2026,
              "name": "ريال مدريد",
              "team_name": {
                "row_id": 8633,
                "title": "ريال مدريد",
                "image": "https://imgs.ysscores.com/teams/64/8633.png"
              },
              "team_id": 8633,
              "play": 9,
              "wins": 7,
              "draw": 1,
              "lose": 1,
              "for": 21,
              "against": 7,
              "diff": 14,
              "points": 22,
              "last_stand": 2,
              "color": "#4986e7"
            }
          }
        ]
      };

      final rows = StandingRowModel.fromResponse(sampleJson);
      expect(rows.length, 2);

      final barca = rows.first;
      expect(barca.rank, 1);
      expect(barca.teamId, 8634);
      expect(barca.teamName, 'برشلونة');
      expect(barca.teamLogo, 'https://imgs.ysscores.com/teams/64/9541690196746.png');
      expect(barca.played, 9);
      expect(barca.won, 9);
      expect(barca.drawn, 0);
      expect(barca.lost, 0);
      expect(barca.goalsFor, 39);
      expect(barca.goalsAgainst, 9);
      expect(barca.goalDiff, 30);
      expect(barca.points, 27);
      expect(barca.color, '#4986e7');

      final real = rows[1];
      expect(real.rank, 2);
      expect(real.teamId, 8633);
      expect(real.teamName, 'ريال مدريد');
      expect(real.points, 22);
    });
  });

  group('MatchNewsModel real JSON parsing', () {
    test('parses real get_match_news response structure', () {
      final sampleJson = {
        "items": [
          {
            "id": 14071181,
            "title": "رسميًا.. الاتحاد الإسباني يعاقب رايو فايكانو",
            "slug": "رسميًا-الاتحاد-الإسباني",
            "news_desc": "قرر الاتحاد الإسباني معاقبة نادي رايو فايكانو بغرامة 6 آلاف يورو",
            "image": "https://imgs.ysscores.com/news/150/17920696529757.jpg",
            "created_at": {
              "date": "2026-10-15 16:07:39.000000",
              "timezone_type": 3,
              "timezone": "Asia/Riyadh"
            },
            "link": "https://www.ysscores.com/ar/news/14071181"
          }
        ]
      };

      final items = MatchNewsItemModel.fromResponse(sampleJson);
      expect(items.length, 1);
      final item = items.first;
      expect(item.id, 14071181);
      expect(item.title, 'رسميًا.. الاتحاد الإسباني يعاقب رايو فايكانو');
      expect(item.description, contains('بغرامة 6 آلاف يورو'));
      expect(item.imageUrl, 'https://imgs.ysscores.com/news/150/17920696529757.jpg');
      expect(item.date, '2026-10-15 16:07:39.000000');
    });
  });

  group('TeamResolverService', () {
    test('resolves pre-seeded team slugs to real API row_ids', () async {
      expect(await TeamResolverService.resolveToApiRowId('real_madrid'), 8633);
      expect(await TeamResolverService.resolveToApiRowId('barcelona'), 8634);
      expect(await TeamResolverService.resolveToApiRowId('arsenal'), 9825);
      expect(await TeamResolverService.resolveToApiRowId('man_city'), 8456);
      expect(await TeamResolverService.resolveToApiRowId('chelsea'), 8455);
      // Already integer string passes through
      expect(await TeamResolverService.resolveToApiRowId('9906'), 9906);
    });

    test('dynamically resolves unseeded teams by matching match titles against allTeams', () async {
      final matches = [
        MatchModel.fromMap({
          'match_id': 12345,
          'match_date': '2026-10-24',
          'match_time': '21:00:00',
          'live': 0,
          'status': 0,
          'home_team': {'row_id': 102008, 'title': 'الأهلي'},
          'away_team': {'row_id': 102009, 'title': 'الزمالك'},
          'home_scores': 0,
          'away_scores': 0,
          'championship': {'id': 1, 'title': 'الدوري المصري'},
        }),
      ];

      final allTeams = [
        const TeamModel(id: 'ahly', name: 'الأهلي', nameEn: 'Al Ahly', leagueId: 'egy_1'),
        const TeamModel(id: 'zamalek', name: 'الزمالك', nameEn: 'Zamalek', leagueId: 'egy_1'),
      ];

      await TeamResolverService.updateMappingsFromMatches(matches, allTeams);

      expect(await TeamResolverService.resolveToApiRowId('ahly'), 102008);
      expect(await TeamResolverService.resolveToApiRowId('zamalek'), 102009);
    });
  });

  group('MatchStatusResolver and EventMapper integration', () {
    test('MatchModel uses MatchStatusResolver for ended match', () {
      final m = MatchModel.fromMap({
        'match_id': 99,
        'live': 0,
        'status': 4,
        'admin_badge': 'ended',
        'admin_title': 'انتهت',
        'event_status': 'ended',
        'forced_status': 'ended',
        'home_team': {'title': 'A'},
        'away_team': {'title': 'B'},
      });
      expect(m.status, MatchStatus.finished);
      expect(m.isFinished, isTrue);
      expect(m.isLive, isFalse);
    });

    test('MatchEventModel uses EventMapper for penalty and card types', () {
      // Type 5: penalty scored
      final penaltyEvent = MatchEventModel.fromMap({
        'event_id': 1,
        'type': 5,
        'minute': 35,
        'status_name': 'هدف (ركلة جزاء)',
      });
      expect(penaltyEvent.eventType, MatchEventType.penaltyScored);

      // Type 6: penalty missed
      final missedEvent = MatchEventModel.fromMap({
        'event_id': 2,
        'type': 6,
        'minute': 42,
        'status_name': 'ركلة جزاء ضائعة',
      });
      expect(missedEvent.eventType, MatchEventType.penaltyMissed);

      // Type 3: red card
      final redCardEvent = MatchEventModel.fromMap({
        'event_id': 3,
        'type': 3,
        'minute': 75,
        'status_name': 'بطاقة حمراء',
      });
      expect(redCardEvent.eventType, MatchEventType.redCard);
    });
  });
}

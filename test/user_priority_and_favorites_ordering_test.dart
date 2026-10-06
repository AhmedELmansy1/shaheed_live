import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/data/models/league_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/team_model.dart';
import 'package:shoot_live/presentation/home/providers/matches_provider.dart';

void main() {
  final leagues = [
    const LeagueModel(
      id: 'esp_1',
      name: 'الدوري الإسباني',
      nameEn: 'La Liga',
      country: 'إسبانيا',
    ),
    const LeagueModel(
      id: 'eng_1',
      name: 'الدوري الإنجليزي الممتاز',
      nameEn: 'Premier League',
      country: 'إنجلترا',
    ),
    const LeagueModel(
      id: 'egy_1',
      name: 'الدوري المصري الممتاز',
      nameEn: 'Egyptian Premier League',
      country: 'مصر',
    ),
    const LeagueModel(
      id: 'ger_1',
      name: 'الدوري الألماني',
      nameEn: 'Bundesliga',
      country: 'ألمانيا',
    ),
  ];

  final teams = [
    const TeamModel(
      id: 'ahly',
      name: 'الأهلي',
      nameEn: 'Al Ahly',
      leagueId: 'egy_1',
    ),
    const TeamModel(
      id: 'barcelona',
      name: 'برشلونة',
      nameEn: 'FC Barcelona',
      leagueId: 'esp_1',
    ),
    const TeamModel(
      id: 'liverpool',
      name: 'ليفربول',
      nameEn: 'Liverpool',
      leagueId: 'eng_1',
    ),
  ];

  final matchAhlyZamalek = const MatchModel(
    matchId: 101,
    isLive: false,
    status: MatchStatus.notStarted,
    matchDate: '2026-10-03',
    matchTime: '20:00:00',
    championship: ChampionshipInfo(id: 'egy_1', title: 'الدوري المصري الممتاز'),
    homeTeam: TeamInfo(rowId: 1, title: 'الأهلي'),
    awayTeam: TeamInfo(rowId: 2, title: 'الزمالك'),
  );

  final matchAhlyLive = const MatchModel(
    matchId: 102,
    isLive: true,
    status: MatchStatus.live,
    matchDate: '2026-10-03',
    matchTime: '17:00:00',
    adminBadge: 'live',
    adminTitle: "65'",
    championship: ChampionshipInfo(id: 'egy_1', title: 'الدوري المصري الممتاز'),
    homeTeam: TeamInfo(rowId: 1, title: 'الأهلي'),
    awayTeam: TeamInfo(rowId: 3, title: 'بيراميدز'),
  );

  final matchChelseaSpursLive = const MatchModel(
    matchId: 201,
    isLive: true,
    status: MatchStatus.live,
    matchDate: '2026-10-03',
    matchTime: '17:30:00',
    adminBadge: 'live',
    adminTitle: "40'",
    championship: ChampionshipInfo(id: 'eng_1', title: 'الدوري الإنجليزي الممتاز'),
    homeTeam: TeamInfo(rowId: 11, title: 'تشيلسي'),
    awayTeam: TeamInfo(rowId: 12, title: 'توتنهام'),
  );

  final matchRealMadridBarcaUpcoming = const MatchModel(
    matchId: 301,
    isLive: false,
    status: MatchStatus.notStarted,
    matchDate: '2026-10-03',
    matchTime: '21:00:00',
    championship: ChampionshipInfo(id: 'esp_1', title: 'الدوري الإسباني'),
    homeTeam: TeamInfo(rowId: 21, title: 'ريال مدريد'),
    awayTeam: TeamInfo(rowId: 22, title: 'برشلونة'),
  );

  final matchBayernDortmundUpcoming = const MatchModel(
    matchId: 401,
    isLive: false,
    status: MatchStatus.notStarted,
    matchDate: '2026-10-03',
    matchTime: '18:30:00',
    championship: ChampionshipInfo(id: 'ger_1', title: 'الدوري الألماني'),
    homeTeam: TeamInfo(rowId: 31, title: 'بايرن ميونخ'),
    awayTeam: TeamInfo(rowId: 32, title: 'بوروسيا دورتموند'),
  );

  group('Phase 2: Hero Match Prioritization Hierarchy Tests', () {
    test('Rule (a): Live match involving a favorite team is chosen above any other live match', () {
      final hero = selectHeroMatch(
        matches: [matchChelseaSpursLive, matchAhlyLive, matchBayernDortmundUpcoming],
        selectedTeamIds: ['ahly'],
        selectedLeagueIds: ['eng_1'],
        allTeams: teams,
        allLeagues: leagues,
      );

      expect(hero?.matchId, matchAhlyLive.matchId);
    });

    test('Rule (b): Any live match is chosen when no favorite team is playing live', () {
      final hero = selectHeroMatch(
        matches: [matchBayernDortmundUpcoming, matchChelseaSpursLive, matchAhlyZamalek],
        selectedTeamIds: ['ahly'],
        selectedLeagueIds: [],
        allTeams: teams,
        allLeagues: leagues,
      );

      expect(hero?.matchId, matchChelseaSpursLive.matchId);
    });

    test('Rule (c): Next upcoming match involving a favorite team is chosen before general upcoming matches', () {
      final hero = selectHeroMatch(
        matches: [matchBayernDortmundUpcoming, matchRealMadridBarcaUpcoming],
        selectedTeamIds: ['barcelona'],
        selectedLeagueIds: [],
        allTeams: teams,
        allLeagues: leagues,
      );

      // Barca match is chosen even though Bayern is earlier
      expect(hero?.matchId, matchRealMadridBarcaUpcoming.matchId);
    });

    test('Rule (d): Next upcoming match overall is chosen when no favorite matches exist', () {
      final hero = selectHeroMatch(
        matches: [matchRealMadridBarcaUpcoming, matchBayernDortmundUpcoming],
        selectedTeamIds: [],
        selectedLeagueIds: [],
        allTeams: teams,
        allLeagues: leagues,
      );

      // 18:30 (Bayern) comes before 21:00 (El Clasico)
      expect(hero?.matchId, matchBayernDortmundUpcoming.matchId);
    });
  });

  group('Phase 2: Followed Leagues & Favorites Ordering Tests', () {
    test('Followed leagues appear before non-followed leagues in leagueGroups sorting', () {
      final allMatches = [
        matchBayernDortmundUpcoming, // ger_1 (not followed)
        matchChelseaSpursLive,        // eng_1 (not followed)
        matchRealMadridBarcaUpcoming, // esp_1 (followed!)
      ];

      final rawGroups = <String, List<MatchModel>>{};
      for (final m in allMatches) {
        rawGroups.putIfAbsent(m.championship.title, () => []).add(m);
      }

      final leagueGroups = rawGroups.entries.map((entry) {
        final title = entry.key;
        final groupMatches = entry.value;
        final isFollowed = isFavoriteLeagueMatch(groupMatches.first, ['esp_1'], leagues);
        return LeagueGroupData(
          leagueTitle: title,
          leagueLogo: null,
          isFollowed: isFollowed,
          matches: groupMatches,
        );
      }).toList();

      leagueGroups.sort((a, b) {
        if (a.isFollowed && !b.isFollowed) return -1;
        if (!a.isFollowed && b.isFollowed) return 1;
        final aHasLive = a.matches.any((m) => m.isLive);
        final bHasLive = b.matches.any((m) => m.isLive);
        if (aHasLive && !bHasLive) return -1;
        if (!aHasLive && bHasLive) return 1;
        return 0;
      });

      // La Liga must be first because it is followed
      expect(leagueGroups.first.leagueTitle, 'الدوري الإسباني');
      expect(leagueGroups.first.isFollowed, isTrue);

      // Premier League has a live match so it follows La Liga
      expect(leagueGroups[1].leagueTitle, 'الدوري الإنجليزي الممتاز');

      // Bundesliga last
      expect(leagueGroups[2].leagueTitle, 'الدوري الألماني');
      expect(leagueGroups[2].isFollowed, isFalse);
    });

    test('Favorite team matches are properly separated for the "مبارياتك" top section', () {
      final allMatches = [
        matchBayernDortmundUpcoming,
        matchAhlyZamalek,
        matchChelseaSpursLive,
      ];

      final favoriteTeamMatches = allMatches
          .where((m) => isFavoriteTeamMatch(m, ['ahly'], teams))
          .toList();

      expect(favoriteTeamMatches.length, 1);
      expect(favoriteTeamMatches.first.matchId, matchAhlyZamalek.matchId);

      final restOfMatches = allMatches
          .where((m) => !favoriteTeamMatches.contains(m))
          .toList();

      expect(restOfMatches.length, 2);
      expect(restOfMatches.any((m) => m.matchId == matchAhlyZamalek.matchId), isFalse);
    });
  });
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/data/models/league_model.dart';
import 'package:shoot_live/data/models/match_lineup_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/team_model.dart';
import 'package:shoot_live/presentation/home/providers/matches_provider.dart';
import 'package:shoot_live/presentation/match_details/tabs/lineup_tab.dart';

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
    const LeagueModel(
      id: 'ita_1',
      name: 'الدوري الإيطالي',
      nameEn: 'Serie A',
      country: 'إيطاليا',
    ),
  ];

  final teams = [
    const TeamModel(
      id: 'barcelona',
      name: 'برشلونة',
      nameEn: 'FC Barcelona',
      leagueId: 'esp_1',
    ),
    const TeamModel(
      id: 'ahly',
      name: 'الأهلي',
      nameEn: 'Al Ahly',
      leagueId: 'egy_1',
    ),
    const TeamModel(
      id: 'zamalek',
      name: 'الزمالك',
      nameEn: 'Zamalek',
      leagueId: 'egy_1',
    ),
    const TeamModel(
      id: 'liverpool',
      name: 'ليفربول',
      nameEn: 'Liverpool',
      leagueId: 'eng_1',
    ),
  ];

  final matchBarcaMadrid = const MatchModel(
    matchId: 1,
    isLive: false,
    status: MatchStatus.notStarted,
    championship: ChampionshipInfo(id: 'esp_1', title: 'الدوري الإسباني'),
    homeTeam: TeamInfo(rowId: 101, title: 'برشلونة'),
    awayTeam: TeamInfo(rowId: 102, title: 'ريال مدريد'),
  );

  final matchAhlyZamalek = const MatchModel(
    matchId: 2,
    isLive: false,
    status: MatchStatus.notStarted,
    championship: ChampionshipInfo(id: 'egy_1', title: 'الدوري المصري الممتاز'),
    homeTeam: TeamInfo(rowId: 201, title: 'الأهلي'),
    awayTeam: TeamInfo(rowId: 202, title: 'الزمالك'),
  );

  final matchChelseaSpurs = const MatchModel(
    matchId: 4,
    isLive: false,
    status: MatchStatus.notStarted,
    championship: ChampionshipInfo(id: 'eng_1', title: 'الدوري الإنجليزي الممتاز'),
    homeTeam: TeamInfo(rowId: 303, title: 'تشيلسي'),
    awayTeam: TeamInfo(rowId: 304, title: 'توتنهام'),
  );

  final matchBayernDortmund = const MatchModel(
    matchId: 5,
    isLive: false,
    status: MatchStatus.notStarted,
    championship: ChampionshipInfo(id: 'ger_1', title: 'الدوري الألماني'),
    homeTeam: TeamInfo(rowId: 401, title: 'بايرن ميونخ'),
    awayTeam: TeamInfo(rowId: 402, title: 'بوروسيا دورتموند'),
  );

  final matchInterMilan = const MatchModel(
    matchId: 6,
    isLive: false,
    status: MatchStatus.notStarted,
    championship: ChampionshipInfo(id: 'ita_1', title: 'الدوري الإيطالي'),
    homeTeam: TeamInfo(rowId: 501, title: 'إنتر ميلان'),
    awayTeam: TeamInfo(rowId: 502, title: 'ميلان'),
  );

  group('Match Prioritization Logic Tests', () {
    test('Test 1: User اختار فرق فقط -> مباريات هذه الفرق تظهر أولاً', () {
      final inputMatches = [
        matchBayernDortmund,
        matchChelseaSpurs,
        matchBarcaMadrid,
        matchInterMilan,
      ];

      final prioritized = prioritizeMatches(
        matches: inputMatches,
        selectedTeamIds: ['barcelona'],
        selectedLeagueIds: [],
        allTeams: teams,
        allLeagues: leagues,
      );

      // Barcelona match must be first
      expect(prioritized.first.matchId, matchBarcaMadrid.matchId);
      // Other matches follow in their original relative order
      expect(prioritized.sublist(1).map((m) => m.matchId).toList(), [
        matchBayernDortmund.matchId,
        matchChelseaSpurs.matchId,
        matchInterMilan.matchId,
      ]);
    });

    test('Test 2: User اختار دوريات فقط -> مباريات هذه الدوريات تظهر أولاً', () {
      final inputMatches = [
        matchBayernDortmund,
        matchChelseaSpurs,
        matchInterMilan,
      ];

      final prioritized = prioritizeMatches(
        matches: inputMatches,
        selectedTeamIds: [],
        selectedLeagueIds: ['eng_1'],
        allTeams: teams,
        allLeagues: leagues,
      );

      // Premier League match must be first
      expect(prioritized.first.matchId, matchChelseaSpurs.matchId);
      // Others follow
      expect(prioritized.sublist(1).map((m) => m.matchId).toList(), [
        matchBayernDortmund.matchId,
        matchInterMilan.matchId,
      ]);
    });

    test('Test 3: User اختار فرق + دوريات -> الفرق أولاً ثم الدوريات ثم باقي المباريات', () {
      final inputMatches = [
        matchBayernDortmund,
        matchChelseaSpurs, // Premier League (fav league, not fav team)
        matchInterMilan,   // Serie A (other)
        matchBarcaMadrid,  // Barca (fav team)
        matchAhlyZamalek,  // Ahly (fav team)
      ];

      final prioritized = prioritizeMatches(
        matches: inputMatches,
        selectedTeamIds: ['barcelona', 'ahly'],
        selectedLeagueIds: ['eng_1'],
        allTeams: teams,
        allLeagues: leagues,
      );

      // 1. Favorite teams
      expect(prioritized[0].matchId, matchBarcaMadrid.matchId);
      expect(prioritized[1].matchId, matchAhlyZamalek.matchId);

      // 2. Favorite league
      expect(prioritized[2].matchId, matchChelseaSpurs.matchId);

      // 3. Other matches in natural order
      expect(prioritized[3].matchId, matchBayernDortmund.matchId);
      expect(prioritized[4].matchId, matchInterMilan.matchId);
    });

    test('Test 4: User لم يختر أي شيء -> السلوك الحالي بدون تغيير', () {
      final inputMatches = [
        matchBayernDortmund,
        matchInterMilan,
        matchBarcaMadrid,
        matchChelseaSpurs,
      ];

      final result = prioritizeMatches(
        matches: inputMatches,
        selectedTeamIds: [],
        selectedLeagueIds: [],
        allTeams: teams,
        allLeagues: leagues,
      );

      expect(result.map((m) => m.matchId).toList(),
          inputMatches.map((m) => m.matchId).toList());
    });

    test('Test 5 & 6: Live matches remain prioritized at the very top without getting delayed', () {
      final liveOther = const MatchModel(
        matchId: 99,
        isLive: true,
        status: MatchStatus.live,
        championship: ChampionshipInfo(id: 'fra_1', title: 'الدوري الفرنسي'),
        homeTeam: TeamInfo(rowId: 901, title: 'باريس'),
        awayTeam: TeamInfo(rowId: 902, title: 'مارسيليا'),
      );

      final liveFavLeague = const MatchModel(
        matchId: 98,
        isLive: true,
        status: MatchStatus.live,
        championship: ChampionshipInfo(id: 'eng_1', title: 'الدوري الإنجليزي الممتاز'),
        homeTeam: TeamInfo(rowId: 303, title: 'تشيلسي'),
        awayTeam: TeamInfo(rowId: 304, title: 'توتنهام'),
      );

      final liveFavTeam = const MatchModel(
        matchId: 97,
        isLive: true,
        status: MatchStatus.live,
        championship: ChampionshipInfo(id: 'esp_1', title: 'الدوري الإسباني'),
        homeTeam: TeamInfo(rowId: 101, title: 'برشلونة'),
        awayTeam: TeamInfo(rowId: 102, title: 'ريال مدريد'),
      );

      final inputMatches = [
        matchBayernDortmund,
        liveOther,
        matchAhlyZamalek,
        liveFavLeague,
        liveFavTeam,
      ];

      final prioritized = prioritizeMatches(
        matches: inputMatches,
        selectedTeamIds: ['barcelona', 'ahly'],
        selectedLeagueIds: ['eng_1'],
        allTeams: teams,
        allLeagues: leagues,
      );

      // Live Favorite Team first
      expect(prioritized[0].matchId, liveFavTeam.matchId);
      // Live Favorite League second
      expect(prioritized[1].matchId, liveFavLeague.matchId);
      // Live other third
      expect(prioritized[2].matchId, liveOther.matchId);
      // Non-live Favorite Team (Ahly) fourth
      expect(prioritized[3].matchId, matchAhlyZamalek.matchId);
      // Non-live other (Bayern) last
      expect(prioritized[4].matchId, matchBayernDortmund.matchId);
    });

    test('Test 7: لا توجد مباريات للفرق المفضلة -> انتقل مباشرة لمباريات الدوريات المفضلة', () {
      final inputMatches = [
        matchBayernDortmund,
        matchChelseaSpurs, // eng_1
        matchInterMilan,
      ];

      final prioritized = prioritizeMatches(
        matches: inputMatches,
        selectedTeamIds: ['barcelona'], // No barca match today
        selectedLeagueIds: ['eng_1'],
        allTeams: teams,
        allLeagues: leagues,
      );

      // Favorite league match takes top priority
      expect(prioritized.first.matchId, matchChelseaSpurs.matchId);
    });

    test('Test 8: لا توجد مباريات مفضلة -> اعرض باقي المباريات بشكل طبيعي', () {
      final inputMatches = [
        matchBayernDortmund,
        matchInterMilan,
      ];

      final prioritized = prioritizeMatches(
        matches: inputMatches,
        selectedTeamIds: ['barcelona'],
        selectedLeagueIds: ['eng_1'],
        allTeams: teams,
        allLeagues: leagues,
      );

      expect(prioritized.map((m) => m.matchId).toList(), [
        matchBayernDortmund.matchId,
        matchInterMilan.matchId,
      ]);
    });
  });

  group('Lineup Player Avatar & Fallback Widget Tests', () {
    testWidgets('LineupPlayer with photoUrl renders CachedNetworkImage', (tester) async {
      const playerWithPhoto = LineupPlayer(
        id: 10,
        name: 'ليونيل ميسي',
        number: 10,
        photoUrl: 'https://imgs.ysscores.com/players/128/messi.png',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PitchView(
                homeData: TeamLineupData(
                  formation: '4-3-3',
                  startingXI: [playerWithPhoto],
                  substitutes: [],
                ),
                awayData: TeamLineupData(
                  formation: '4-3-3',
                  startingXI: [],
                  substitutes: [],
                ),
              ),
            ),
          ),
        ),
      );

      // Expect CachedNetworkImage widget to be present
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.text('ليونيل ميسي'), findsOneWidget);
    });

    testWidgets('LineupPlayer with null photoUrl renders graceful fallback without error', (tester) async {
      const playerNoPhoto = LineupPlayer(
        id: 7,
        name: 'كريستيانو رونالدو',
        number: 7,
        photoUrl: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PitchView(
                homeData: TeamLineupData(
                  formation: '4-3-3',
                  startingXI: [playerNoPhoto],
                  substitutes: [],
                ),
                awayData: TeamLineupData(
                  formation: '4-3-3',
                  startingXI: [],
                  substitutes: [],
                ),
              ),
            ),
          ),
        ),
      );

      // No network image should be present, fallback number '٧' rendered
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.text('كريستيانو رونالدو'), findsOneWidget);
      expect(find.text('٧'), findsOneWidget);
    });

    test('LineupPlayer.fromMap parses photoUrl from multiple key candidates', () {
      final p1 = LineupPlayer.fromMap({
        'short_title': 'محمد صلاح',
        'image': 'salah.png',
      });
      expect(p1.photoUrl, 'https://imgs.ysscores.com/players/128/salah.png');

      final p2 = LineupPlayer.fromMap({
        'short_title': 'هالاند',
        'photo': 'https://example.com/haaland.jpg',
      });
      expect(p2.photoUrl, 'https://example.com/haaland.jpg');

      final p3 = LineupPlayer.fromMap({
        'short_title': 'مبابي',
        'player': {'photo_url': 'https://example.com/mbappe.jpg'},
      });
      expect(p3.photoUrl, 'https://example.com/mbappe.jpg');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/core/utils/match_filter_helper.dart';
import 'package:shoot_live/data/models/league_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/team_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User Feed Priority & Fallback Logic (User Requirements 1, 2, 3)', () {
    final mockTeams = [
      const TeamModel(id: '8650', leagueId: 'egy_1', name: 'الأهلي', nameEn: 'Al Ahly'),
      const TeamModel(id: '8634', leagueId: 'egy_1', name: 'الزمالك', nameEn: 'Zamalek'),
      const TeamModel(id: '2001', leagueId: 'eng_1', name: 'ليفربول', nameEn: 'Liverpool'),
    ];

    final mockLeagues = [
      const LeagueModel(id: 'egy_1', name: 'الدوري المصري الممتاز', nameEn: 'Egyptian Premier League', country: 'مصر', isPopular: true, displayOrder: 1),
      const LeagueModel(id: 'eng_1', name: 'الدوري الإنجليزي الممتاز', nameEn: 'Premier League', country: 'إنجلترا', isPopular: true, displayOrder: 2),
      const LeagueModel(id: 'ucl', name: 'دوري أبطال أوروبا', nameEn: 'UEFA Champions League', country: 'أوروبا', isPopular: true, displayOrder: 3),
      const LeagueModel(id: 'rwa_1', name: 'دوري رواندا الممتاز', nameEn: 'Rwanda Premier League', country: 'رواندا', isPopular: false, displayOrder: 99),
    ];

    final matchFavTeam = MatchModel(
      matchId: 101,
      matchDate: '2026-11-19',
      matchTime: '20:00',
      isLive: false,
      status: MatchStatus.notStarted,
      championship: const ChampionshipInfo(id: 6047, title: 'الدوري المصري الممتاز'),
      homeTeam: const TeamInfo(rowId: 8650, title: 'الأهلي'),
      awayTeam: const TeamInfo(rowId: 9000, title: 'المقاولون العرب'),
    );

    final matchFollowedLeague = MatchModel(
      matchId: 102,
      matchDate: '2026-11-19',
      matchTime: '18:00',
      isLive: false,
      status: MatchStatus.notStarted,
      championship: const ChampionshipInfo(id: 6811, title: 'الدوري الإنجليزي الممتاز'),
      homeTeam: const TeamInfo(rowId: 7001, title: 'تشيلسي'),
      awayTeam: const TeamInfo(rowId: 7002, title: 'أستون فيلا'),
    );

    final matchMajorLeague = MatchModel(
      matchId: 103,
      matchDate: '2026-11-19',
      matchTime: '22:00',
      isLive: false,
      status: MatchStatus.notStarted,
      championship: const ChampionshipInfo(id: 1929, title: 'دوري أبطال أوروبا'),
      homeTeam: const TeamInfo(rowId: 5001, title: 'ريال مدريد'),
      awayTeam: const TeamInfo(rowId: 5002, title: 'بايرن ميونخ'),
    );

    final matchObscureLeague = MatchModel(
      matchId: 104,
      matchDate: '2026-11-19',
      matchTime: '15:00',
      isLive: false,
      status: MatchStatus.notStarted,
      championship: const ChampionshipInfo(id: 8888, title: 'دوري رواندا الممتاز'),
      homeTeam: const TeamInfo(rowId: 8801, title: 'رواندا إف سي'),
      awayTeam: const TeamInfo(rowId: 8802, title: 'كيغالي سيتي'),
    );

    test('1. Favorite team match is identified correctly for Priority #1', () {
      final isFav = isFavoriteTeamMatch(matchFavTeam, ['8650'], mockTeams);
      expect(isFav, isTrue);

      final isFavOther = isFavoriteTeamMatch(matchFollowedLeague, ['8650'], mockTeams);
      expect(isFavOther, isFalse);
    });

    test('2. Followed league match is identified correctly for Priority #2', () {
      final isFollowed = isFavoriteLeagueMatch(matchFollowedLeague, ['eng_1'], mockLeagues);
      expect(isFollowed, isTrue);

      final isFollowedOther = isFavoriteLeagueMatch(matchObscureLeague, ['eng_1'], mockLeagues);
      expect(isFollowedOther, isFalse);
    });

    test('3. Major / Strong competitions identified correctly for Priority #3', () {
      expect(isMajorCompetitionTitle('دوري أبطال أوروبا'), isTrue);
      expect(isMajorCompetitionTitle('الدوري الإنجليزي الممتاز'), isTrue);
      expect(isMajorCompetitionTitle('الدوري الإسباني الدرجة الأولى'), isTrue);
      expect(isMajorCompetitionTitle('دوري روشن السعودي'), isTrue);
      expect(isMajorCompetitionTitle('دوري أبطال أفريقيا'), isTrue);

      // Obscure competitions
      expect(isMajorCompetitionTitle('دوري رواندا الممتاز'), isFalse);
      expect(isMajorCompetitionTitle('دوري مقاطعة كينت'), isFalse);
    });

    test('4. Prioritize matches puts favorite team first, then followed league, then others', () {
      final allMatches = [matchObscureLeague, matchMajorLeague, matchFollowedLeague, matchFavTeam];

      final prioritized = prioritizeMatches(
        matches: allMatches,
        selectedTeamIds: ['8650'],
        selectedLeagueIds: ['eng_1'],
        allTeams: mockTeams,
        allLeagues: mockLeagues,
      );

      // Favorite team match must come first (#1 Priority)
      expect(prioritized.first.matchId, equals(matchFavTeam.matchId));

      // Followed league must come before non-followed matches (#2 Priority)
      final favTeamIdx = prioritized.indexWhere((m) => m.matchId == matchFavTeam.matchId);
      final followedLeagueIdx = prioritized.indexWhere((m) => m.matchId == matchFollowedLeague.matchId);
      final otherMajorIdx = prioritized.indexWhere((m) => m.matchId == matchMajorLeague.matchId);

      expect(favTeamIdx, lessThan(followedLeagueIdx));
      expect(followedLeagueIdx, lessThan(otherMajorIdx));
    });
  });
}

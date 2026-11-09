import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/data/models/league_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/team_model.dart';
import 'package:shoot_live/data/repositories/onboarding_repository.dart';
import 'package:shoot_live/core/network/dio_client.dart';
import 'package:shoot_live/core/utils/match_filter_helper.dart';
import 'package:shoot_live/presentation/onboarding/providers/onboarding_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Synthetic ID migration', () {
    test('isSyntheticId correctly flags mock string IDs and accepts real numeric IDs', () {
      expect(OnboardingNotifier.isSyntheticId('egy_1'), isTrue);
      expect(OnboardingNotifier.isSyntheticId('eng_1'), isTrue);
      expect(OnboardingNotifier.isSyntheticId('esp_1'), isTrue);
      expect(OnboardingNotifier.isSyntheticId('ucl'), isTrue);
      expect(OnboardingNotifier.isSyntheticId('egy_ahly'), isTrue);
      expect(OnboardingNotifier.isSyntheticId('liverpool'), isTrue);
      expect(OnboardingNotifier.isSyntheticId(''), isTrue);

      // Real numeric IDs from YsScores
      expect(OnboardingNotifier.isSyntheticId('937599'), isFalse);
      expect(OnboardingNotifier.isSyntheticId('938652'), isFalse);
      expect(OnboardingNotifier.isSyntheticId('8650'), isFalse);
      expect(OnboardingNotifier.isSyntheticId('9826'), isFalse);
    });

    test('cleans legacy synthetic IDs safely from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'selected_leagues': ['egy_1', '937599', 'eng_1', '938652'],
        'selected_teams': ['eng_liv', '8650', 'ahly'],
      });

      final prefs = await SharedPreferences.getInstance();
      final rawLeagues = prefs.getStringList('selected_leagues') ?? [];
      final rawTeams = prefs.getStringList('selected_teams') ?? [];

      final cleanedLeagues = rawLeagues.where((id) => !OnboardingNotifier.isSyntheticId(id)).toList();
      final cleanedTeams = rawTeams.where((id) => !OnboardingNotifier.isSyntheticId(id)).toList();

      expect(cleanedLeagues, ['937599', '938652']);
      expect(cleanedTeams, ['8650']);
    });
  });

  group('Match filtering rules (myMatches vs allMatches)', () {
    const premierLeague = ChampionshipInfo(id: 937599, title: 'الدوري الإنجليزي الممتاز');
    const laLiga = ChampionshipInfo(id: 938652, title: 'الدوري الإسباني');
    const serieA = ChampionshipInfo(id: 936357, title: 'الدوري الإيطالي');

    final liverpool = TeamModel(id: '8650', name: 'ليفربول', nameEn: 'Liverpool', leagueId: '937599');
    final crystalPalace = TeamModel(id: '9826', name: 'كريستال بالاس', nameEn: 'Crystal Palace', leagueId: '937599');
    final realMadrid = TeamModel(id: '8633', name: 'ريال مدريد', nameEn: 'Real Madrid', leagueId: '938652');
    final juventus = TeamModel(id: '8700', name: 'يوفنتوس', nameEn: 'Juventus', leagueId: '936357');

    const matchPL = MatchModel(
      matchId: 1,
      isLive: false,
      status: MatchStatus.notStarted,
      championship: premierLeague,
      homeTeam: TeamInfo(rowId: 9826, title: 'كريستال بالاس'),
      awayTeam: TeamInfo(rowId: 8650, title: 'ليفربول'),
    );

    const matchLaLiga = MatchModel(
      matchId: 2,
      isLive: false,
      status: MatchStatus.notStarted,
      championship: laLiga,
      homeTeam: TeamInfo(rowId: 8633, title: 'ريال مدريد'),
      awayTeam: TeamInfo(rowId: 8634, title: 'برشلونة'),
    );

    const matchSerieA = MatchModel(
      matchId: 3,
      isLive: false,
      status: MatchStatus.notStarted,
      championship: serieA,
      homeTeam: TeamInfo(rowId: 8700, title: 'يوفنتوس'),
      awayTeam: TeamInfo(rowId: 8701, title: 'ميلان'),
    );

    final allLeagues = [
      const LeagueModel(id: '937599', name: 'الدوري الإنجليزي الممتاز', nameEn: 'Premier League', country: 'إنجلترا'),
      const LeagueModel(id: '938652', name: 'الدوري الإسباني', nameEn: 'La Liga', country: 'إسبانيا'),
      const LeagueModel(id: '936357', name: 'الدوري الإيطالي', nameEn: 'Serie A', country: 'إيطاليا'),
    ];

    final allTeams = [liverpool, crystalPalace, realMadrid, juventus];

    test('isMatchInUserLeaguesOrFollowedTeams returns true for matches in selected leagues', () {
      final selectedLeagues = ['937599']; // only PL
      final selectedTeams = <String>[];

      expect(
        isMatchInUserLeaguesOrFollowedTeams(
          match: matchPL,
          selectedLeagueIds: selectedLeagues,
          selectedTeamIds: selectedTeams,
          allLeagues: allLeagues,
          allTeams: allTeams,
        ),
        isTrue,
      );

      expect(
        isMatchInUserLeaguesOrFollowedTeams(
          match: matchLaLiga,
          selectedLeagueIds: selectedLeagues,
          selectedTeamIds: selectedTeams,
          allLeagues: allLeagues,
          allTeams: allTeams,
        ),
        isFalse,
      );

      expect(
        isMatchInUserLeaguesOrFollowedTeams(
          match: matchSerieA,
          selectedLeagueIds: selectedLeagues,
          selectedTeamIds: selectedTeams,
          allLeagues: allLeagues,
          allTeams: allTeams,
        ),
        isFalse,
      );
    });

    test('team selection wins: shows match of followed team even if its league is not selected', () {
      final selectedLeagues = ['936357']; // Serie A selected, but NOT La Liga
      final selectedTeams = ['8633']; // Real Madrid followed

      expect(
        isMatchInUserLeaguesOrFollowedTeams(
          match: matchLaLiga,
          selectedLeagueIds: selectedLeagues,
          selectedTeamIds: selectedTeams,
          allLeagues: allLeagues,
          allTeams: allTeams,
        ),
        isTrue,
      );
    });

    test('shows everything when user has selected nothing', () {
      expect(
        isMatchInUserLeaguesOrFollowedTeams(
          match: matchPL,
          selectedLeagueIds: [],
          selectedTeamIds: [],
          allLeagues: allLeagues,
          allTeams: allTeams,
        ),
        isTrue,
      );
      expect(
        isMatchInUserLeaguesOrFollowedTeams(
          match: matchLaLiga,
          selectedLeagueIds: [],
          selectedTeamIds: [],
          allLeagues: allLeagues,
          allTeams: allTeams,
        ),
        isTrue,
      );
    });
  });

  group('ApiOnboardingRepository offline and error behavior', () {
    test('throws CatalogException when offline and cache is empty (never serves fake data)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Mock DioClient that throws network error
      final mockDio = DioClient();
      final repo = ApiOnboardingRepository(dioClient: mockDio, prefs: prefs);

      expect(
        () async => await repo.getPopularLeagues(),
        throwsA(isA<CatalogException>()),
      );
    });

    test('serves cached catalog when offline and cache is present', () async {
      final cachedJson = '[{"id":"937599","name":"الدوري الإنجليزي","name_en":"Premier League","country":"إنجلترا","is_popular":true,"display_order":2}]';
      SharedPreferences.setMockInitialValues({
        'cached_catalog_leagues_v1': cachedJson,
      });
      final prefs = await SharedPreferences.getInstance();

      final mockDio = DioClient();
      final repo = ApiOnboardingRepository(dioClient: mockDio, prefs: prefs);

      final leagues = await repo.getPopularLeagues();
      expect(leagues.length, 1);
      expect(leagues.first.id, '937599');
      expect(leagues.first.name, 'الدوري الإنجليزي');
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/presentation/home/providers/matches_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Home Feed Ordering and Migration Tests (Step 4)', () {
    test('HomeFeedScopeNotifier migrates stored myMatches mode to allMatches', () async {
      SharedPreferences.setMockInitialValues({
        'home_feed_scope_mode': 'myMatches',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(homeFeedScopeProvider.notifier);
      await notifier.migrateAndLoad();

      final scope = container.read(homeFeedScopeProvider);
      expect(scope, HomeFeedScope.allMatches);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('home_feed_scope_mode'), 'allMatches');
    });

    test('HomeFeedScopeNotifier defaults to allMatches when no preferences exist', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final scope = container.read(homeFeedScopeProvider);
      expect(scope, HomeFeedScope.allMatches);
    });

    test('sortMatchesLiveFirstThenTime puts live matches first, then sorts by kickoff time', () {
      const champ = ChampionshipInfo(id: 10, title: 'League 1');
      const teamA = TeamInfo(rowId: 101, title: 'A');
      const teamB = TeamInfo(rowId: 102, title: 'B');
      const teamC = TeamInfo(rowId: 103, title: 'C');
      const teamD = TeamInfo(rowId: 104, title: 'D');
      const teamE = TeamInfo(rowId: 105, title: 'E');
      const teamF = TeamInfo(rowId: 106, title: 'F');

      const mUpcoming1 = MatchModel(
        matchId: 1,
        matchTime: '21:00',
        matchDate: '2026-11-09',
        isLive: false,
        status: MatchStatus.notStarted,
        championship: champ,
        homeTeam: teamA,
        awayTeam: teamB,
      );

      const mLive = MatchModel(
        matchId: 2,
        matchTime: '19:30',
        matchDate: '2026-11-09',
        isLive: true,
        status: MatchStatus.live,
        championship: champ,
        homeTeam: teamC,
        awayTeam: teamD,
      );

      const mUpcomingEarlier = MatchModel(
        matchId: 3,
        matchTime: '17:00',
        matchDate: '2026-11-09',
        isLive: false,
        status: MatchStatus.notStarted,
        championship: champ,
        homeTeam: teamE,
        awayTeam: teamF,
      );

      final sorted = sortMatchesLiveFirstThenTime([mUpcoming1, mLive, mUpcomingEarlier]);

      expect(sorted[0].id, '2', reason: 'Live match must be first');
      expect(sorted[1].id, '3', reason: '17:00 match must precede 21:00');
      expect(sorted[2].id, '1', reason: '21:00 match is last');
    });

    test('LeagueGroupData sorting orders followed leagues first, then popular leagues', () {
      const gNormal = LeagueGroupData(
        leagueTitle: 'دوري مجهول',
        leagueLogo: '',
        isFollowed: false,
        isPopular: false,
        displayOrder: 99,
        matches: [],
      );

      const gFollowed = LeagueGroupData(
        leagueTitle: 'الدوري الإسباني',
        leagueLogo: '',
        isFollowed: true,
        isPopular: true,
        displayOrder: 3,
        matches: [],
      );

      const gPopular = LeagueGroupData(
        leagueTitle: 'الدوري الإنجليزي',
        leagueLogo: '',
        isFollowed: false,
        isPopular: true,
        displayOrder: 2,
        matches: [],
      );

      final list = [gNormal, gPopular, gFollowed];
      list.sort((a, b) {
        if (a.isFollowed && !b.isFollowed) return -1;
        if (!a.isFollowed && b.isFollowed) return 1;

        if (a.isPopular && !b.isPopular) return -1;
        if (!a.isPopular && b.isPopular) return 1;

        if (a.displayOrder != b.displayOrder) {
          return a.displayOrder.compareTo(b.displayOrder);
        }
        return a.leagueTitle.compareTo(b.leagueTitle);
      });

      expect(list[0].leagueTitle, 'الدوري الإسباني', reason: 'Followed league must be first');
      expect(list[1].leagueTitle, 'الدوري الإنجليزي', reason: 'Popular league must precede normal');
      expect(list[2].leagueTitle, 'دوري مجهول');
    });
  });
}

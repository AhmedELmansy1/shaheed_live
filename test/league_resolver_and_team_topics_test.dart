import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/services/league_resolver_service.dart';
import 'package:shoot_live/core/services/match_reminder_service.dart';
import 'package:shoot_live/core/services/notification_service.dart';
import 'package:shoot_live/core/utils/match_filter_helper.dart';
import 'package:shoot_live/data/models/league_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/repositories/onboarding_repository.dart';
import 'package:shoot_live/core/services/remote_config_service.dart';
import 'package:shoot_live/data/models/ad_config_model.dart';
import 'package:shoot_live/presentation/widgets/banner_ad_widget.dart';

class FakeNotificationService implements NotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockRepo = MockOnboardingRepository();
  final allLeagues = <LeagueModel>[];
  final allTeams = mockRepo.getPopularTeams();

  setUpAll(() async {
    allLeagues.addAll(await mockRepo.getPopularLeagues());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Item 1: TEAM TOPICS & Migration', () {
    test('subscribes to team_{apiRowId} ONLY and ignores slug topics', () async {
      SharedPreferences.setMockInitialValues({
        'selected_teams': ['barcelona', 'liverpool', 'real_madrid'],
      });

      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(matchReminderServiceProvider);
      await service.reapplyTeamTopicSubscriptions();

      final prefs = await SharedPreferences.getInstance();
      final activeTopics = prefs.getStringList('subscribed_team_topics') ?? [];

      // Barcelona is 8634, Liverpool is 8650, Real Madrid is 8633
      expect(activeTopics, contains('team_8634'));
      expect(activeTopics, contains('team_8650'));
      expect(activeTopics, contains('team_8633'));

      // Ensure NO slug topics exist in subscribed list
      expect(activeTopics.contains('team_barcelona'), isFalse);
      expect(activeTopics.contains('team_liverpool'), isFalse);
      expect(activeTopics.contains('team_real_madrid'), isFalse);
      expect(activeTopics.length, equals(3));
    });

    test('one-time migration cleans existing legacy slug topics from storage', () async {
      SharedPreferences.setMockInitialValues({
        'subscribed_team_topics': [
          'team_ahly',
          'team_liverpool',
          'team_8634', // valid numeric
          'team_real_madrid',
        ],
      });

      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(matchReminderServiceProvider);
      await service.migrateOldSlugTopics();

      final prefs = await SharedPreferences.getInstance();
      final cleaned = prefs.getStringList('subscribed_team_topics') ?? [];

      expect(cleaned, equals(['team_8634']));
      expect(prefs.getBool('migrated_old_team_slug_topics_v1'), isTrue);
    });
  });

  group('Item 2: LEAGUE MATCHING & LeagueResolver', () {
    test('normalise names rule: cut after |, unify alefs, unify yaa, strip diacritics/spaces', () {
      expect(
        LeagueResolverService.normalizeLeagueName(
          'دوري أبطال أفريقيا | الأدوار الإقصائية',
        ),
        equals('دوري ابطال افريقيا'),
      );
      expect(
        LeagueResolverService.normalizeLeagueName(
          'دوري أبطال إفريقيا',
        ),
        equals('دوري ابطال افريقيا'),
      );
      expect(
        LeagueResolverService.normalizeLeagueName(
          'كأس الكونفيدرالية | الأدوار الإقصائية',
        ),
        equals('كاس الكونفيدراليه'),
      );
      expect(
        LeagueResolverService.normalizeLeagueName(
          '  الدوري   الفرنسي  ',
        ),
        equals('الدوري الفرنسي'),
      );
    });

    test('resolves and matches all 11 real API championships given in requirements', () {
      final realApiChampionships = [
        {'id': 1985, 'title': 'الدوري الفرنسي', 'expected': 'fra_1'},
        {'id': 2606, 'title': 'الدوري الألماني', 'expected': 'ger_1'},
        {'id': 3734, 'title': 'الدوري الإيطالي', 'expected': 'ita_1'},
        {'id': 6682, 'title': 'الدوري التركي', 'expected': 'tur_1'},
        {'id': 40224, 'title': 'الدوري البرازيلي', 'expected': 'bra_1'},
        {'id': 41135, 'title': 'البطولة الوطنية المغربية', 'expected': 'mar_1'},
        {'id': 44444, 'title': 'كأس الكونفيدرالية | الأدوار الإقصائية', 'expected': 'caf_cc'},
        {'id': 54416, 'title': 'الدوري البرتغالي الممتاز', 'expected': 'por_1'},
        {'id': 57146, 'title': 'الرابطة المحترفة الجزائرية', 'expected': 'alg_1'},
        {'id': 97533, 'title': 'دوري أبطال أفريقيا | الأدوار الإقصائية', 'expected': 'caf_cl'},
        {'id': 99376, 'title': 'دوري نجوم العراق', 'expected': 'irq_1'},
      ];

      for (final item in realApiChampionships) {
        final resolved = LeagueResolverService.resolveToOnboardingLeagueId(
          champId: item['id'],
          champTitle: item['title'] as String,
          allLeagues: allLeagues,
        );
        expect(
          resolved,
          equals(item['expected']),
          reason: 'Failed to resolve API champ "${item['title']}" (ID ${item['id']})',
        );
      }
    });

    test('central filter includes matches from "دوري أبطال أفريقيا | الأدوار الإقصائية" (ID 97533) when caf_cl is selected', () {
      const matchCaf = MatchModel(
        matchId: 9753301,
        isLive: false,
        status: MatchStatus.notStarted,
        matchDate: '2026-10-25',
        matchTime: '20:00:00',
        homeTeam: TeamInfo(rowId: 102769, title: 'الهلال'),
        awayTeam: TeamInfo(rowId: 2137072, title: 'سيداما'),
        championship: ChampionshipInfo(
          id: 97533,
          title: 'دوري أبطال أفريقيا | الأدوار الإقصائية',
        ),
      );

      final included = isMatchInUserLeaguesOrFollowedTeams(
        match: matchCaf,
        selectedLeagueIds: ['caf_cl'],
        selectedTeamIds: [],
        allLeagues: allLeagues,
        allTeams: allTeams,
      );

      expect(included, isTrue, reason: 'Stage suffix or spelling should not exclude match');
    });

    test('rule that followed teams matches always show is preserved even if league is not followed', () {
      const matchUnfollowedLeague = MatchModel(
        matchId: 5441601,
        isLive: false,
        status: MatchStatus.notStarted,
        matchDate: '2026-10-25',
        matchTime: '21:00:00',
        homeTeam: TeamInfo(rowId: 8634, title: 'برشلونة'),
        awayTeam: TeamInfo(rowId: 9999, title: 'فريق غير معروف'),
        championship: ChampionshipInfo(
          id: 54416,
          title: 'الدوري البرتغالي الممتاز',
        ),
      );

      // User did not select 'por_1', but follows Barcelona ('barcelona')
      final included = isMatchInUserLeaguesOrFollowedTeams(
        match: matchUnfollowedLeague,
        selectedLeagueIds: ['egy_1'],
        selectedTeamIds: ['barcelona'],
        allLeagues: allLeagues,
        allTeams: allTeams,
      );

      expect(included, isTrue, reason: 'Followed team must always show regardless of league');
    });
  });

  group('Item 3: BANNER RACE & Lifecycle', () {
    testWidgets('dispose during load does not throw and cleans up safely', (tester) async {
      BannerAdWidget.resetCounters();

      const enabledConfig = AdConfig(
        bannerHome: BannerAdPlacementConfig(
          enabled: true,
          adUnitId: 'test_banner_unit_id',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          currentAdConfigProvider.overrideWithValue(enabledConfig),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: BannerAdWidget(placement: BannerPlacement.home),
            ),
          ),
        ),
      );

      // Trigger initial layout / didChangeDependencies / loadBanner
      await tester.pump();

      // Dispose immediately while load is in-flight
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );

      // Verify no exceptions occurred and counter logged ad request
      expect(
        BannerAdWidget.requestCounters[BannerPlacement.home],
        greaterThanOrEqualTo(1),
      );
    });
  });
}

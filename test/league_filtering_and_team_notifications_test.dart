import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/services/match_reminder_service.dart';
import 'package:shoot_live/core/services/notification_service.dart';
import 'package:shoot_live/data/models/league_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/team_model.dart';
import 'package:shoot_live/data/repositories/onboarding_repository.dart';
import 'package:shoot_live/presentation/home/home_screen.dart';
import 'package:shoot_live/presentation/home/providers/matches_provider.dart';
import 'package:shoot_live/presentation/onboarding/providers/onboarding_provider.dart';

class FakeNotificationService implements NotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      id: 'barcelona',
      name: 'برشلونة',
      nameEn: 'FC Barcelona',
      leagueId: 'esp_1',
    ),
    const TeamModel(
      id: 'real_madrid',
      name: 'ريال مدريد',
      nameEn: 'Real Madrid',
      leagueId: 'esp_1',
    ),
    const TeamModel(
      id: 'ahly',
      name: 'الأهلي',
      nameEn: 'Al Ahly',
      leagueId: 'egy_1',
    ),
    const TeamModel(
      id: 'liverpool',
      name: 'ليفربول',
      nameEn: 'Liverpool',
      leagueId: 'eng_1',
    ),
    const TeamModel(
      id: 'bayern',
      name: 'بايرن ميونخ',
      nameEn: 'Bayern Munich',
      leagueId: 'ger_1',
    ),
  ];

  const matchBarcaMadrid = MatchModel(
    matchId: 101,
    isLive: false,
    status: MatchStatus.notStarted,
    championship: ChampionshipInfo(id: 'esp_1', title: 'الدوري الإسباني'),
    homeTeam: TeamInfo(rowId: 1, title: 'برشلونة'),
    awayTeam: TeamInfo(rowId: 2, title: 'ريال مدريد'),
  );

  const matchLiverpoolCity = MatchModel(
    matchId: 102,
    isLive: false,
    status: MatchStatus.notStarted,
    championship: ChampionshipInfo(id: 'eng_1', title: 'الدوري الإنجليزي الممتاز'),
    homeTeam: TeamInfo(rowId: 3, title: 'ليفربول'),
    awayTeam: TeamInfo(rowId: 4, title: 'مانشستر سيتي'),
  );

  const matchAhlyZamalek = MatchModel(
    matchId: 103,
    isLive: false,
    status: MatchStatus.notStarted,
    championship: ChampionshipInfo(id: 'egy_1', title: 'الدوري المصري الممتاز'),
    homeTeam: TeamInfo(rowId: 5, title: 'الأهلي'),
    awayTeam: TeamInfo(rowId: 6, title: 'الزمالك'),
  );

  const matchBayernDortmund = MatchModel(
    matchId: 104,
    isLive: false,
    status: MatchStatus.notStarted,
    championship: ChampionshipInfo(id: 'ger_1', title: 'الدوري الألماني'),
    homeTeam: TeamInfo(rowId: 7, title: 'بايرن ميونخ'),
    awayTeam: TeamInfo(rowId: 8, title: 'بوروسيا دورتموند'),
  );

  group('Part 1: League-Only Filtering Rules', () {
    test('Rule 1: If user selected no leagues (legacy/all), show everything', () {
      final matches = [
        matchBarcaMadrid,
        matchLiverpoolCity,
        matchAhlyZamalek,
        matchBayernDortmund,
      ];

      final filtered = matches.where((m) {
        return isMatchInUserLeaguesOrFollowedTeams(
          match: m,
          selectedLeagueIds: [], // Empty selection
          selectedTeamIds: [],
          allLeagues: leagues,
          allTeams: teams,
        );
      }).toList();

      expect(filtered.length, equals(4));
    });

    test('Rule 2: Filters matches to ONLY user-selected leagues', () {
      final matches = [
        matchBarcaMadrid,
        matchLiverpoolCity,
        matchAhlyZamalek,
        matchBayernDortmund,
      ];

      // User only follows Premier League (eng_1) and La Liga (esp_1)
      final filtered = matches.where((m) {
        return isMatchInUserLeaguesOrFollowedTeams(
          match: m,
          selectedLeagueIds: ['eng_1', 'esp_1'],
          selectedTeamIds: [],
          allLeagues: leagues,
          allTeams: teams,
        );
      }).toList();

      expect(filtered.length, equals(2));
      expect(filtered.contains(matchBarcaMadrid), isTrue);
      expect(filtered.contains(matchLiverpoolCity), isTrue);
      expect(filtered.contains(matchAhlyZamalek), isFalse);
      expect(filtered.contains(matchBayernDortmund), isFalse);
    });

    test('Rule 3: Team-wins-over-league: followed team match is shown even if its league is NOT selected', () {
      final matches = [
        matchBarcaMadrid,
        matchLiverpoolCity,
        matchAhlyZamalek,
        matchBayernDortmund,
      ];

      // User selected only Spanish league (esp_1), but follows Al Ahly (egy_1)
      final filtered = matches.where((m) {
        return isMatchInUserLeaguesOrFollowedTeams(
          match: m,
          selectedLeagueIds: ['esp_1'],
          selectedTeamIds: ['ahly'],
          allLeagues: leagues,
          allTeams: teams,
        );
      }).toList();

      expect(filtered.length, equals(2));
      expect(filtered.contains(matchBarcaMadrid), isTrue); // In selected league
      expect(filtered.contains(matchAhlyZamalek), isTrue); // Team selection wins!
      expect(filtered.contains(matchLiverpoolCity), isFalse);
      expect(filtered.contains(matchBayernDortmund), isFalse);
    });

    test('Rule 4: Fallback match on normalized Arabic and English league names', () {
      // API returns championship without ID or with different ID format
      const matchWithTitleOnly = MatchModel(
        matchId: 201,
        isLive: false,
        status: MatchStatus.notStarted,
        championship: ChampionshipInfo(id: null, title: 'الدوري الإسباني الدرجة الأولى'),
        homeTeam: TeamInfo(rowId: 10, title: 'فالنسيا'),
        awayTeam: TeamInfo(rowId: 11, title: 'إشبيلية'),
      );

      final isMatchIncluded = isMatchInUserLeaguesOrFollowedTeams(
        match: matchWithTitleOnly,
        selectedLeagueIds: ['esp_1'],
        selectedTeamIds: [],
        allLeagues: leagues,
        allTeams: teams,
      );

      expect(isMatchIncluded, isTrue);
    });
  });

  group('Part 2: Chosen Clubs Priority & Topic Subscriptions', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Subscribing and persisting team topics', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(matchReminderServiceProvider);

      // User follows Barcelona and Liverpool
      await service.syncTeamTopicSubscriptions(['barcelona', 'liverpool']);

      final saved = prefs.getStringList('subscribed_team_topics') ?? [];
      expect(saved.contains('team_barcelona'), isFalse);
      expect(saved.contains('team_8634'), isTrue); // Resolved API row_id
      expect(saved.contains('team_8650'), isTrue); // Liverpool resolved API row_id
      expect(saved.length, equals(2));

      // User unfollows Barcelona, keeps Liverpool
      await service.syncTeamTopicSubscriptions(['liverpool']);
      final updated = prefs.getStringList('subscribed_team_topics') ?? [];
      expect(updated.contains('team_barcelona'), isFalse);
      expect(updated.contains('team_8634'), isFalse);
      expect(updated.contains('team_8650'), isTrue);
      expect(updated.length, equals(1));
    });

    test('Per-match bell visual state is ON by default for followed teams and OFF when muted', () {
      final mutedIds = <int>{};
      final manualIds = <int>{};
      final selectedTeamIds = ['barcelona'];

      // Match involving Barcelona
      final isBarcaFav = isFavoriteTeamMatch(matchBarcaMadrid, selectedTeamIds, teams);
      expect(isBarcaFav, isTrue);

      // Visual state: active if (fav team or manual) and not muted
      bool isBellActive(MatchModel m) {
        if (mutedIds.contains(m.matchId)) return false;
        if (manualIds.contains(m.matchId)) return true;
        return isFavoriteTeamMatch(m, selectedTeamIds, teams);
      }

      // Default: Bell is ON for Barcelona match
      expect(isBellActive(matchBarcaMadrid), isTrue);
      // Default: Bell is OFF for Liverpool match
      expect(isBellActive(matchLiverpoolCity), isFalse);

      // User mutes Barcelona match
      mutedIds.add(matchBarcaMadrid.matchId);
      expect(isBellActive(matchBarcaMadrid), isFalse);

      // User unmutes Barcelona match
      mutedIds.remove(matchBarcaMadrid.matchId);
      expect(isBellActive(matchBarcaMadrid), isTrue);
    });

    testWidgets('Empty state displays "لا توجد مباريات في دورياتك اليوم" and manage button', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selected_leagues', ['938652']);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchesProvider.overrideWith(() => _EmptyMatchesNotifier()),
            onboardingRepositoryProvider.overrideWithValue(FakeOnboardingRepository()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('لا توجد مباريات في دورياتك اليوم'), findsOneWidget);
      expect(find.text('إدارة الدوريات'), findsOneWidget);
    });
  });
}

class _EmptyMatchesNotifier extends MatchesNotifier {
  @override
  Future<List<MatchModel>> build() async => [];
}

class FakeOnboardingRepository implements OnboardingRepository {
  @override
  Future<List<LeagueModel>> getPopularLeagues({bool forceRefresh = false}) async => [];

  @override
  Future<List<TeamModel>> getTeamsForLeagues(List<String> leagueIds, {bool forceRefresh = false}) async => [];

  @override
  Future<List<TeamModel>> getPopularTeams({bool forceRefresh = false}) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

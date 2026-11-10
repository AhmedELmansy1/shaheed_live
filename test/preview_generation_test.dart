@Tags(['preview'])
library;

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/theme/app_theme.dart';
import 'package:shoot_live/data/models/league_model.dart';
import 'package:shoot_live/data/models/match_event_model.dart';
import 'package:shoot_live/data/models/match_lineup_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/match_statistics_model.dart';
import 'package:shoot_live/data/models/standings_model.dart';
import 'package:shoot_live/data/models/team_model.dart';
import 'package:shoot_live/presentation/home/home_screen.dart';
import 'package:shoot_live/presentation/home/providers/matches_provider.dart';
import 'package:shoot_live/presentation/leagues/leagues_screen.dart';
import 'package:shoot_live/presentation/match_details/match_details_screen.dart';
import 'package:shoot_live/presentation/match_details/providers/match_details_providers.dart';
import 'package:shoot_live/presentation/onboarding/providers/onboarding_provider.dart';
import 'package:shoot_live/presentation/onboarding/team_selection_screen.dart';
import 'package:shoot_live/presentation/settings/settings_screen.dart';

Future<void> loadCairoFont() async {
  final fontFile = File('assets/fonts/Cairo.ttf');
  if (fontFile.existsSync()) {
    final bytes = fontFile.readAsBytesSync();
    final fontLoader = FontLoader('Cairo');
    fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await fontLoader.load();
  }
}

class TestActiveTabNotifier extends ActiveTabNotifier {
  final HomeTab _tab;
  TestActiveTabNotifier(this._tab);
  @override
  HomeTab build() => _tab;
}

class TestMatchFilterNotifier extends MatchFilterNotifier {
  final MatchFilterType _filter;
  TestMatchFilterNotifier(this._filter);
  @override
  MatchFilterType build() => _filter;
}

class TestOfflineFallbackNotifier extends OfflineFallbackNotifier {
  final bool _offline;
  TestOfflineFallbackNotifier(this._offline);
  @override
  bool build() => _offline;
}

class TestOnboardingNotifier extends OnboardingNotifier {
  final OnboardingState _initial;
  TestOnboardingNotifier(this._initial);

  @override
  OnboardingState build() => _initial;

  @override
  Future<void> init() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadCairoFont();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': true,
      'theme_mode': 'dark',
    });
    PackageInfo.setMockInitialValues(
      appName: 'مدرّج',
      packageName: 'com.shootlive.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  // Reusable Sample Matches
  final liveMatch = MatchModel(
    matchId: 101,
    matchDate: '2026-11-10',
    matchTime: '20:00',
    isLive: true,
    status: MatchStatus.live,
    championship: const ChampionshipInfo(id: 1, title: 'الدوري الإنجليزي الممتاز'),
    homeTeam: const TeamInfo(rowId: 10, title: 'ليفربول'),
    awayTeam: const TeamInfo(rowId: 20, title: 'مانشستر سيتي'),
    homeScore: '2',
    awayScore: '1',
    adminTitle: '68\'',
  );

  final upcomingMatch = MatchModel(
    matchId: 102,
    matchDate: '2026-11-10',
    matchTime: '22:00',
    isLive: false,
    status: MatchStatus.notStarted,
    championship: const ChampionshipInfo(id: 2, title: 'دوري أبطال أوروبا'),
    homeTeam: const TeamInfo(rowId: 30, title: 'ريال مدريد'),
    awayTeam: const TeamInfo(rowId: 40, title: 'باريس سان جيرمان'),
    homeScore: null,
    awayScore: null,
    adminTitle: 'لم تبدأ',
  );

  final finishedMatch = MatchModel(
    matchId: 103,
    matchDate: '2026-11-10',
    matchTime: '17:30',
    isLive: false,
    status: MatchStatus.finished,
    championship: const ChampionshipInfo(id: 3, title: 'الدوري الإسباني'),
    homeTeam: const TeamInfo(rowId: 50, title: 'برشلونة'),
    awayTeam: const TeamInfo(rowId: 60, title: 'أتلتيكو مدريد'),
    homeScore: '3',
    awayScore: '0',
    adminTitle: 'انتهت',
  );

  final populatedSectionData = HomeSectionData(
    heroMatch: liveMatch,
    favoriteMatches: [liveMatch],
    liveMatches: [liveMatch],
    allFilteredMatches: [liveMatch, upcomingMatch, finishedMatch],
    leagueGroups: [
      LeagueGroupData(
        leagueTitle: 'الدوري الإنجليزي الممتاز',
        leagueLogo: null,
        matches: [liveMatch],
        isFollowed: true,
      ),
      LeagueGroupData(
        leagueTitle: 'دوري أبطال أوروبا',
        leagueLogo: null,
        matches: [upcomingMatch],
        isFollowed: true,
      ),
      LeagueGroupData(
        leagueTitle: 'الدوري الإسباني',
        leagueLogo: null,
        matches: [finishedMatch],
        isFollowed: false,
      ),
    ],
  );

  final sampleStandings = [
    const StandingRowModel(
      rank: 1,
      teamId: 10,
      teamName: 'ليفربول',
      played: 11,
      won: 9,
      drawn: 1,
      lost: 1,
      goalsFor: 27,
      goalsAgainst: 10,
      goalDiff: 17,
      points: 28,
    ),
    const StandingRowModel(
      rank: 2,
      teamId: 20,
      teamName: 'مانشستر سيتي',
      played: 11,
      won: 8,
      drawn: 2,
      lost: 1,
      goalsFor: 25,
      goalsAgainst: 11,
      goalDiff: 14,
      points: 26,
    ),
    const StandingRowModel(
      rank: 3,
      teamId: 30,
      teamName: 'أرسنال',
      played: 11,
      won: 7,
      drawn: 3,
      lost: 1,
      goalsFor: 20,
      goalsAgainst: 9,
      goalDiff: 11,
      points: 24,
    ),
  ];

  final sampleEvents = [
    const MatchEventModel(
      eventId: 1,
      teamId: 10,
      eventType: MatchEventType.goal,
      statusName: 'هدف',
      minute: 24,
      playerName: 'محمد صلاح',
      assistPlayerName: 'ترنت ألكسندر أرنولد',
    ),
    const MatchEventModel(
      eventId: 2,
      teamId: 20,
      eventType: MatchEventType.yellowCard,
      statusName: 'بطاقة صفراء',
      minute: 38,
      playerName: 'رودري',
    ),
    const MatchEventModel(
      eventId: 3,
      teamId: 20,
      eventType: MatchEventType.goal,
      statusName: 'هدف',
      minute: 55,
      playerName: 'إرلينغ هالاند',
      assistPlayerName: 'كيفين دي بروين',
    ),
    const MatchEventModel(
      eventId: 4,
      teamId: 10,
      eventType: MatchEventType.goal,
      statusName: 'هدف',
      minute: 67,
      playerName: 'لويس دياز',
      assistPlayerName: 'دومينيك سوبوسلاي',
    ),
  ];

  final sampleLeagues = [
    const LeagueModel(id: 'eng_1', name: 'الدوري الإنجليزي الممتاز', nameEn: 'Premier League', country: 'إنجلترا'),
    const LeagueModel(id: 'ucl', name: 'دوري أبطال أوروبا', nameEn: 'UEFA Champions League', country: 'أوروبا'),
    const LeagueModel(id: 'esp_1', name: 'الدوري الإسباني', nameEn: 'La Liga', country: 'إسبانيا'),
    const LeagueModel(id: 'ita_1', name: 'الدوري الإيطالي', nameEn: 'Serie A', country: 'إيطاليا'),
  ];

  final sampleTeams = [
    const TeamModel(id: '10', name: 'ليفربول', nameEn: 'Liverpool', leagueId: 'eng_1'),
    const TeamModel(id: '20', name: 'مانشستر سيتي', nameEn: 'Manchester City', leagueId: 'eng_1'),
    const TeamModel(id: '30', name: 'ريال مدريد', nameEn: 'Real Madrid', leagueId: 'esp_1'),
    const TeamModel(id: '50', name: 'برشلونة', nameEn: 'Barcelona', leagueId: 'esp_1'),
  ];

  Future<void> renderAndCapture({
    required WidgetTester tester,
    required Widget child,
    required Brightness brightness,
    required String filename,
    List<dynamic> overrides = const [],
  }) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(360 * 3.0, 800 * 3.0);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides.cast(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: brightness == Brightness.light ? AppTheme.lightTheme : AppTheme.darkTheme,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 360,
                  height: 800,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    // Step forward frames to settle layout without hanging on continuous shimmer tickers
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final file = File('docs/design-preview/$filename');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
    });
  }

  group('Phase 2 — Golden Previews Generator', () {
    // ------------------------------------------------------------------------
    // 1. Home Screen Variants
    // ------------------------------------------------------------------------
    testWidgets('Home Data (Dark)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: const HomeScreen(),
        brightness: Brightness.dark,
        filename: 'home_data_dark.png',
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => AsyncValue.data(populatedSectionData)),
          activeTabProvider.overrideWith(() => TestActiveTabNotifier(HomeTab.today)),
          matchFilterProvider.overrideWith(() => TestMatchFilterNotifier(MatchFilterType.all)),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(false)),
        ],
      );
    });

    testWidgets('Home Data (Light)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: const HomeScreen(),
        brightness: Brightness.light,
        filename: 'home_data_light.png',
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => AsyncValue.data(populatedSectionData)),
          activeTabProvider.overrideWith(() => TestActiveTabNotifier(HomeTab.today)),
          matchFilterProvider.overrideWith(() => TestMatchFilterNotifier(MatchFilterType.all)),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(false)),
        ],
      );
    });

    testWidgets('Home Live Filter (Dark)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: const HomeScreen(),
        brightness: Brightness.dark,
        filename: 'home_live_dark.png',
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => AsyncValue.data(populatedSectionData)),
          activeTabProvider.overrideWith(() => TestActiveTabNotifier(HomeTab.today)),
          matchFilterProvider.overrideWith(() => TestMatchFilterNotifier(MatchFilterType.live)),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(false)),
        ],
      );
    });

    testWidgets('Home Live Filter (Light)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: const HomeScreen(),
        brightness: Brightness.light,
        filename: 'home_live_light.png',
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => AsyncValue.data(populatedSectionData)),
          activeTabProvider.overrideWith(() => TestActiveTabNotifier(HomeTab.today)),
          matchFilterProvider.overrideWith(() => TestMatchFilterNotifier(MatchFilterType.live)),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(false)),
        ],
      );
    });

    testWidgets('Home Loading (Dark)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: const HomeScreen(),
        brightness: Brightness.dark,
        filename: 'home_loading_dark.png',
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => const AsyncValue.loading()),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(false)),
        ],
      );
    });

    testWidgets('Home Loading (Light)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: const HomeScreen(),
        brightness: Brightness.light,
        filename: 'home_loading_light.png',
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => const AsyncValue.loading()),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(false)),
        ],
      );
    });

    testWidgets('Home Offline Cache (Dark)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: const HomeScreen(),
        brightness: Brightness.dark,
        filename: 'home_offline_dark.png',
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => AsyncValue.data(populatedSectionData)),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(true)),
        ],
      );
    });

    testWidgets('Home Offline Cache (Light)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: const HomeScreen(),
        brightness: Brightness.light,
        filename: 'home_offline_light.png',
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => AsyncValue.data(populatedSectionData)),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(true)),
        ],
      );
    });

    // ------------------------------------------------------------------------
    // 2. Match Details Screen Variants & Tabs
    // ------------------------------------------------------------------------
    testWidgets('Match Details Live (Dark)', (tester) async {
      final params = MatchDetailsParams(
        matchId: liveMatch.id,
        homeTeamId: liveMatch.homeTeamId,
        awayTeamId: liveMatch.awayTeamId,
        isLive: true,
      );
      await renderAndCapture(
        tester: tester,
        child: MatchDetailsScreen(matchId: liveMatch.id, initialMatch: liveMatch),
        brightness: Brightness.dark,
        filename: 'match_live_dark.png',
        overrides: [
          matchEventsProvider(params).overrideWith((ref) async => sampleEvents),
          matchStandingsProvider(101).overrideWith((ref) async => sampleStandings),
        ],
      );
    });

    testWidgets('Match Details Live (Light)', (tester) async {
      final params = MatchDetailsParams(
        matchId: liveMatch.id,
        homeTeamId: liveMatch.homeTeamId,
        awayTeamId: liveMatch.awayTeamId,
        isLive: true,
      );
      await renderAndCapture(
        tester: tester,
        child: MatchDetailsScreen(matchId: liveMatch.id, initialMatch: liveMatch),
        brightness: Brightness.light,
        filename: 'match_live_light.png',
        overrides: [
          matchEventsProvider(params).overrideWith((ref) async => sampleEvents),
          matchStandingsProvider(101).overrideWith((ref) async => sampleStandings),
        ],
      );
    });

    testWidgets('Match Details Finished (Dark)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: MatchDetailsScreen(matchId: finishedMatch.id, initialMatch: finishedMatch),
        brightness: Brightness.dark,
        filename: 'match_finished_dark.png',
      );
    });

    testWidgets('Match Details Finished (Light)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: MatchDetailsScreen(matchId: finishedMatch.id, initialMatch: finishedMatch),
        brightness: Brightness.light,
        filename: 'match_finished_light.png',
      );
    });

    testWidgets('Match Details Upcoming (Dark)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: MatchDetailsScreen(matchId: upcomingMatch.id, initialMatch: upcomingMatch),
        brightness: Brightness.dark,
        filename: 'match_upcoming_dark.png',
      );
    });

    testWidgets('Match Details Upcoming (Light)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: MatchDetailsScreen(matchId: upcomingMatch.id, initialMatch: upcomingMatch),
        brightness: Brightness.light,
        filename: 'match_upcoming_light.png',
      );
    });

    // ------------------------------------------------------------------------
    // 2b. Match Details Tabs (Lineup, Stats, Standings)
    // ------------------------------------------------------------------------
    testWidgets('Match Details Tab Lineup (Dark)', (tester) async {
      final params = MatchDetailsParams(
        matchId: liveMatch.id,
        homeTeamId: liveMatch.homeTeamId,
        awayTeamId: liveMatch.awayTeamId,
        isLive: true,
      );
      final homeStarters = List.generate(
        11,
        (i) => LineupPlayer(
          id: 100 + i,
          name: i == 0 ? 'أليسون' : (i == 1 ? 'أرنولد' : (i == 2 ? 'فان دايك' : (i == 3 ? 'كوناتي' : (i == 4 ? 'روبرتسون' : 'صلاح $i')))),
          number: i + 1,
          position: i == 0 ? 'G' : (i < 5 ? 'D' : (i < 8 ? 'M' : 'F')),
        ),
      );
      final awayStarters = List.generate(
        11,
        (i) => LineupPlayer(
          id: 200 + i,
          name: i == 0 ? 'إيدرسون' : (i == 1 ? 'ووكر' : (i == 2 ? 'دياز' : (i == 3 ? 'أكانجي' : (i == 4 ? 'غفارديول' : 'هالاند $i')))),
          number: i + 1,
          position: i == 0 ? 'G' : (i < 5 ? 'D' : (i < 8 ? 'M' : 'F')),
        ),
      );
      final lineupData = MatchLineupModel(
        homeLineup: TeamLineupData(
          formation: '4-3-3',
          startingXI: homeStarters,
          substitutes: const [],
          coach: 'آرني سلوت',
        ),
        awayLineup: TeamLineupData(
          formation: '4-2-3-1',
          startingXI: awayStarters,
          substitutes: const [],
          coach: 'بيب غوارديولا',
        ),
      );

      await renderAndCapture(
        tester: tester,
        child: MatchDetailsScreen(
          matchId: liveMatch.id,
          initialMatch: liveMatch,
          initialTabIndex: 1, // Lineup tab
        ),
        brightness: Brightness.dark,
        filename: 'match_tab_lineup_dark.png',
        overrides: [
          matchLineupProvider(params).overrideWith((ref) async => lineupData),
        ],
      );
    });

    testWidgets('Match Details Tab Stats (Dark)', (tester) async {
      final params = MatchDetailsParams(
        matchId: liveMatch.id,
        homeTeamId: liveMatch.homeTeamId,
        awayTeamId: liveMatch.awayTeamId,
        isLive: true,
      );
      final statsData = MatchStatisticsModel(
        homeStats: const TeamStats(
          teamId: 10,
          possession: 58,
          totalShots: 16,
          shotsOnGoal: 7,
          corners: 6,
          fouls: 9,
          yellowCards: 1,
        ),
        awayStats: const TeamStats(
          teamId: 20,
          possession: 42,
          totalShots: 11,
          shotsOnGoal: 4,
          corners: 3,
          fouls: 12,
          yellowCards: 2,
        ),
      );

      await renderAndCapture(
        tester: tester,
        child: MatchDetailsScreen(
          matchId: liveMatch.id,
          initialMatch: liveMatch,
          initialTabIndex: 2, // Stats tab
        ),
        brightness: Brightness.dark,
        filename: 'match_tab_stats_dark.png',
        overrides: [
          matchStatisticsProvider(params).overrideWith((ref) async => statsData),
        ],
      );
    });

    testWidgets('Match Details Tab Standings (Dark)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: MatchDetailsScreen(
          matchId: liveMatch.id,
          initialMatch: liveMatch,
          initialTabIndex: 4, // Standings tab
        ),
        brightness: Brightness.dark,
        filename: 'match_tab_standings_dark.png',
        overrides: [
          matchStandingsProvider(101).overrideWith((ref) async => sampleStandings),
        ],
      );
    });

    // ------------------------------------------------------------------------
    // 3. Leagues Screen
    // ------------------------------------------------------------------------
    testWidgets('Leagues Screen (Dark)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: const LeaguesScreen(),
        brightness: Brightness.dark,
        filename: 'leagues_dark.png',
        overrides: [
          onboardingProvider.overrideWith(() => TestOnboardingNotifier(
            OnboardingState(
              leagues: sampleLeagues,
              selectedLeagueIds: const ['eng_1', 'ucl'],
            ),
          )),
        ],
      );
    });

    testWidgets('Leagues Screen (Light)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: const LeaguesScreen(),
        brightness: Brightness.light,
        filename: 'leagues_light.png',
        overrides: [
          onboardingProvider.overrideWith(() => TestOnboardingNotifier(
            OnboardingState(
              leagues: sampleLeagues,
              selectedLeagueIds: const ['eng_1', 'ucl'],
            ),
          )),
        ],
      );
    });

    // ------------------------------------------------------------------------
    // 4. Team Selection Screen
    // ------------------------------------------------------------------------
    testWidgets('Team Selection Screen (Dark)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: const TeamSelectionScreen(),
        brightness: Brightness.dark,
        filename: 'team_selection_dark.png',
        overrides: [
          onboardingProvider.overrideWith(() => TestOnboardingNotifier(
            OnboardingState(
              leagues: sampleLeagues,
              selectedLeagueIds: const ['eng_1', 'esp_1'],
              selectedTeamIds: const ['10', '30'],
              leagueTeams: {
                'eng_1': [sampleTeams[0], sampleTeams[1]],
                'esp_1': [sampleTeams[2], sampleTeams[3]],
              },
            ),
          )),
        ],
      );
    });

    testWidgets('Team Selection Screen (Light)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: const TeamSelectionScreen(),
        brightness: Brightness.light,
        filename: 'team_selection_light.png',
        overrides: [
          onboardingProvider.overrideWith(() => TestOnboardingNotifier(
            OnboardingState(
              leagues: sampleLeagues,
              selectedLeagueIds: const ['eng_1', 'esp_1'],
              selectedTeamIds: const ['10', '30'],
              leagueTeams: {
                'eng_1': [sampleTeams[0], sampleTeams[1]],
                'esp_1': [sampleTeams[2], sampleTeams[3]],
              },
            ),
          )),
        ],
      );
    });

    // ------------------------------------------------------------------------
    // 5. Settings Screen
    // ------------------------------------------------------------------------
    testWidgets('Settings Screen (Dark)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: const SettingsScreen(),
        brightness: Brightness.dark,
        filename: 'settings_dark.png',
      );
    });

    testWidgets('Settings Screen (Light)', (tester) async {
      await renderAndCapture(
        tester: tester,
        child: const SettingsScreen(),
        brightness: Brightness.light,
        filename: 'settings_light.png',
      );
    });
  });
}

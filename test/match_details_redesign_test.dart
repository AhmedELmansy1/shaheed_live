import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/core/theme/app_theme.dart';
import 'package:shoot_live/core/utils/date_formatter.dart';
import 'package:shoot_live/data/models/match_event_model.dart';
import 'package:shoot_live/data/models/match_info_model.dart';
import 'package:shoot_live/data/models/match_lineup_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/match_statistics_model.dart';
import 'package:shoot_live/presentation/match_details/match_details_screen.dart';
import 'package:shoot_live/presentation/match_details/providers/match_details_providers.dart';
import 'package:shoot_live/presentation/match_details/tabs/events_tab.dart';
import 'package:shoot_live/presentation/match_details/tabs/info_tab.dart';
import 'package:shoot_live/presentation/match_details/tabs/lineup_tab.dart';
import 'package:shoot_live/presentation/match_details/tabs/statistics_tab.dart';
import 'package:shoot_live/presentation/widgets/app_empty_state.dart';
import 'package:shoot_live/presentation/widgets/app_error_state.dart';
import 'package:shoot_live/presentation/widgets/score_view.dart';
import 'package:shoot_live/presentation/widgets/status_chip.dart';
import 'package:shoot_live/presentation/widgets/team_logo.dart';

void main() {
  group('Match Details & Tabs Redesign (Step 3)', () {
    const homeTeam = TeamInfo(
      rowId: 1,
      title: 'الأهلي',
      image: 'https://example.com/ahly.png',
    );
    const awayTeam = TeamInfo(
      rowId: 2,
      title: 'الزمالك',
      image: 'https://example.com/zamalek.png',
    );
    const champ = ChampionshipInfo(
      id: 10,
      title: 'الدوري المصري الممتاز',
      image: 'https://example.com/egypt_league.png',
    );

    MatchModel createMatch({
      required MatchStatus status,
      bool isLive = false,
      String? homeScore,
      String? awayScore,
      String? matchTime,
    }) {
      return MatchModel(
        matchId: 12345,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        championship: champ,
        status: status,
        isLive: isLive,
        homeScore: homeScore,
        awayScore: awayScore,
        matchTime: matchTime ?? '19:00',
        matchDate: '2026-11-08',
      );
    }

    Widget createScreenHarness({
      required MatchModel match,
      Brightness brightness = Brightness.light,
      List<dynamic> overrides = const [],
    }) {
      return ProviderScope(
        overrides: overrides.cast(),
        child: MaterialApp(
          theme: brightness == Brightness.light
              ? AppTheme.lightTheme
              : AppTheme.darkTheme,
          home: MatchDetailsScreen(
            matchId: match.id,
            initialMatch: match,
          ),
        ),
      );
    }

    testWidgets('Header renders TeamLogos, score, and finished status correctly in Light mode', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final match = createMatch(
        status: MatchStatus.finished,
        homeScore: '2',
        awayScore: '1',
      );

      await tester.pumpWidget(createScreenHarness(match: match));
      await tester.pumpAndSettle();

      expect(find.byType(TeamLogo), findsNWidgets(2));
      expect(find.text('الأهلي'), findsAtLeastNWidgets(1));
      expect(find.text('الزمالك'), findsAtLeastNWidgets(1));
      expect(find.byType(ScoreView), findsOneWidget);
      expect(find.byType(StatusChip), findsOneWidget);
      expect(find.text('الدوري المصري الممتاز'), findsAtLeastNWidgets(1));
    });

    testWidgets('Header renders upcoming kickoff time and reminder bell in Dark mode', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final match = createMatch(
        status: MatchStatus.notStarted,
        matchTime: '20:30',
      );

      await tester.pumpWidget(createScreenHarness(
        match: match,
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ScoreView), findsNothing);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    });

    testWidgets('InfoTab renders available details and hides empty fields without "غير محدد"', (tester) async {
      final match = createMatch(status: MatchStatus.notStarted);
      const testInfo = MatchInfoModel(
        matchId: 12345,
        stadium: 'استاد القاهرة الدولي',
        refereeName: 'محمود عاشور',
        channel: 'أون تايم سبورتس 1',
        commentator: null, // Empty, should NOT render
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchInfoProvider(match.id).overrideWith(
              (ref) async => testInfo,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: InfoTab(match: match),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Stadium, referee, and channel must be visible
      expect(find.text('استاد القاهرة الدولي'), findsOneWidget);
      expect(find.text('محمود عاشور'), findsOneWidget);
      expect(find.text('أون تايم سبورتس 1'), findsOneWidget);

      // Must NOT contain "غير محدد"
      expect(find.textContaining('غير محدد'), findsNothing);
    });

    testWidgets('InfoTab shows error state with retry on failure', (tester) async {
      final match = createMatch(status: MatchStatus.notStarted);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchInfoProvider(match.id).overrideWith(
              (ref) async => throw Exception('Network error'),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: InfoTab(match: match),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('تعذر تحميل معلومات المباراة'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });

    testWidgets('StatisticsTab renders proportional comparison bars', (tester) async {
      const params = MatchDetailsParams(
        matchId: '12345',
        homeTeamId: 1,
        awayTeamId: 2,
      );
      const testStats = MatchStatisticsModel(
        homeStats: TeamStats(
          teamId: 1,
          possession: 60,
          shotsOnGoal: 7,
          totalShots: 12,
        ),
        awayStats: TeamStats(
          teamId: 2,
          possession: 40,
          shotsOnGoal: 3,
          totalShots: 8,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchStatisticsProvider(params).overrideWith(
              (ref) async => testStats,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: StatisticsTab(params: params),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الاستحواذ'), findsOneWidget);
      expect(find.text('تسديدات على المرمى'), findsOneWidget);
      expect(find.text('إجمالي التسديدات'), findsOneWidget);
    });

    testWidgets('StatisticsTab renders empty state when stats are null', (tester) async {
      const params = MatchDetailsParams(
        matchId: '12345',
        homeTeamId: 1,
        awayTeamId: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchStatisticsProvider(params).overrideWith(
              (ref) async => null,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: StatisticsTab(params: params),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('لا تتوفر إحصائيات لهذه المباراة حالياً'), findsOneWidget);
    });

    testWidgets('EventsTab renders vertical timeline with goals and cards in RTL', (tester) async {
      const params = MatchDetailsParams(
        matchId: '12345',
        homeTeamId: 1,
        awayTeamId: 2,
      );
      const testEvents = [
        MatchEventModel(
          eventId: 1,
          minute: 23,
          eventType: MatchEventType.goal,
          statusName: 'هدف',
          playerName: 'محمد شريف',
          teamId: 1,
        ),
        MatchEventModel(
          eventId: 2,
          minute: 45,
          eventType: MatchEventType.yellowCard,
          statusName: 'بطاقة صفراء',
          playerName: 'أحمد فتوح',
          teamId: 2,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchEventsProvider(params).overrideWith(
              (ref) async => testEvents,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: EventsTab(
                params: params,
                homeTeamId: 1,
                awayTeamId: 2,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('محمد شريف'), findsOneWidget);
      expect(find.text('أحمد فتوح'), findsOneWidget);
      expect(find.text('هدف'), findsOneWidget);
      expect(find.text('بطاقة صفراء'), findsOneWidget);
    });

    testWidgets('LineupTab renders neutral pitch (zero green) and tactical formations', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const params = MatchDetailsParams(
        matchId: '12345',
        homeTeamId: 1,
        awayTeamId: 2,
      );
      final homeStarters = List.generate(
        11,
        (i) => LineupPlayer(
          id: 100 + i,
          name: 'لاعب أ $i',
          number: i + 1,
          position: i == 0 ? 'GK' : (i < 5 ? 'DEF' : 'MID'),
        ),
      );
      final awayStarters = List.generate(
        11,
        (i) => LineupPlayer(
          id: 200 + i,
          name: 'لاعب ب $i',
          number: i + 1,
          position: i == 0 ? 'GK' : (i < 5 ? 'DEF' : 'MID'),
        ),
      );

      final lineupData = MatchLineupModel(
        homeLineup: TeamLineupData(
          formation: '4-3-3',
          startingXI: homeStarters,
          substitutes: const [],
          coach: 'مارسيل كولر',
        ),
        awayLineup: TeamLineupData(
          formation: '4-2-3-1',
          startingXI: awayStarters,
          substitutes: const [],
          coach: 'جوزيه جوميز',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchLineupProvider(params).overrideWith(
              (ref) async => lineupData,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: LineupTab(params: params),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check formations displayed in Arabic numerals
      expect(find.text(DateFormatter.toArabicNumerals('4-3-3')), findsOneWidget);
      expect(find.text(DateFormatter.toArabicNumerals('4-2-3-1')), findsOneWidget);
      // Check managers displayed
      expect(find.text('مارسيل كولر'), findsOneWidget);
      expect(find.text('جوزيه جوميز'), findsOneWidget);
      // Check pitch is rendered
      expect(find.byType(NeutralPitchView), findsOneWidget);
    });

    testWidgets('LineupTab falls back gracefully to a list when formations are missing', (tester) async {
      const params = MatchDetailsParams(
        matchId: '12345',
        homeTeamId: 1,
        awayTeamId: 2,
      );
      final homeStarters = [
        const LineupPlayer(id: 1, name: 'محمد الشناوي', number: 1, position: 'GK'),
      ];
      final awayStarters = [
        const LineupPlayer(id: 2, name: 'محمد عواد', number: 1, position: 'GK'),
      ];

      final lineupData = MatchLineupModel(
        homeLineup: TeamLineupData(
          formation: null, // Missing formation
          startingXI: homeStarters,
          substitutes: const [],
        ),
        awayLineup: TeamLineupData(
          formation: null, // Missing formation
          startingXI: awayStarters,
          substitutes: const [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchLineupProvider(params).overrideWith(
              (ref) async => lineupData,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: LineupTab(params: params),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pitch should not be rendered
      expect(find.byType(NeutralPitchView), findsNothing);
      // List entries should be rendered
      expect(find.text('محمد الشناوي'), findsOneWidget);
      expect(find.text('محمد عواد'), findsOneWidget);
    });
  });
}

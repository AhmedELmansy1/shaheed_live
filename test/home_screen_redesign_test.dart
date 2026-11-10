import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/config/app_constants.dart';
import 'package:shoot_live/core/network/app_exception.dart';
import 'package:shoot_live/core/theme/app_theme.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/presentation/home/home_screen.dart';
import 'package:shoot_live/presentation/home/providers/matches_provider.dart';
import 'package:shoot_live/presentation/widgets/app_empty_state.dart';
import 'package:shoot_live/presentation/widgets/app_error_state.dart';
import 'package:shoot_live/presentation/widgets/day_selector.dart';
import 'package:shoot_live/presentation/widgets/hero_match_card.dart';
import 'package:shoot_live/presentation/widgets/match_card.dart';
import 'package:shoot_live/presentation/widgets/matches_skeleton.dart';
import 'package:shoot_live/presentation/widgets/section_header.dart';

class TestOfflineFallbackNotifier extends OfflineFallbackNotifier {
  final bool initialValue;
  TestOfflineFallbackNotifier([this.initialValue = false]);

  @override
  bool build() => initialValue;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleHeroMatch = MatchModel(
    matchId: 3001,
    matchDate: '2026-11-08',
    matchTime: '21:00',
    isLive: true,
    status: MatchStatus.live,
    championship: const ChampionshipInfo(id: 1, title: 'الدوري الإنجليزي الممتاز'),
    homeTeam: const TeamInfo(rowId: 10, title: 'ليفربول'),
    awayTeam: const TeamInfo(rowId: 20, title: 'ريال مدريد'),
    homeScore: '2',
    awayScore: '1',
    adminTitle: '٧٥\'',
  );

  final sampleLeagueMatch = MatchModel(
    matchId: 3002,
    matchDate: '2026-11-08',
    matchTime: '23:00',
    isLive: false,
    status: MatchStatus.notStarted,
    championship: const ChampionshipInfo(id: 2, title: 'دوري أبطال أوروبا'),
    homeTeam: const TeamInfo(rowId: 30, title: 'مانشستر سيتي'),
    awayTeam: const TeamInfo(rowId: 40, title: 'بايرن ميونخ'),
    adminTitle: 'لم تبدأ',
  );

  final sampleSectionData = HomeSectionData(
    heroMatch: sampleHeroMatch,
    favoriteMatches: [],
    liveMatches: [sampleHeroMatch],
    allFilteredMatches: [sampleHeroMatch, sampleLeagueMatch],
    leagueGroups: [
      LeagueGroupData(
        leagueTitle: 'دوري أبطال أوروبا',
        leagueLogo: null,
        matches: [sampleLeagueMatch],
        isFollowed: true,
      ),
    ],
  );

  const emptySectionData = HomeSectionData(
    heroMatch: null,
    favoriteMatches: [],
    liveMatches: [],
    allFilteredMatches: [],
    leagueGroups: [],
  );

  Widget createHomeScreenWidget({
    required List<dynamic> overrides,
    ThemeData? theme,
    Size? surfaceSize,
    double textScaleFactor = 1.0,
  }) {
    return ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQueryData(
              size: surfaceSize ?? const Size(400, 1400),
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: const Scaffold(body: HomeScreen()),
          ),
        ),
      ),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HomeScreen Redesign — Loading & Skeleton States', () {
    testWidgets('Renders MatchesSkeleton when section data is loading (Light Theme)', (tester) async {
      await tester.pumpWidget(createHomeScreenWidget(
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => const AsyncValue.loading()),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(false)),
        ],
        theme: AppTheme.lightTheme,
      ));

      expect(find.byType(DaySelector), findsOneWidget);
      expect(find.byType(MatchesSkeleton), findsOneWidget);
      expect(find.text(AppConstants.appName), findsOneWidget);
    });

    testWidgets('Renders MatchesSkeleton when section data is loading (Dark Theme)', (tester) async {
      await tester.pumpWidget(createHomeScreenWidget(
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => const AsyncValue.loading()),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(false)),
        ],
        theme: AppTheme.darkTheme,
      ));

      expect(find.byType(DaySelector), findsOneWidget);
      expect(find.byType(MatchesSkeleton), findsOneWidget);
      expect(find.text(AppConstants.appName), findsOneWidget);
    });
  });

  group('HomeScreen Redesign — Populated & Cached Data States', () {
    testWidgets('Renders DaySelector, HeroMatchCard, SectionHeader, and MatchCard in Light Theme', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createHomeScreenWidget(
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => AsyncValue.data(sampleSectionData)),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(false)),
        ],
        theme: AppTheme.lightTheme,
      ));

      await tester.pumpAndSettle();

      expect(find.byType(DaySelector), findsOneWidget);
      expect(find.byType(HeroMatchCard), findsOneWidget);
      expect(find.byType(SectionHeader), findsOneWidget);
      expect(find.byType(MatchCard), findsWidgets);
      expect(find.text('ليفربول'), findsWidgets);
      expect(find.text('ريال مدريد'), findsWidgets);
      expect(find.text('مانشستر سيتي'), findsOneWidget);
      expect(find.text('بايرن ميونخ'), findsOneWidget);
    });

    testWidgets('Renders DaySelector, HeroMatchCard, and MatchCard in Dark Theme', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createHomeScreenWidget(
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => AsyncValue.data(sampleSectionData)),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(false)),
        ],
        theme: AppTheme.darkTheme,
      ));

      await tester.pumpAndSettle();

      expect(find.byType(DaySelector), findsOneWidget);
      expect(find.byType(HeroMatchCard), findsOneWidget);
      expect(find.text('المباراة المميزة'), findsOneWidget);
      expect(find.text('دوري أبطال أوروبا'), findsWidgets);
    });
  });

  group('HomeScreen Redesign — Offline Cache Fallback Banner', () {
    testWidgets('Displays restyled offline banner when offlineFallbackProvider is true (Light Theme)', (tester) async {
      await tester.pumpWidget(createHomeScreenWidget(
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => AsyncValue.data(sampleSectionData)),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(true)),
        ],
        theme: AppTheme.lightTheme,
      ));

      await tester.pumpAndSettle();

      expect(find.text('أنت تشاهد بيانات محفوظة (غير متصل بالإنترنت)'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('Displays restyled offline banner when offlineFallbackProvider is true (Dark Theme)', (tester) async {
      await tester.pumpWidget(createHomeScreenWidget(
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => AsyncValue.data(sampleSectionData)),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(true)),
        ],
        theme: AppTheme.darkTheme,
      ));

      await tester.pumpAndSettle();

      expect(find.text('أنت تشاهد بيانات محفوظة (غير متصل بالإنترنت)'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });
  });

  group('HomeScreen Redesign — Empty & Error States', () {
    testWidgets('Renders AppEmptyState when section data is empty', (tester) async {
      await tester.pumpWidget(createHomeScreenWidget(
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => const AsyncValue.data(emptySectionData)),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(false)),
        ],
        theme: AppTheme.lightTheme,
      ));

      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
    });

    testWidgets('Renders AppErrorState with Arabic message on NetworkException', (tester) async {
      await tester.pumpWidget(createHomeScreenWidget(
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => AsyncValue.error(
            NetworkException(),
            StackTrace.empty,
          )),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(false)),
        ],
        theme: AppTheme.lightTheme,
      ));

      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });

    testWidgets('Renders AppErrorState with 404 Arabic message on ServerException(404)', (tester) async {
      await tester.pumpWidget(createHomeScreenWidget(
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => AsyncValue.error(
            ServerException(statusCode: 404),
            StackTrace.empty,
          )),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(false)),
        ],
        theme: AppTheme.darkTheme,
      ));

      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('لم يتم العثور على المباريات'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });
  });

  group('HomeScreen Redesign — 360dp Width & 1.3x Text Scale Responsiveness', () {
    testWidgets('Renders cleanly on 360dp phone with 1.3x text scale without overflow', (tester) async {
      final errors = <FlutterErrorDetails>[];
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
      };

      await tester.pumpWidget(createHomeScreenWidget(
        overrides: [
          homeSectionDataProvider.overrideWith((ref) => AsyncValue.data(sampleSectionData)),
          offlineFallbackProvider.overrideWith(() => TestOfflineFallbackNotifier(true)),
        ],
        surfaceSize: const Size(360, 640),
        textScaleFactor: 1.3,
        theme: AppTheme.lightTheme,
      ));

      await tester.pumpAndSettle();
      FlutterError.onError = prevOnError;

      if (errors.isNotEmpty) {
        for (final e in errors) {
          debugPrint('OVERFLOW DETAILS:\n${e.exceptionAsString()}\n${e.context}\n${e.informationCollector?.call().join("\n")}');
        }
      }

      expect(errors, isEmpty);
      expect(find.byType(DaySelector), findsOneWidget);
      expect(find.byType(HeroMatchCard), findsOneWidget);
      expect(find.text('أنت تشاهد بيانات محفوظة (غير متصل بالإنترنت)'), findsOneWidget);
    });
  });
}

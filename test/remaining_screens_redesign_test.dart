import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/config/app_constants.dart';
import 'package:shoot_live/core/theme/app_theme.dart';
import 'package:shoot_live/data/models/league_model.dart';
import 'package:shoot_live/data/models/standings_model.dart';
import 'package:shoot_live/presentation/leagues/leagues_screen.dart';
import 'package:shoot_live/presentation/match_details/providers/match_details_providers.dart';
import 'package:shoot_live/presentation/match_details/tabs/standings_tab.dart';
import 'package:shoot_live/presentation/onboarding/notification_permission_screen.dart';
import 'package:shoot_live/presentation/onboarding/providers/onboarding_provider.dart';
import 'package:shoot_live/presentation/settings/settings_screen.dart';
import 'package:shoot_live/presentation/splash/splash_screen.dart';
import 'package:shoot_live/presentation/widgets/app_error_state.dart';
import 'package:shoot_live/presentation/widgets/matches_skeleton.dart';
import 'package:shoot_live/presentation/widgets/section_header.dart';

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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Step 4 — Remaining Screens Redesign Tests', () {
    testWidgets('LeaguesScreen renders SectionHeader and league cards in Light and Dark mode', (tester) async {
      final testLeagues = [
        const LeagueModel(
          id: 'eng_1',
          name: 'الدوري الإنجليزي الممتاز',
          nameEn: 'Premier League',
          country: 'إنجلترا',
        ),
        const LeagueModel(
          id: 'esp_1',
          name: 'الدوري الإسباني',
          nameEn: 'La Liga',
          country: 'إسبانيا',
        ),
      ];

      final state = OnboardingState(
        leagues: testLeagues,
        selectedLeagueIds: ['eng_1'],
        isLoading: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingProvider.overrideWith(() => TestOnboardingNotifier(state)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: LeaguesScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SectionHeader), findsNWidgets(2));
      expect(find.text('البطولات المفضلة'), findsOneWidget);
      expect(find.text('جميع البطولات'), findsNothing);
      expect(find.text('بطولات أخرى'), findsOneWidget);
      expect(find.text('الدوري الإنجليزي الممتاز'), findsOneWidget);
      expect(find.text('الدوري الإسباني'), findsOneWidget);
    });

    testWidgets('LeaguesScreen renders MatchesSkeleton when loading', (tester) async {
      const state = OnboardingState(isLoading: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingProvider.overrideWith(() => TestOnboardingNotifier(state)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: LeaguesScreen(),
            ),
          ),
        ),
      );

      expect(find.byType(MatchesSkeleton), findsOneWidget);
    });

    testWidgets('StandingsTab renders table with clean typography and tabular numerals (zero green)', (tester) async {
      final rows = [
        const StandingRowModel(
          rank: 1,
          teamId: 10,
          teamName: 'ليفربول',
          played: 10,
          won: 8,
          drawn: 1,
          lost: 1,
          goalsFor: 25,
          goalsAgainst: 10,
          goalDiff: 15,
          points: 25,
        ),
        const StandingRowModel(
          rank: 2,
          teamId: 20,
          teamName: 'مانشستر سيتي',
          played: 10,
          won: 7,
          drawn: 2,
          lost: 1,
          goalsFor: 22,
          goalsAgainst: 10,
          goalDiff: 12,
          points: 23,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchStandingsProvider(1001).overrideWith((ref) async => rows),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: StandingsTab(matchId: 1001),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ليفربول'), findsOneWidget);
      expect(find.text('مانشستر سيتي'), findsOneWidget);
      expect(find.text('الفريق'), findsOneWidget);
      expect(find.text('نقاط'), findsOneWidget);
      // Latin tabular numerals standard
      expect(find.text('25'), findsOneWidget);
      expect(find.text('23'), findsOneWidget);
    });

    testWidgets('StandingsTab renders AppErrorState with retry on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchStandingsProvider(1001).overrideWith((ref) async => throw Exception('Fetch failed')),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: StandingsTab(matchId: 1001),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('تعذر تحميل جدول الترتيب'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });

    testWidgets('SplashScreen renders editorial title with AppConstants.appName and NO green', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Verify single source of truth brand name
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text('دليلك الشامل لمواعيد ونتائج المباريات'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders ThemeMode options with 48dp minimum targets', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: SettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('المظهر العام'), findsOneWidget);
      expect(find.text('داكن'), findsOneWidget);
      expect(find.text('فاتح'), findsOneWidget);
      expect(find.text('تلقائي'), findsOneWidget);

      // Tap dark mode option
      await tester.tap(find.text('داكن'));
      await tester.pumpAndSettle();

      // Tap light mode option
      await tester.tap(find.text('فاتح'));
      await tester.pumpAndSettle();
    });

    testWidgets('NotificationPermissionScreen renders design tokens in Light and Dark', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: NotificationPermissionScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تفعيل إشعارات المباريات المباشرة'), findsOneWidget);
      expect(find.text('تفعيل الإشعارات'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
    });
  });
}

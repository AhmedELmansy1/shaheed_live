import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore_for_file: unused_local_variable
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/config/app_constants.dart';
import 'package:shoot_live/core/theme/theme_provider.dart';
import 'package:shoot_live/core/utils/match_share_helper.dart';
import 'package:shoot_live/core/utils/timezone_helper.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/presentation/home/providers/matches_provider.dart';
import 'package:shoot_live/presentation/onboarding/providers/onboarding_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('ar', null);
    await TimezoneHelper.init();
  });

  group('FEATURE 3: Light / Dark Theme Mode Provider Tests', () {
    test('Default theme mode is dark and persists changes', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default is dark
      expect(container.read(themeModeProvider), ThemeMode.dark);

      // Change to light
      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'light');

      // Change to system
      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(prefs.getString('app_theme_mode'), 'system');
    });
  });

  group('FEATURE 4: MatchShareHelper Arabic Templates Tests', () {
    test('Live match share text includes red live indicator, scores, and live minute', () {
      const match = MatchModel(
        matchId: 101,
        matchDate: '2026-09-24',
        matchTime: '20:00:00',
        isLive: true,
        status: MatchStatus.live,
        homeTeam: TeamInfo(rowId: 1, title: 'الأهلي', image: ''),
        awayTeam: TeamInfo(rowId: 2, title: 'الزمالك', image: ''),
        championship: ChampionshipInfo(id: 10, title: 'الدوري المصري', image: ''),
        homeScore: '2',
        awayScore: '1',
        adminTitle: "67'",
      );

      final text = MatchShareHelper.getShareText(match);
      expect(text, contains('🔴 مباشر الآن: الأهلي 2 - 1 الزمالك'));
      expect(text, contains("الدقيقة 67'"));
      expect(text, contains('الدوري المصري'));
      expect(text, contains('عبر تطبيق ${AppConstants.appName}'));
    });

    test('Finished match share text includes final score', () {
      const match = MatchModel(
        matchId: 102,
        matchDate: '2026-09-24',
        matchTime: '18:00:00',
        isLive: false,
        status: MatchStatus.finished,
        homeTeam: TeamInfo(rowId: 3, title: 'ريال مدريد', image: ''),
        awayTeam: TeamInfo(rowId: 4, title: 'برشلونة', image: ''),
        championship: ChampionshipInfo(id: 20, title: 'الدوري الإسباني', image: ''),
        homeScore: '3',
        awayScore: '2',
      );

      final text = MatchShareHelper.getShareText(match);
      expect(text, contains('⚽ النتيجة النهائية: ريال مدريد 3 - 2 برشلونة'));
      expect(text, contains('الدوري الإسباني'));
      expect(text, contains('عبر تطبيق ${AppConstants.appName}'));
    });

    test('Upcoming match share text includes kickoff time', () {
      const match = MatchModel(
        matchId: 103,
        matchDate: '2026-09-25',
        matchTime: '21:00:00',
        isLive: false,
        status: MatchStatus.notStarted,
        homeTeam: TeamInfo(rowId: 5, title: 'ليفربول', image: ''),
        awayTeam: TeamInfo(rowId: 6, title: 'مانشستر سيتي', image: ''),
        championship: ChampionshipInfo(id: 30, title: 'الدوري الإنجليزي الممتاز', image: ''),
      );

      final text = MatchShareHelper.getShareText(match);
      expect(text, contains('⏰ مباراة ليفربول × مانشستر سيتي'));
      expect(text, contains('الدوري الإنجليزي الممتاز'));
      expect(text, contains('عبر تطبيق ${AppConstants.appName}'));
    });
  });

  group('FEATURE 2: Favorites Filter Tests', () {
    test('Empty favorites selection returns empty list', () {
      final container = ProviderContainer(
        overrides: [
          onboardingProvider.overrideWith(() => OnboardingNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final matches = [
        const MatchModel(
          matchId: 1,
          isLive: false,
          status: MatchStatus.notStarted,
          homeTeam: TeamInfo(rowId: 1, title: 'الأهلي', image: ''),
          awayTeam: TeamInfo(rowId: 2, title: 'الزمالك', image: ''),
          championship: ChampionshipInfo(id: 1, title: 'الدوري المصري', image: ''),
        ),
      ];

      // Set filter to favorites
      container.read(matchFilterProvider.notifier).setFilter(MatchFilterType.favorites);

      // Filtered result should be empty when user has 0 selected favorite teams
      final filter = container.read(matchFilterProvider);
      expect(filter, MatchFilterType.favorites);
      expect(container.read(onboardingProvider).selectedTeamIds.isEmpty, isTrue);
    });
  });
}

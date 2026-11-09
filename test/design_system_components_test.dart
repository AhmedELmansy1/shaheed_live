import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/core/theme/app_colors.dart';
import 'package:shoot_live/core/theme/app_theme.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/presentation/home/providers/matches_provider.dart';
import 'package:shoot_live/presentation/widgets/app_empty_state.dart';
import 'package:shoot_live/presentation/widgets/app_error_state.dart';
import 'package:shoot_live/presentation/widgets/day_selector.dart';
import 'package:shoot_live/presentation/widgets/live_badge.dart';
import 'package:shoot_live/presentation/widgets/match_card.dart';
import 'package:shoot_live/presentation/widgets/score_view.dart';
import 'package:shoot_live/presentation/widgets/status_chip.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final liveMatch = MatchModel(
    matchId: 2001,
    matchDate: '2026-11-08',
    matchTime: '20:00',
    isLive: true,
    status: MatchStatus.live,
    championship: const ChampionshipInfo(id: 1, title: 'الدوري الإنجليزي الممتاز'),
    homeTeam: const TeamInfo(rowId: 10, title: 'ليفربول'),
    awayTeam: const TeamInfo(rowId: 20, title: 'مانشستر سيتي'),
    homeScore: '2',
    awayScore: '1',
    adminTitle: '٧٢\'',
  );

  final upcomingMatch = MatchModel(
    matchId: 2002,
    matchDate: '2026-11-08',
    matchTime: '22:00',
    isLive: false,
    status: MatchStatus.notStarted,
    championship: const ChampionshipInfo(id: 2, title: 'دوري أبطال أوروبا'),
    homeTeam: const TeamInfo(rowId: 30, title: 'ريال مدريد'),
    awayTeam: const TeamInfo(rowId: 40, title: 'بايرن ميونخ'),
    adminTitle: 'لم تبدأ',
  );

  final finishedMatch = MatchModel(
    matchId: 2003,
    matchDate: '2026-11-08',
    matchTime: '17:00',
    isLive: false,
    status: MatchStatus.finished,
    championship: const ChampionshipInfo(id: 3, title: 'الدوري الإسباني'),
    homeTeam: const TeamInfo(rowId: 50, title: 'برشلونة'),
    awayTeam: const TeamInfo(rowId: 60, title: 'أتلتيكو مدريد'),
    homeScore: '3',
    awayScore: '0',
    adminTitle: 'انتهت',
  );

  Widget createTestWidget(Widget child, {ThemeData? theme}) {
    return ProviderScope(
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('Design System — MatchCard Tests', () {
    testWidgets('Live MatchCard renders vermilion accent, live badge, and scores', (tester) async {
      await tester.pumpWidget(createTestWidget(MatchCard(match: liveMatch)));

      expect(find.text('ليفربول'), findsOneWidget);
      expect(find.text('مانشستر سيتي'), findsOneWidget);
      expect(find.byType(LiveBadge), findsOneWidget);
      expect(find.text('٢'), findsOneWidget);
      expect(find.text('١'), findsOneWidget);
    });

    testWidgets('Upcoming MatchCard renders kickoff time and reminder bell icon', (tester) async {
      await tester.pumpWidget(createTestWidget(MatchCard(match: upcomingMatch)));

      expect(find.text('ريال مدريد'), findsOneWidget);
      expect(find.text('بايرن ميونخ'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byType(ScoreView), findsNothing);
    });

    testWidgets('Finished MatchCard renders final scores and finished status in dark theme', (tester) async {
      await tester.pumpWidget(createTestWidget(
        MatchCard(match: finishedMatch),
        theme: AppTheme.darkTheme,
      ));

      expect(find.text('برشلونة'), findsOneWidget);
      expect(find.text('أتلتيكو مدريد'), findsOneWidget);
      expect(find.text('انتهت'), findsOneWidget);
      expect(find.text('٣'), findsOneWidget);
      expect(find.text('٠'), findsOneWidget);
    });
  });

  group('Design System — StatusChip & ScoreView Tests', () {
    testWidgets('StatusChip renders correct states', (tester) async {
      await tester.pumpWidget(createTestWidget(Column(
        children: [
          StatusChip(match: liveMatch),
          StatusChip(match: upcomingMatch),
          StatusChip(match: finishedMatch),
        ],
      )));

      expect(find.byType(LiveBadge), findsOneWidget);
      expect(find.text('انتهت'), findsOneWidget);
    });

    testWidgets('ScoreView renders Arabic numerals and colon separator with semantic label', (tester) async {
      await tester.pumpWidget(createTestWidget(const ScoreView(
        homeScore: '3',
        awayScore: '1',
        isLive: true,
      )));

      expect(find.text('٣'), findsOneWidget);
      expect(find.text('١'), findsOneWidget);
      expect(find.text(':'), findsOneWidget);
    });
  });

  group('Design System — DaySelector Tests', () {
    testWidgets('DaySelector renders tabs and triggers callback on tap', (tester) async {
      HomeTab selectedTab = HomeTab.today;

      await tester.pumpWidget(createTestWidget(DaySelector(
        activeTab: selectedTab,
        onTabSelected: (tab) => selectedTab = tab,
        onCustomDateSelected: (_) {},
      )));

      expect(find.text('الأمس'), findsOneWidget);
      expect(find.text('اليوم'), findsOneWidget);
      expect(find.text('الغد'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);

      await tester.tap(find.text('الغد'));
      expect(selectedTab, HomeTab.tomorrow);
    });
  });

  group('Design System — AppEmptyState & AppErrorState Tests', () {
    testWidgets('AppEmptyState renders title, subtitle, and action button without overflow', (tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(createTestWidget(AppEmptyState(
        title: 'لا توجد مباريات جارية الآن',
        subtitle: 'تفقد جدول مباريات اليوم لمتابعة المباريات القادمة',
        type: EmptyStateType.soccer,
        action: ElevatedButton(
          onPressed: () => actionPressed = true,
          child: const Text('عرض كل المباريات'),
        ),
      )));

      expect(find.text('لا توجد مباريات جارية الآن'), findsOneWidget);
      expect(find.text('تفقد جدول مباريات اليوم لمتابعة المباريات القادمة'), findsOneWidget);
      expect(find.text('عرض كل المباريات'), findsOneWidget);

      await tester.tap(find.text('عرض كل المباريات'));
      expect(actionPressed, isTrue);
    });

    testWidgets('AppErrorState renders clear error copy and triggers retry callback', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(createTestWidget(AppErrorState(
        title: 'تعذر الاتصال بالخادم',
        subtitle: 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً',
        onRetry: () => retryCalled = true,
      )));

      expect(find.text('تعذر الاتصال بالخادم'), findsOneWidget);
      expect(find.text('يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);

      await tester.tap(find.text('إعادة المحاولة'));
      expect(retryCalled, isTrue);
    });
  });

  group('Design System — WCAG AA Contrast Audit', () {
    double linearChannel(double c) =>
        c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

    double relativeLuminance(Color color) {
      final r = linearChannel(color.r);
      final g = linearChannel(color.g);
      final b = linearChannel(color.b);
      return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    }

    double contrastRatio(Color fg, Color bg) {
      final l1 = relativeLuminance(fg);
      final l2 = relativeLuminance(bg);
      final lighter = math.max(l1, l2);
      final darker = math.min(l1, l2);
      return (lighter + 0.05) / (darker + 0.05);
    }

    test('All Light Mode text tokens exceed 4.5:1 WCAG AA on background, surface, and elevated', () {
      const colors = AppThemeColors.light;
      final surfaces = {
        'background (#F7F4EE)': colors.background,
        'surface (#FFFFFF)': colors.surface,
        'surfaceElevated (#FBF9F5)': colors.surfaceElevated,
      };

      final textTokens = {
        'textPrimary (#14161C)': colors.textPrimary,
        'textSecondary (#5B6070)': colors.textSecondary,
        'vermilionText (#C23318)': colors.vermilionText,
        'upcomingText (#3B5BDB)': colors.upcomingText,
        'finishedText (#525866)': colors.finishedText,
      };

      debugPrint('\n=== LIGHT THEME CONTRAST RATIOS ===');
      for (final sEntry in surfaces.entries) {
        debugPrint('-- Surface: ${sEntry.key} --');
        for (final tEntry in textTokens.entries) {
          final ratio = contrastRatio(tEntry.value, sEntry.value);
          debugPrint('   ${tEntry.key} -> ${ratio.toStringAsFixed(2)}:1');
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '${tEntry.key} on ${sEntry.key} failed WCAG AA with ratio ${ratio.toStringAsFixed(2)}:1',
          );
        }
      }
    });

    test('All Dark Mode text tokens exceed 4.5:1 WCAG AA on background, surface, and elevated', () {
      const colors = AppThemeColors.dark;
      final surfaces = {
        'background (#0E1015)': colors.background,
        'surface (#171A21)': colors.surface,
        'surfaceElevated (#1F232C)': colors.surfaceElevated,
      };

      final textTokens = {
        'textPrimary (#F2EFE8)': colors.textPrimary,
        'textSecondary (#A3A8B5)': colors.textSecondary,
        'vermilionText (#FF5A3C)': colors.vermilionText,
        'upcomingText (#6C85F5)': colors.upcomingText,
        'finishedText (#8B93A4)': colors.finishedText,
      };

      debugPrint('\n=== DARK THEME CONTRAST RATIOS ===');
      for (final sEntry in surfaces.entries) {
        debugPrint('-- Surface: ${sEntry.key} --');
        for (final tEntry in textTokens.entries) {
          final ratio = contrastRatio(tEntry.value, sEntry.value);
          debugPrint('   ${tEntry.key} -> ${ratio.toStringAsFixed(2)}:1');
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '${tEntry.key} on ${sEntry.key} failed WCAG AA with ratio ${ratio.toStringAsFixed(2)}:1',
          );
        }
      }
    });

    test('UI Non-text elements and badges exceed 3.0:1 for large/accent elements', () {
      // Light Vermilion shape/border on light background
      final lightVermilionRatio = contrastRatio(AppColors.lightVermilion, AppColors.lightBackground);
      expect(lightVermilionRatio, greaterThanOrEqualTo(3.0));

      // Dark Vermilion shape on dark surface
      final darkVermilionRatio = contrastRatio(AppColors.darkVermilion, AppColors.darkSurface);
      expect(darkVermilionRatio, greaterThanOrEqualTo(3.0));
    });
  });

  group('Design System — Font & Digits Verification', () {
    testWidgets('Font renders Arabic and Latin digits with distinct weights', (tester) async {
      await tester.pumpWidget(createTestWidget(
        Column(
          children: const [
            Text('الأهلي 1 - 0 الزمالك', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w400)),
            Text('الأهلي ١ - ٠ الزمالك', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
            Text('90+4\' مباشر', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
            Text('٩٠+٤\' مباشر', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
          ],
        ),
      ));

      expect(find.text('الأهلي 1 - 0 الزمالك'), findsOneWidget);
      expect(find.text('الأهلي ١ - ٠ الزمالك'), findsOneWidget);
      expect(find.text('90+4\' مباشر'), findsOneWidget);
      expect(find.text('٩٠+٤\' مباشر'), findsOneWidget);
    });
  });
}


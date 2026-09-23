import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/theme/app_theme.dart';
import 'package:shoot_live/presentation/onboarding/league_selection_screen.dart';
import 'package:shoot_live/presentation/onboarding/team_selection_screen.dart';
import 'package:shoot_live/presentation/onboarding/providers/onboarding_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Investigate LeagueSelectionScreen loading pipeline and render behavior', (WidgetTester tester) async {
    // ignore: avoid_print
    print('--- STARTING LEAGUE SELECTION SCREEN TEST ---');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LeagueSelectionScreen(),
        ),
      ),
    );

    // ignore: avoid_print
    print('--- INITIAL PUMP DONE ---');
    await tester.pump(const Duration(milliseconds: 200));

    // ignore: avoid_print
    print('--- POST DELAY PUMP DONE ---');
    await tester.pump(const Duration(milliseconds: 300));

    // Verify loading indicator is gone
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Verify all mock league cards render in GridView
    expect(find.text('اختر الدوريات المفضلة لديك'), findsOneWidget);
    expect(find.text('الدوري المصري الممتاز'), findsOneWidget);
    expect(find.text('الدوري الإنجليزي الممتاز'), findsOneWidget);
    expect(find.text('الدوري الإسباني'), findsOneWidget);

    // Test selection interaction
    expect(find.text('يجب اختيار دوري واحد على الأقل للمتابعة (0 محدد)'), findsOneWidget);
    await tester.tap(find.text('الدوري المصري الممتاز'));
    await tester.pump();
    expect(find.text('يجب اختيار دوري واحد على الأقل للمتابعة (1 محدد)'), findsOneWidget);

    // ignore: avoid_print
    print('--- TEST FINISHED SUCCESSFULLY ---');
  });

  testWidgets('Investigate TeamSelectionScreen with selected leagues', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TeamSelectionScreen(),
        ),
      ),
    );

    // Let initialization finish
    await tester.pump(const Duration(milliseconds: 200));

    // Select a league and save leagues
    final element = tester.element(find.byType(TeamSelectionScreen));
    final container = ProviderScope.containerOf(element);
    container.read(onboardingProvider.notifier).toggleLeagueSelection('egy_1');
    await tester.runAsync(() async {
      await container.read(onboardingProvider.notifier).saveSelectedLeagues();
    });
    await tester.pump();

    expect(find.text('اختر فرقك المفضلة'), findsOneWidget);
    expect(find.text('الأهلي'), findsOneWidget);
    expect(find.text('الزمالك'), findsOneWidget);
    expect(find.text('بيراميدز'), findsOneWidget);

    // Tap Al Ahly
    await tester.tap(find.text('الأهلي'));
    await tester.pump();

    expect(find.text('اختر نادياً واحداً على الأقل لمتابعة أخباره وتنبيهاته (1 محدد)'), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/core/theme/app_theme.dart';
import 'package:shoot_live/presentation/about/about_developer_screen.dart';

void main() {
  Widget createTestWidget({ThemeMode mode = ThemeMode.dark, TextDirection direction = TextDirection.rtl}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        home: Directionality(
          textDirection: direction,
          child: const AboutDeveloperScreen(),
        ),
      ),
    );
  }

  testWidgets('AboutDeveloperScreen renders developer profile details accurately', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify Developer Name and Titles
    expect(find.textContaining('أحمد المنسي'), findsWidgets);
    expect(find.textContaining('Ahmed Elmansy'), findsWidgets);
    expect(find.textContaining('Flutter Developer • AI • Cybersecurity'), findsWidgets);

    // Verify Academic Education Details
    expect(find.textContaining('جامعة بنها'), findsWidgets);
    expect(find.textContaining('أمن المعلومات والأدلة الجنائية الرقمية'), findsWidgets);
    expect(find.textContaining('جيد جداً • Very Good'), findsOneWidget);

    // Verify Graduation Project has Excellent grade
    expect(find.textContaining('امتياز • Excellent'), findsOneWidget);
    expect(find.textContaining('Forgery Detection'), findsWidgets);

    // Verify Services ("What I Do")
    expect(find.textContaining('ماذا أقدم؟'), findsWidgets);
    expect(find.textContaining('تطوير تطبيقات Flutter'), findsWidgets);
    expect(find.textContaining('تطبيقات مدعومة بالذكاء الاصطناعي'), findsWidgets);
    expect(find.textContaining('الأمن السيبراني'), findsWidgets);
    expect(find.textContaining('الأدلة الجنائية الرقمية'), findsWidgets);

    // Verify Skills
    expect(find.textContaining('المهارات والتخصصات'), findsWidgets);
    expect(find.text('Flutter'), findsWidgets);
    expect(find.text('Dart'), findsWidgets);
    expect(find.text('Digital Forensics'), findsWidgets);

    // Verify Projects
    expect(find.textContaining('أبرز المشاريع'), findsWidgets);
    expect(find.textContaining('AI-Powered Digital Forensics System'), findsWidgets);
    expect(find.textContaining('Match Score'), findsWidgets);

    // Verify Certificates
    expect(find.textContaining('الشهادات والتدريب'), findsWidgets);
    expect(find.textContaining('Cisco CCNA — Introduction to Networks'), findsOneWidget);
    expect(find.textContaining('Huawei HCIA-Datacom V1.0'), findsOneWidget);

    // Verify Contact
    expect(find.textContaining('تواصل معي'), findsWidgets);
    expect(find.textContaining('تواصل عبر واتساب'), findsWidgets);
    expect(find.textContaining('GitHub Profile'), findsWidgets);
    expect(find.textContaining('LinkedIn Profile'), findsWidgets);
    expect(find.textContaining('ahmedelmansy1311@gmail.com'), findsWidgets);
  });

  testWidgets('AboutDeveloperScreen renders in Light Mode without overflow or errors', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget(mode: ThemeMode.light));
    await tester.pumpAndSettle();

    expect(find.byType(AboutDeveloperScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AboutDeveloperScreen renders in small screen size without overflow', (WidgetTester tester) async {
    // Test on a small 360x640 mobile screen
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final exception = tester.takeException();
    expect(find.byType(AboutDeveloperScreen), findsOneWidget);
    expect(exception, isNull);
  });
}

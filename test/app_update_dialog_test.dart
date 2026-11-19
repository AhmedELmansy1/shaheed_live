import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/presentation/update/widgets/app_update_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUpdateDialog Tests', () {
    testWidgets('Renders update dialog with default message, title, and link', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppUpdateDialog(
                downloadUrl: 'https://shootlive.app/download',
                latestVersion: '2.0.0',
              ),
            ),
          ),
        ),
      );

      // Verify header badge, title and buttons
      expect(find.text('تحديث جديد متوفر v2.0.0'), findsOneWidget);
      expect(find.text('يرجى تحميل التحديث الجديد ⚽'), findsOneWidget);
      expect(find.text('https://shootlive.app/download'), findsOneWidget);
      expect(find.text('تحميل التحديث الآن'), findsOneWidget);
      expect(find.text('تذكيري لاحقاً'), findsOneWidget);
    });

    testWidgets('Renders custom update message when supplied', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppUpdateDialog(
                downloadUrl: 'https://shootlive.app/download',
                message: 'سيرفرات بث جديدة بدون تقطيع تم تفعيلها الآن.',
              ),
            ),
          ),
        ),
      );

      expect(find.text('سيرفرات بث جديدة بدون تقطيع تم تفعيلها الآن.'), findsOneWidget);
    });

    test('UpdateDialogSessionNotifier marks shown once per session', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(updateDialogShownSessionProvider), isFalse);

      container.read(updateDialogShownSessionProvider.notifier).markShown();
      expect(container.read(updateDialogShownSessionProvider), isTrue);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/data/models/ticker_config_model.dart';
import 'package:shoot_live/presentation/home/widgets/breaking_news_ticker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TickerConfigModel Unit Tests', () {
    test('Parses from full Map matching dashboard schema', () {
      final map = {
        'enabled': true,
        'text': 'انطلاق قمة الكلاسيكو بعد قليل ⚽',
        'type': 'breaking',
        'action_url': 'https://shootlive.app/match/5795507',
      };

      final model = TickerConfigModel.fromMap(map);

      expect(model.enabled, isTrue);
      expect(model.text, 'انطلاق قمة الكلاسيكو بعد قليل ⚽');
      expect(model.type, 'breaking');
      expect(model.actionUrl, 'https://shootlive.app/match/5795507');
      expect(model.isValid, isTrue);
    });

    test('Parses gracefully with missing or malformed fields', () {
      final model = TickerConfigModel.fromMap(null);
      expect(model.enabled, isFalse);
      expect(model.text, '');
      expect(model.type, 'breaking');
      expect(model.isValid, isFalse);

      final emptyMapModel = TickerConfigModel.fromMap({});
      expect(emptyMapModel.enabled, isFalse);
      expect(emptyMapModel.text, '');
      expect(emptyMapModel.isValid, isFalse);
    });

    test('JSON serialization round-trip for caching in SharedPreferences', () {
      const original = TickerConfigModel(
        enabled: true,
        text: 'خبر عاجل: تم تأجيل المباراة لسوء الأحوال الجوية',
        type: 'warning',
        actionUrl: 'shootlive://match/1234',
      );

      final jsonStr = original.toJson();
      final restored = TickerConfigModel.fromJson(jsonStr);

      expect(restored.enabled, original.enabled);
      expect(restored.text, original.text);
      expect(restored.type, original.type);
      expect(restored.actionUrl, original.actionUrl);
    });
  });

  group('BreakingNewsTicker Widget Tests', () {
    testWidgets('Renders nothing when ticker is disabled or text is empty', (tester) async {
      const disabledModel = TickerConfigModel(
        enabled: false,
        text: 'نص إخباري لكنه معطل',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BreakingNewsTicker(overrideConfig: disabledModel),
            ),
          ),
        ),
      );

      expect(find.text('نص إخباري لكنه معطل'), findsNothing);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('Renders breaking news banner with RTL direction and "عاجل" badge', (tester) async {
      const activeModel = TickerConfigModel(
        enabled: true,
        text: 'الأهلي يسجل هدف التعادل في الوقت القاتل!',
        type: 'breaking',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BreakingNewsTicker(overrideConfig: activeModel),
            ),
          ),
        ),
      );

      expect(find.text('عاجل'), findsOneWidget);
      expect(find.text('الأهلي يسجل هدف التعادل في الوقت القاتل!'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Verify Directionality is RTL
      final directionality = tester.widget<Directionality>(
        find.ancestor(
          of: find.text('عاجل'),
          matching: find.byType(Directionality),
        ).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });

    testWidgets('Renders warning badge for warning type', (tester) async {
      const warningModel = TickerConfigModel(
        enabled: true,
        text: 'تنويه: أعمال صيانة في السيرفرات بعد قليل',
        type: 'warning',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BreakingNewsTicker(overrideConfig: warningModel),
            ),
          ),
        ),
      );

      expect(find.text('تنبيه'), findsOneWidget);
      expect(find.text('تنويه: أعمال صيانة في السيرفرات بعد قليل'), findsOneWidget);
    });

    testWidgets('Renders info badge for info type', (tester) async {
      const infoModel = TickerConfigModel(
        enabled: true,
        text: 'تم تحديث جدول مباريات دوري أبطال أوروبا',
        type: 'info',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BreakingNewsTicker(overrideConfig: infoModel),
            ),
          ),
        ),
      );

      expect(find.text('معلومة'), findsOneWidget);
      expect(find.text('تم تحديث جدول مباريات دوري أبطال أوروبا'), findsOneWidget);
    });

    testWidgets('Tapping dismiss button hides ticker immediately', (tester) async {
      const dismissModel = TickerConfigModel(
        enabled: true,
        text: 'خبر سيتم إغلاقه يدوياً',
        type: 'breaking',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BreakingNewsTicker(overrideConfig: dismissModel),
            ),
          ),
        ),
      );

      expect(find.text('خبر سيتم إغلاقه يدوياً'), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(find.text('خبر سيتم إغلاقه يدوياً'), findsNothing);
    });

    testWidgets('Reduced motion: tap expands text without animation when disableAnimations is true', (tester) async {
      const longModel = TickerConfigModel(
        enabled: true,
        text: 'بيان عاجل ومفصل جداً يتجاوز سطراً واحداً للتأكد من قدرة المستخدم على قراءته بالكامل عند الضغط عليه',
        type: 'breaking',
      );

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: BreakingNewsTicker(overrideConfig: longModel),
              ),
            ),
          ),
        ),
      );

      final textWidgetBefore = tester.widget<Text>(find.text(longModel.text));
      expect(textWidgetBefore.maxLines, 1);

      // Tap to expand
      await tester.tap(find.text(longModel.text));
      await tester.pump();

      final textWidgetAfter = tester.widget<Text>(find.text(longModel.text));
      expect(textWidgetAfter.maxLines, 4);
    });
  });
}

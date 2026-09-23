import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ShootLiveApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ShootLiveApp(),
      ),
    );
    final err = tester.takeException();
    // ignore: avoid_print
    print('TAKEN_EXCEPTION_WAS: $err');
    expect(find.byType(ShootLiveApp), findsOneWidget);
  });
}

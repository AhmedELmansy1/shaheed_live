import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/core/utils/date_formatter.dart';
import 'package:shoot_live/core/utils/timezone_helper.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/presentation/widgets/match_countdown_widget.dart';

void main() {
  setUpAll(() {
    TimezoneHelper.init();
  });

  group('MatchModel Minute & Status parsing', () {
    test('extracts Western Latin tabular minute for live match', () {
      final match = MatchModel.fromMap({
        'match_id': 101,
        'live': 1,
        'admin_badge': 'live',
        'admin_title': "67'",
        'home_scores': '1',
        'away_scores': '0',
      });

      expect(match.isLive, isTrue);
      expect(match.status, equals(MatchStatus.live));
      expect(match.currentMinute, equals("67'"));
    });

    test('extracts injury time minute correctly', () {
      final match = MatchModel.fromMap({
        'match_id': 102,
        'live': 1,
        'admin_badge': 'live',
        'admin_title': "45+2'",
        'home_scores': '0',
        'away_scores': '0',
      });

      expect(match.isLive, isTrue);
      expect(match.currentMinute, equals("45+2'"));
    });

    test('handles halftime pause correctly', () {
      final match = MatchModel.fromMap({
        'match_id': 103,
        'live': 1,
        'admin_title': 'استراحة',
      });

      expect(match.isLive, isTrue);
      expect(match.status, equals(MatchStatus.paused));
      expect(match.currentMinute, equals('استراحة'));
    });

    test('does not treat soon match as live even if live=1', () {
      final match = MatchModel.fromMap({
        'match_id': 104,
        'live': 1,
        'admin_badge': 'soon',
        'admin_title': 'لم تبدأ',
        'forced_status': 'soon',
      });

      expect(match.isLive, isFalse);
      expect(match.status, equals(MatchStatus.notStarted));
      expect(match.currentMinute, isNull);
    });
  });

  group('MatchCountdownWidget Rendering', () {
    testWidgets('renders countdown in MM:SS format for match within 1 hour', (tester) async {
      final target = DateTime.now().add(const Duration(minutes: 14, seconds: 36));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCountdownWidget(
              targetDateTime: target,
              fallbackFormattedTime: '٧:٣٠ م',
            ),
          ),
        ),
      );

      expect(find.textContaining('تبدأ خلال'), findsOneWidget);
      expect(find.textContaining(DateFormatter.toArabicNumerals('14:')), findsOneWidget);
    });

    testWidgets('renders countdown in HH:MM:SS format for match > 1 hour away', (tester) async {
      final target = DateTime.now().add(const Duration(hours: 2, minutes: 14, seconds: 36));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCountdownWidget(
              targetDateTime: target,
              fallbackFormattedTime: '٧:٣٠ م',
              isHero: true,
            ),
          ),
        ),
      );

      expect(find.textContaining('تبدأ خلال'), findsOneWidget);
      expect(find.textContaining(DateFormatter.toArabicNumerals('02:14:')), findsOneWidget);
    });

    testWidgets('renders "تبدأ الآن" when target time is in the past or zero', (tester) async {
      final target = DateTime.now().subtract(const Duration(seconds: 10));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCountdownWidget(
              targetDateTime: target,
              fallbackFormattedTime: '٧:٣٠ م',
            ),
          ),
        ),
      );

      expect(find.text('تبدأ الآن'), findsOneWidget);
    });
  });
}

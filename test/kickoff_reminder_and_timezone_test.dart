import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/core/utils/date_formatter.dart';
import 'package:shoot_live/data/models/match_model.dart';

void main() {
  group('Kickoff Time Parsing & 12h/24h Resiliency', () {
    test('parseTimeComponents converts Arabic PM (م) correctly to 24h', () {
      final (hour, minute, _) = DateFormatter.parseTimeComponents('08:00 م');
      expect(hour, equals(20));
      expect(minute, equals(0));
    });

    test('parseTimeComponents converts Arabic AM (ص) correctly', () {
      final (hour, minute, _) = DateFormatter.parseTimeComponents('08:00 ص');
      expect(hour, equals(8));
      expect(minute, equals(0));
    });

    test('parseTimeComponents converts 12:00 PM (ظهر) correctly', () {
      final (hour, minute, _) = DateFormatter.parseTimeComponents('12:00 م');
      expect(hour, equals(12));
      expect(minute, equals(0));
    });

    test('parseTimeComponents converts 12:00 AM (منتصف الليل) correctly', () {
      final (hour, minute, _) = DateFormatter.parseTimeComponents('12:00 ص');
      expect(hour, equals(0));
      expect(minute, equals(0));
    });

    test('parseTimeComponents handles standard 24h format', () {
      final (hour, minute, _) = DateFormatter.parseTimeComponents('21:45');
      expect(hour, equals(21));
      expect(minute, equals(45));
    });

    test('parseTimeComponents handles English PM/AM', () {
      final (hourPm, minPm, _) = DateFormatter.parseTimeComponents('09:30 PM');
      expect(hourPm, equals(21));
      expect(minPm, equals(30));

      final (hourAm, minAm, _) = DateFormatter.parseTimeComponents('09:30 AM');
      expect(hourAm, equals(9));
      expect(minAm, equals(30));
    });

    test('parseTimeComponents returns (0, 0, 0) for invalid strings safely', () {
      expect(DateFormatter.parseTimeComponents(''), equals((0, 0, 0)));
      expect(DateFormatter.parseTimeComponents('TBD'), equals((0, 0, 0)));
      expect(DateFormatter.parseTimeComponents('غير محدد'), equals((0, 0, 0)));
    });
  });

  group('Remaining Kickoff Countdown Formatter', () {
    test('formatRemainingKickoff produces exact hours and minutes', () {
      final now = DateTime(2026, 11, 10, 18, 0);
      final kickoff = DateTime(2026, 11, 10, 20, 15);

      final text = DateFormatter.formatRemainingKickoff(kickoff, now: now);
      expect(text, equals('متبقي 2 س و 15 د'));
    });

    test('formatRemainingKickoff produces minutes only when under 1 hour', () {
      final now = DateTime(2026, 11, 10, 19, 15);
      final kickoff = DateTime(2026, 11, 10, 20, 0);

      final text = DateFormatter.formatRemainingKickoff(kickoff, now: now);
      expect(text, equals('متبقي 45 دقيقة'));
    });

    test('formatRemainingKickoff produces "تبدأ خلال لحظات" when less than 1 minute', () {
      final now = DateTime(2026, 11, 10, 19, 59, 30);
      final kickoff = DateTime(2026, 11, 10, 20, 0);

      final text = DateFormatter.formatRemainingKickoff(kickoff, now: now);
      expect(text, equals('تبدأ خلال لحظات'));
    });

    test('formatRemainingKickoff returns empty string if kickoff is past', () {
      final now = DateTime(2026, 11, 10, 20, 5);
      final kickoff = DateTime(2026, 11, 10, 20, 0);

      final text = DateFormatter.formatRemainingKickoff(kickoff, now: now);
      expect(text, isEmpty);
    });

    test('MatchModel remainingTimeUntilKickoff works properly for future match', () {
      final now = DateTime.now();
      final futureDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final futureHour = ((now.hour + 3) % 24).toString().padLeft(2, '0');

      final match = MatchModel(
        matchId: 999123,
        matchDate: futureDate,
        matchTime: '$futureHour:30:00',
        isLive: false,
        status: MatchStatus.notStarted,
        championship: const ChampionshipInfo(id: 1, title: 'دوري أبطال أوروبا'),
        homeTeam: const TeamInfo(rowId: 1, title: 'ريال مدريد'),
        awayTeam: const TeamInfo(rowId: 2, title: 'برشلونة'),
      );

      final countdown = match.remainingTimeUntilKickoff;
      // Depending on current time vs future, should be formatted
      expect(countdown, isNotNull);
      expect(countdown, contains('متبقي'));
    });
  });
}

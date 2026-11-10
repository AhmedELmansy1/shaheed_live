import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/data/models/match_event_model.dart';
import 'package:shoot_live/data/models/standings_model.dart';
import 'package:shoot_live/data/repositories/matches_repository.dart';

void main() {
  group('Standings Rank 0 Bug Fix', () {
    test('Correctly extracts 1-based ranks even when upstream API returns standing: 0', () {
      final mockData = {
        '1': {
          'standing': 0, // Upstream bug
          'last_stand': null,
          'team_name': {
            'title': 'ليفربول',
            'image': 'https://example.com/liverpool.png',
            'row_id': 14,
          },
          'play': '28',
          'wins': '20',
          'draw': '4',
          'lose': '4',
          'diff': '40',
          'points': '64',
        },
        '2': {
          'standing': 0, // Upstream bug
          'last_stand': null,
          'team_name': {
            'title': 'مانشستر سيتي',
            'image': 'https://example.com/city.png',
            'row_id': 11,
          },
          'play': '28',
          'wins': '19',
          'draw': '5',
          'lose': '4',
          'diff': '35',
          'points': '62',
        },
        '3': {
          'standing': 0, // Upstream bug
          'last_stand': null,
          'team_name': {
            'title': 'أرسنال',
            'image': 'https://example.com/arsenal.png',
            'row_id': 19,
          },
          'play': '28',
          'wins': '18',
          'draw': '7',
          'lose': '3',
          'diff': '38',
          'points': '61',
        },
      };

      final rows = StandingRowModel.fromResponse(mockData);
      expect(rows.length, 3);

      expect(rows[0].rank, 1);
      expect(rows[0].teamName, 'ليفربول');
      expect(rows[0].teamLogo, 'https://example.com/liverpool.png');
      expect(rows[0].points, 64);
      expect(rows[0].goalDiff, 40);

      expect(rows[1].rank, 2);
      expect(rows[1].teamName, 'مانشستر سيتي');
      expect(rows[1].points, 62);

      expect(rows[2].rank, 3);
      expect(rows[2].teamName, 'أرسنال');
      expect(rows[2].points, 61);
    });

    test('Ensures no rank is ever <= 0', () {
      final mockData = {
        '0': {
          'standing': 0,
          'name': 'فريق تجريبي',
          'play': '1',
          'wins': '1',
          'draw': '0',
          'lose': '0',
          'diff': '1',
          'points': '3',
        }
      };

      final rows = StandingRowModel.fromResponse(mockData);
      expect(rows.first.rank, 1);
    });
  });

  group('Events Timeline Deduplication & Reverse-Chronological Sorting', () {
    test('Deduplicates duplicate period markers and sorts reverse-chronologically', () {
      final fixtureFile = File('test/fixtures/raw_matches_event_5795507.json');
      expect(fixtureFile.existsSync(), isTrue, reason: 'Event fixture must exist');

      final rawJson = jsonDecode(fixtureFile.readAsStringSync());
      final events = ApiMatchesRepository.parseEvents(rawJson);

      expect(events.isNotEmpty, isTrue);

      // 1. Assert "انتهت المباراة" appears exactly once
      final ftMarkers = events.where(
        (e) => e.eventType == MatchEventType.periodMarker && e.statusName.contains('انتهت'),
      );
      expect(ftMarkers.length, 1, reason: 'Duplicate FT period marker must be deduplicated');

      // 2. Assert events are sorted reverse-chronological by sortMinute
      for (var i = 0; i < events.length - 1; i++) {
        final current = events[i];
        final next = events[i + 1];
        expect(
          current.sortMinute,
          greaterThanOrEqualTo(next.sortMinute),
          reason: 'Event "${current.statusName}" (${current.minute}\') at index $i must be >= "${next.statusName}" (${next.minute}\') at index ${i + 1}',
        );
      }

      // 3. First event should be Full Time period marker (sortMinute 9999)
      expect(events.first.eventType, MatchEventType.periodMarker);
      expect(events.first.statusName, contains('انتهت'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/data/models/match_stream_model.dart';

void main() {
  group('MatchStreamModel & StreamServerModel Tests', () {
    test('Parses PlayerType enum values correctly', () {
      expect(PlayerType.fromString('hls'), equals(PlayerType.hls));
      expect(PlayerType.fromString('m3u8'), equals(PlayerType.hls));
      expect(PlayerType.fromString('embed'), equals(PlayerType.embed));
      expect(PlayerType.fromString('iframe'), equals(PlayerType.embed));
      expect(PlayerType.fromString('external'), equals(PlayerType.external));
      expect(PlayerType.fromString('unknown'), equals(PlayerType.external));
      expect(PlayerType.fromString(null), equals(PlayerType.external));
    });

    test('Parses valid MatchStreamModel JSON correctly', () {
      final json = {
        'match_id': 123456,
        'is_enabled': true,
        'servers': [
          {
            'id': 'srv_2',
            'name': 'Server 2 - SD',
            'stream_url': 'https://example.com/stream2.m3u8',
            'player_type': 'hls',
            'is_active': true,
            'priority': 2,
          },
          {
            'id': 'srv_1',
            'name': 'Server 1 - HD',
            'stream_url': 'https://example.com/stream1.m3u8',
            'player_type': 'hls',
            'is_active': true,
            'priority': 1,
          },
        ],
      };

      final model = MatchStreamModel.fromMap(json);

      expect(model.matchId, equals(123456));
      expect(model.isEnabled, isTrue);
      expect(model.servers.length, equals(2));

      // Active servers should be sorted by priority ascending
      final active = model.activeServersSorted;
      expect(active.length, equals(2));
      expect(active[0].id, equals('srv_1'));
      expect(active[0].priority, equals(1));
      expect(active[1].id, equals('srv_2'));
      expect(active[1].priority, equals(2));
    });

    test('Filters inactive servers and empty stream URLs', () {
      final json = {
        'match_id': 999,
        'is_enabled': true,
        'servers': [
          {
            'id': 's1',
            'name': 'Active Server',
            'stream_url': 'https://example.com/stream.m3u8',
            'player_type': 'hls',
            'is_active': true,
            'priority': 1,
          },
          {
            'id': 's2',
            'name': 'Inactive Server',
            'stream_url': 'https://example.com/stream2.m3u8',
            'player_type': 'hls',
            'is_active': false,
            'priority': 2,
          },
          {
            'id': 's3',
            'name': 'Empty URL Server',
            'stream_url': '   ',
            'player_type': 'embed',
            'is_active': true,
            'priority': 3,
          },
        ],
      };

      final model = MatchStreamModel.fromMap(json);

      expect(model.servers.length, equals(3));
      final active = model.activeServersSorted;
      expect(active.length, equals(1));
      expect(active[0].id, equals('s1'));
    });

    test('Returns empty active servers when is_enabled is false', () {
      final json = {
        'match_id': 555,
        'is_enabled': false,
        'servers': [
          {
            'id': 's1',
            'name': 'Server 1',
            'stream_url': 'https://example.com/stream.m3u8',
            'player_type': 'hls',
            'is_active': true,
            'priority': 1,
          },
        ],
      };

      final model = MatchStreamModel.fromMap(json);

      expect(model.isEnabled, isFalse);
      expect(model.activeServersSorted, isEmpty);
      expect(model.hasActiveServers, isFalse);
    });

    test('Handles malformed and missing JSON safely without crashing', () {
      final json = <String, dynamic>{};

      final model = MatchStreamModel.fromMap(json, 777);

      expect(model.matchId, equals(777));
      expect(model.isEnabled, isTrue);
      expect(model.servers, isEmpty);
      expect(model.activeServersSorted, isEmpty);
    });

    test('Parses single direct stream_url field and enabled boolean correctly', () {
      final json = {
        'match_id': '4732635',
        'stream_url': 'https://912acsss8af382.sirtv.top/playerv5.php?match=4732635',
        'enabled': true,
      };

      final model = MatchStreamModel.fromMap(json);

      expect(model.matchId, equals(4732635));
      expect(model.isEnabled, isTrue);
      expect(model.servers.length, equals(1));
      expect(model.servers.first.streamUrl, equals('https://912acsss8af382.sirtv.top/playerv5.php?match=4732635'));
      expect(model.hasActiveServers, isTrue);
      expect(model.activeServersSorted.first.playerType, equals(PlayerType.embed));
    });

    test('Parses disabled single direct stream_url correctly', () {
      final json = {
        'match_id': 4732635,
        'stream_url': 'https://912acsss8af382.sirtv.top/playerv5.php?match=4732635',
        'enabled': false,
      };

      final model = MatchStreamModel.fromMap(json);

      expect(model.matchId, equals(4732635));
      expect(model.isEnabled, isFalse);
      expect(model.hasActiveServers, isFalse);
      expect(model.activeServersSorted, isEmpty);
    });
  });
}

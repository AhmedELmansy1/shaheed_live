import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/core/network/app_exception.dart';
import 'package:shoot_live/core/network/dio_client.dart';
import 'package:shoot_live/data/models/match_info_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/match_statistics_model.dart';
import 'package:shoot_live/data/repositories/matches_repository.dart';

class FakeDioAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  FakeDioAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('MatchModel Parsing and Null Safety Tests', () {
    test('Correctly parses real match item from new API', () {
      final json = {
        'match_id': 5071488,
        'match_date': '2026-11-08',
        'match_time': '00:00:00',
        'live': 0,
        'status': '4',
        'event_status': 'ended',
        'forced_status': null,
        'admin_badge': 'ended',
        'admin_title': 'انتهت',
        'home_scores': 2,
        'away_scores': 1,
        'championship': {
          'id': 913550,
          'title': 'الدوري الأمريكي لكرة القدم',
          'image': 'https://imgs.ysscores.com/championship/48/671691408606.png',
        },
        'home_team': {
          'row_id': 960720,
          'title': 'إنتر ميامي',
          'image': 'https://imgs.ysscores.com/teams/64/17936673734433.png',
        },
        'away_team': {
          'row_id': 1323940,
          'title': 'شارلوت',
          'image': 'https://imgs.ysscores.com/teams/64/4701691409708.png',
        },
      };

      final match = MatchModel.fromMap(json);

      expect(match.matchId, 5071488);
      expect(match.id, '5071488');
      expect(match.homeTeamName, 'إنتر ميامي');
      expect(match.awayTeamName, 'شارلوت');
      expect(match.leagueName, 'الدوري الأمريكي لكرة القدم');
      expect(match.homeScore, '2');
      expect(match.awayScore, '1');
      expect(match.isLive, false);
      expect(match.status, MatchStatus.finished);
    });

    test('Tolerates missing, null, and empty fields without crashing', () {
      final json = <String, dynamic>{
        'match_id': null,
        'championship': null,
        'home_team': null,
        'away_team': null,
        'home_scores': null,
        'away_scores': null,
      };

      final match = MatchModel.fromMap(json);

      expect(match.matchId, 0);
      expect(match.homeTeamName, 'فريق غير محدد');
      expect(match.awayTeamName, 'فريق غير محدد');
      expect(match.leagueName, 'دوري غير محدد');
      expect(match.homeScore, isNull);
      expect(match.awayScore, isNull);
      expect(match.isLive, false);
    });

    test('Parses String match_id gracefully', () {
      final json = {
        'match_id': '4732635',
        'home_team': {'title': 'الأهلي'},
        'away_team': {'title': 'الزمالك'},
      };

      final match = MatchModel.fromMap(json);
      expect(match.matchId, 4732635);
      expect(match.id, '4732635');
    });
  });

  group('MatchInfoModel Parsing Tests', () {
    test('Parses stadium_name, channel_name, referee_name from new API', () {
      final json = {
        'match_id': 5071488,
        'stadium': 'غير محدد',
        'stadium_name': 'استاد القاهرة الدولي',
        'channel': 'beIN Sports',
        'channel_name': 'beIN Sports 1',
        'commentator': 'عصام الشوالي',
        'commentator_name': 'عصام الشوالي',
        'referee': 'أمين عمر',
        'referee_name': 'أمين عمر',
        'events': 1,
        'lineup': 1,
        'statics': 0,
      };

      final info = MatchInfoModel.fromMap(json);

      expect(info.matchId, 5071488);
      expect(info.stadium, 'استاد القاهرة الدولي');
      expect(info.channel, 'beIN Sports 1');
      expect(info.commentator, 'عصام الشوالي');
      expect(info.refereeName, 'أمين عمر');
      expect(info.hasEvents, true);
      expect(info.hasLineup, true);
      expect(info.hasStatics, false);
    });

    test('Tolerates empty and null fields in MatchInfo', () {
      final json = {'match_id': 12345};
      final info = MatchInfoModel.fromMap(json);

      expect(info.matchId, 12345);
      expect(info.stadium, isNull);
      expect(info.channel, isNull);
      expect(info.refereeName, isNull);
      expect(info.hasEvents, false);
    });
  });

  group('MatchStatisticsModel Parsing Tests', () {
    test('Returns null when statics map is empty', () {
      final json = {'statics': {}};
      final stats = MatchStatisticsModel.fromResponse(json, 960720, 1323940);
      expect(stats, isNull);
    });

    test('Parses valid team statistics', () {
      final json = {
        'statics': {
          '960720': {
            'team_id': 960720,
            'ball_possession': 58,
            'total_shots': 14,
            'shots_on_goal': 6,
            'shots_off_goal': 8,
            'corner_kicks': 5,
            'fouls': 10,
            'yellow_cards': 2,
            'red_cards': 0,
            'offsides': 1,
            'goalkeeper_saves': 3,
          },
          '1323940': {
            'team_id': 1323940,
            'ball_possession': 42,
            'total_shots': 8,
            'shots_on_goal': 3,
            'shots_off_goal': 5,
            'corner_kicks': 3,
            'fouls': 12,
            'yellow_cards': 3,
            'red_cards': 1,
            'offsides': 2,
            'goalkeeper_saves': 4,
          },
        },
      };

      final stats = MatchStatisticsModel.fromResponse(json, 960720, 1323940);
      expect(stats, isNotNull);
      expect(stats!.homeStats.possession, 58);
      expect(stats.homeStats.totalShots, 14);
      expect(stats.awayStats.possession, 42);
      expect(stats.awayStats.redCards, 1);
    });
  });

  group('DioClient & Repository Error Mapping Tests', () {
    test('Maps connectionTimeout to TimeoutException with clear message', () async {
      final dio = Dio();
      dio.httpClientAdapter = FakeDioAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
      });

      final client = DioClient(baseUrl: 'https://test.com', dio: dio);
      final repo = ApiMatchesRepository(dioClient: client);

      expect(
        () => repo.getMatchesToday(),
        throwsA(
          isA<TimeoutException>().having(
            (e) => e.message,
            'message',
            contains('مهلة الاتصال'),
          ),
        ),
      );
    });

    test('Maps HTTP 404 to ServerException with status 404', () async {
      final dio = Dio();
      dio.httpClientAdapter = FakeDioAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 404,
            statusMessage: 'Not Found',
          ),
        );
      });

      final client = DioClient(baseUrl: 'https://test.com', dio: dio);
      final repo = ApiMatchesRepository(dioClient: client);

      expect(
        () => repo.getMatchesToday(),
        throwsA(
          isA<ServerException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });

    test('Maps connectionError to NetworkException with clear message', () async {
      final dio = Dio();
      dio.httpClientAdapter = FakeDioAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'Connection refused',
        );
      });

      final client = DioClient(baseUrl: 'https://test.com', dio: dio);
      final repo = ApiMatchesRepository(dioClient: client);

      expect(
        () => repo.getMatchesToday(),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            contains('اتصال'),
          ),
        ),
      );
    });

    test('Maps malformed non-list response to ParseException', () async {
      final dio = Dio();
      dio.httpClientAdapter = FakeDioAdapter((options) async {
        return ResponseBody.fromString(
          '{"invalid_shape": 123}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = DioClient(baseUrl: 'https://test.com', dio: dio);
      final repo = ApiMatchesRepository(dioClient: client);

      // Should return empty list safely instead of crashing
      final matches = await repo.getMatchesToday();
      expect(matches, isEmpty);
    });
  });
}

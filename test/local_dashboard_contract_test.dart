import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/network/dio_client.dart';
import 'package:shoot_live/data/repositories/matches_repository.dart';
import 'package:shoot_live/data/repositories/onboarding_repository.dart';

class RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = RealHttpOverrides();
  const localUrl = 'http://localhost:3000/api/matches';

  group('Data Layer Contract Tests against Local Dashboard ($localUrl)', () {
    late DioClient dioClient;
    late ApiMatchesRepository matchesRepo;
    late ApiOnboardingRepository onboardingRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      dioClient = DioClient(baseUrl: localUrl);
      matchesRepo = ApiMatchesRepository(dioClient: dioClient);
      onboardingRepo = ApiOnboardingRepository(dioClient: dioClient);
    });

    test('1. matches_by_date returns HTTP 200 and parses matches', () async {
      try {
        final res = await dioClient.dioInstance.get(
          '',
          queryParameters: {'type': 'matches_by_date', 'date': '2026-11-09'},
        );
        expect(res.statusCode, 200);
        print('[Contract] GET matches_by_date: HTTP ${res.statusCode}');
        
        final matches = await matchesRepo.getMatchesByDate('2026-11-09', forceRefresh: true);
        print('           MatchesRepository parsed ${matches.length} matches');
        expect(matches, isNotNull);
      } on DioException catch (e) {
        print('DIO EXCEPTION DATA: ${e.response?.data}');
        print('DIO REQUEST URI: ${e.requestOptions.uri}');
        rethrow;
      }
    });

    test('2. match_info returns HTTP 200 and parses metadata', () async {
      final res = await dioClient.dioInstance.get(
        '',
        queryParameters: {'type': 'match_info', 'id': 5795507},
      );
      expect(res.statusCode, 200);
      print('[Contract] GET match_info (5795507): HTTP ${res.statusCode}');

      final info = await matchesRepo.getMatchInfo('5795507', forceRefresh: true);
      print('           MatchesRepository match_info: stadium=${info?.stadium}');
      expect(info, isNotNull);
    });

    test('3. statics_match returns HTTP 200 and parses statistics', () async {
      final res = await dioClient.dioInstance.get(
        '',
        queryParameters: {'type': 'statics_match', 'id': 5795507},
      );
      expect(res.statusCode, 200);
      print('[Contract] GET statics_match (5795507): HTTP ${res.statusCode}');

      final stats = await matchesRepo.getMatchStatistics(
        '5795507',
        homeTeamId: 9826,
        awayTeamId: 8650,
        forceRefresh: true,
      );
      print('           MatchesRepository stats: possession home=${stats?.homeStats.possession}%, away=${stats?.awayStats.possession}%');
      expect(stats, isNotNull);
    });

    test('4. matches_event returns HTTP 200 and parses timeline events', () async {
      final res = await dioClient.dioInstance.get(
        '',
        queryParameters: {'type': 'matches_event', 'id': 5795507},
      );
      expect(res.statusCode, 200);
      print('[Contract] GET matches_event (5795507): HTTP ${res.statusCode}');

      final events = await matchesRepo.getMatchEvents('5795507', forceRefresh: true);
      print('           MatchesRepository parsed ${events.length} timeline events');
      expect(events, isNotNull);
    });

    test('5. matches_lineup returns HTTP 200 and parses lineups', () async {
      final res = await dioClient.dioInstance.get(
        '',
        queryParameters: {'type': 'matches_lineup', 'id': 5795507},
      );
      expect(res.statusCode, 200);
      print('[Contract] GET matches_lineup (5795507): HTTP ${res.statusCode}');

      final lineup = await matchesRepo.getMatchLineup(
        '5795507',
        homeTeamId: 9826,
        awayTeamId: 8650,
        forceRefresh: true,
      );
      print('           MatchesRepository parsed lineups: home starters=${lineup?.homeLineup.startingXI.length}, away starters=${lineup?.awayLineup.startingXI.length}');
      expect(lineup, isNotNull);
    });

    test('6. leagues returns HTTP 200 and parses popular leagues', () async {
      final res = await dioClient.dioInstance.get(
        '',
        queryParameters: {'type': 'leagues'},
      );
      expect(res.statusCode, 200);
      print('[Contract] GET leagues: HTTP ${res.statusCode}');

      final leagues = await onboardingRepo.getPopularLeagues(forceRefresh: true);
      print('           OnboardingRepository parsed ${leagues.length} primary leagues');
      expect(leagues, isNotEmpty);
    });

    test('7. teams returns HTTP 200 and parses catalog teams', () async {
      final res = await dioClient.dioInstance.get(
        '',
        queryParameters: {'type': 'teams'},
      );
      expect(res.statusCode, 200);
      print('[Contract] GET teams (catalog): HTTP ${res.statusCode}');

      final teams = await onboardingRepo.getPopularTeams(forceRefresh: true);
      print('           OnboardingRepository parsed ${teams.length} catalog teams');
      expect(teams, isNotNull);
    });

    test('8. teams by league returns HTTP 200 and parses teams for league', () async {
      final res = await dioClient.dioInstance.get(
        '',
        queryParameters: {'type': 'teams', 'league_id': 937599},
      );
      expect(res.statusCode, 200);
      print('[Contract] GET teams (league 937599): HTTP ${res.statusCode}');

      final leagueTeams = await onboardingRepo.getTeamsByLeagueId('937599', forceRefresh: true);
      print('           OnboardingRepository parsed ${leagueTeams.length} teams for Premier League (937599)');
      expect(leagueTeams, isNotEmpty);
    });

    test('9. matches_today / tomorrow / yesterday / live return HTTP 200', () async {
      final todayRes = await dioClient.dioInstance.get('', queryParameters: {'type': 'matches_today'});
      expect(todayRes.statusCode, 200);
      print('[Contract] GET matches_today: HTTP ${todayRes.statusCode}');

      final tomRes = await dioClient.dioInstance.get('', queryParameters: {'type': 'matches_tomorrow'});
      expect(tomRes.statusCode, 200);
      print('[Contract] GET matches_tomorrow: HTTP ${tomRes.statusCode}');

      final yestRes = await dioClient.dioInstance.get('', queryParameters: {'type': 'matches_yesterday'});
      expect(yestRes.statusCode, 200);
      print('[Contract] GET matches_yesterday: HTTP ${yestRes.statusCode}');

      final liveRes = await dioClient.dioInstance.get('', queryParameters: {'type': 'matches_live'});
      expect(liveRes.statusCode, 200);
      print('[Contract] GET matches_live: HTTP ${liveRes.statusCode}');
    });
  });
}

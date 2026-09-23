import '../models/match_event_model.dart';
import '../models/match_info_model.dart';
import '../models/match_lineup_model.dart';
import '../models/match_model.dart';
import '../models/match_statistics_model.dart';
import '../../core/network/dio_client.dart';

/// Repository contract for retrieving live and scheduled football matches and match details.
abstract class MatchesRepository {
  /// Fetches matches using server-bucketed `matches_today` endpoint.
  Future<List<MatchModel>> getMatchesToday();

  /// Fetches matches using server-bucketed `matches_tomorrow` endpoint.
  Future<List<MatchModel>> getMatchesTomorrow();

  /// Fetches matches using server-bucketed `matches_yesterday` endpoint.
  Future<List<MatchModel>> getMatchesYesterday();

  /// Fetches matches for a specific local date string (`YYYY-MM-DD`).
  Future<List<MatchModel>> getMatchesByDate(String date);

  /// Fetches detailed match metadata (`type=match_info&id={matchId}`).
  Future<MatchInfoModel?> getMatchInfo(String matchId);

  /// Fetches match statistics (`type=statics_match&id={matchId}`).
  Future<MatchStatisticsModel?> getMatchStatistics(
    String matchId, {
    required dynamic homeTeamId,
    required dynamic awayTeamId,
  });

  /// Fetches match events timeline (`type=matches_event&id={matchId}`).
  Future<List<MatchEventModel>> getMatchEvents(String matchId);

  /// Fetches match lineups (`type=matches_lineup&id={matchId}`).
  Future<MatchLineupModel?> getMatchLineup(
    String matchId, {
    required dynamic homeTeamId,
    required dynamic awayTeamId,
  });
}

/// Concrete implementation of [MatchesRepository] hitting Worker API endpoints.
///
/// CODE COMMENT NOTE ON ENDPOINTS:
/// While `getMatchesToday`, `getMatchesTomorrow`, and `getMatchesYesterday` are
/// preserved here for completeness, the Home Screen tab logic calls [getMatchesByDate]
/// with locally-computed date strings (`YYYY-MM-DD`). This guarantees that users across
/// all timezones see matches bucketed according to their own local calendar day.
class ApiMatchesRepository implements MatchesRepository {
  final DioClient dioClient;

  ApiMatchesRepository({required this.dioClient});

  @override
  Future<List<MatchModel>> getMatchesToday() async {
    return _fetchMatches({'type': 'matches_today'});
  }

  @override
  Future<List<MatchModel>> getMatchesTomorrow() async {
    return _fetchMatches({'type': 'matches_tomorrow'});
  }

  @override
  Future<List<MatchModel>> getMatchesYesterday() async {
    return _fetchMatches({'type': 'matches_yesterday'});
  }

  @override
  Future<List<MatchModel>> getMatchesByDate(String date) async {
    return _fetchMatches({
      'type': 'matches_by_date',
      'date': date,
    });
  }

  @override
  Future<MatchInfoModel?> getMatchInfo(String matchId) async {
    final responseData = await dioClient.get(queryParameters: {
      'type': 'match_info',
      'id': matchId,
    });

    if (responseData is Map<String, dynamic> && responseData.isNotEmpty) {
      return MatchInfoModel.fromMap(responseData);
    }
    return null;
  }

  @override
  Future<MatchStatisticsModel?> getMatchStatistics(
    String matchId, {
    required dynamic homeTeamId,
    required dynamic awayTeamId,
  }) async {
    final responseData = await dioClient.get(queryParameters: {
      'type': 'statics_match',
      'id': matchId,
    });

    return MatchStatisticsModel.fromResponse(responseData, homeTeamId, awayTeamId);
  }

  @override
  Future<List<MatchEventModel>> getMatchEvents(String matchId) async {
    final responseData = await dioClient.get(queryParameters: {
      'type': 'matches_event',
      'id': matchId,
    });

    if (responseData is Map<String, dynamic>) {
      final eventsList = responseData['events'];
      if (eventsList is List) {
        return eventsList
            .whereType<Map<String, dynamic>>()
            .map((item) => MatchEventModel.fromMap(item))
            .toList();
      }
    } else if (responseData is List) {
      return responseData
          .whereType<Map<String, dynamic>>()
          .map((item) => MatchEventModel.fromMap(item))
          .toList();
    }
    return [];
  }

  @override
  Future<MatchLineupModel?> getMatchLineup(
    String matchId, {
    required dynamic homeTeamId,
    required dynamic awayTeamId,
  }) async {
    final responseData = await dioClient.get(queryParameters: {
      'type': 'matches_lineup',
      'id': matchId,
    });

    return MatchLineupModel.fromResponse(responseData, homeTeamId, awayTeamId);
  }

  Future<List<MatchModel>> _fetchMatches(Map<String, dynamic> params) async {
    final responseData = await dioClient.get(queryParameters: params);
    if (responseData is List) {
      return responseData
          .map((item) => MatchModel.fromMap(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

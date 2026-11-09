import '../cache/matches_cache_service.dart';
import '../models/match_event_model.dart';
import '../models/match_info_model.dart';
import '../models/match_lineup_model.dart';
import '../models/match_model.dart';
import '../models/match_statistics_model.dart';
import '../../core/network/dio_client.dart';

/// Repository contract for retrieving live and scheduled football matches and match details.
abstract class MatchesRepository {
  /// Fetches matches using server-bucketed `matches_today` endpoint.
  Future<List<MatchModel>> getMatchesToday({bool forceRefresh = false});

  /// Fetches matches using server-bucketed `matches_tomorrow` endpoint.
  Future<List<MatchModel>> getMatchesTomorrow({bool forceRefresh = false});

  /// Fetches matches using server-bucketed `matches_yesterday` endpoint.
  Future<List<MatchModel>> getMatchesYesterday({bool forceRefresh = false});

  /// Fetches matches for a specific local date string (`YYYY-MM-DD`).
  Future<List<MatchModel>> getMatchesByDate(String date, {bool forceRefresh = false});

  /// Fetches detailed match metadata (`type=match_info&id={matchId}`).
  Future<MatchInfoModel?> getMatchInfo(String matchId, {bool forceRefresh = false});

  /// Fetches match statistics (`type=statics_match&id={matchId}`).
  Future<MatchStatisticsModel?> getMatchStatistics(
    String matchId, {
    required dynamic homeTeamId,
    required dynamic awayTeamId,
    bool forceRefresh = false,
  });

  /// Fetches match events timeline (`type=matches_event&id={matchId}`).
  Future<List<MatchEventModel>> getMatchEvents(String matchId, {bool forceRefresh = false});

  /// Fetches match lineups (`type=matches_lineup&id={matchId}`).
  Future<MatchLineupModel?> getMatchLineup(
    String matchId, {
    required dynamic homeTeamId,
    required dynamic awayTeamId,
    bool forceRefresh = false,
  });
}

/// Concrete implementation of [MatchesRepository] hitting Worker API endpoints
/// backed by [MatchesCacheService] for Stale-While-Revalidate caching.
class ApiMatchesRepository implements MatchesRepository {
  final DioClient dioClient;
  final MatchesCacheService? cacheService;

  ApiMatchesRepository({
    required this.dioClient,
    this.cacheService,
  });

  @override
  Future<List<MatchModel>> getMatchesToday({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final todayStr =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    return getMatchesByDate(todayStr, forceRefresh: forceRefresh);
  }

  @override
  Future<List<MatchModel>> getMatchesTomorrow({bool forceRefresh = false}) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowStr =
        "${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";
    return getMatchesByDate(tomorrowStr, forceRefresh: forceRefresh);
  }

  @override
  Future<List<MatchModel>> getMatchesYesterday({bool forceRefresh = false}) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr =
        "${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
    return getMatchesByDate(yesterdayStr, forceRefresh: forceRefresh);
  }

  @override
  Future<List<MatchModel>> getMatchesByDate(String date, {bool forceRefresh = false}) async {
    // 1. If not forcing refresh, return valid fresh cache immediately
    if (!forceRefresh && cacheService != null) {
      final cached = cacheService!.getCachedMatches(date);
      if (cached != null && !cached.isExpired) {
        return cached.matches;
      }
    }

    // 2. Fetch fresh from network
    try {
      final responseData = await dioClient.get(
        queryParameters: {'type': 'matches_by_date', 'date': date},
      );
      // Persist to local cache
      if (cacheService != null && responseData != null) {
        await cacheService!.saveMatches(date, responseData);
      }
      return _parseMatches(responseData);
    } catch (e) {
      // 3. Fallback on network failure: serve stale cached data if present
      if (cacheService != null) {
        final stale = cacheService!.getCachedMatches(date);
        if (stale != null && stale.matches.isNotEmpty) {
          return stale.matches;
        }
      }
      rethrow;
    }
  }

  @override
  Future<MatchInfoModel?> getMatchInfo(String matchId, {bool forceRefresh = false}) async {
    if (!forceRefresh && cacheService != null) {
      final cached = cacheService!.getCachedMatchInfo(matchId);
      if (cached != null) return cached;
    }

    try {
      final responseData = await dioClient.get(
        queryParameters: {'type': 'match_info', 'id': matchId},
      );

      if (responseData is Map<String, dynamic> && responseData.isNotEmpty) {
        if (cacheService != null) {
          await cacheService!.saveMatchInfo(matchId, responseData);
        }
        return MatchInfoModel.fromMap(responseData);
      }
      return null;
    } catch (e) {
      if (cacheService != null) {
        final fallback = cacheService!.getCachedMatchInfo(matchId);
        if (fallback != null) return fallback;
      }
      rethrow;
    }
  }

  @override
  Future<MatchStatisticsModel?> getMatchStatistics(
    String matchId, {
    required dynamic homeTeamId,
    required dynamic awayTeamId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && cacheService != null) {
      final cached = cacheService!.getCachedMatchStatistics(
        matchId,
        homeTeamId,
        awayTeamId,
      );
      if (cached != null) return cached;
    }

    try {
      final responseData = await dioClient.get(
        queryParameters: {'type': 'statics_match', 'id': matchId},
      );

      if (cacheService != null && responseData != null) {
        await cacheService!.saveMatchStatistics(matchId, responseData);
      }

      return MatchStatisticsModel.fromResponse(
        responseData,
        homeTeamId,
        awayTeamId,
      );
    } catch (e) {
      if (cacheService != null) {
        final fallback = cacheService!.getCachedMatchStatistics(
          matchId,
          homeTeamId,
          awayTeamId,
        );
        if (fallback != null) return fallback;
      }
      rethrow;
    }
  }

  @override
  Future<List<MatchEventModel>> getMatchEvents(String matchId, {bool forceRefresh = false}) async {
    if (!forceRefresh && cacheService != null) {
      final cached = cacheService!.getCachedMatchEvents(matchId);
      if (cached != null) return cached;
    }

    try {
      final responseData = await dioClient.get(
        queryParameters: {'type': 'matches_event', 'id': matchId},
      );

      if (cacheService != null && responseData != null) {
        await cacheService!.saveMatchEvents(matchId, responseData);
      }

      return _parseEvents(responseData);
    } catch (e) {
      if (cacheService != null) {
        final fallback = cacheService!.getCachedMatchEvents(matchId);
        if (fallback != null) return fallback;
      }
      rethrow;
    }
  }

  @override
  Future<MatchLineupModel?> getMatchLineup(
    String matchId, {
    required dynamic homeTeamId,
    required dynamic awayTeamId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && cacheService != null) {
      final cached = cacheService!.getCachedMatchLineup(
        matchId,
        homeTeamId,
        awayTeamId,
      );
      if (cached != null) return cached;
    }

    try {
      final responseData = await dioClient.get(
        queryParameters: {'type': 'matches_lineup', 'id': matchId},
      );

      if (cacheService != null && responseData != null) {
        await cacheService!.saveMatchLineup(matchId, responseData);
      }

      return MatchLineupModel.fromResponse(responseData, homeTeamId, awayTeamId);
    } catch (e) {
      if (cacheService != null) {
        final fallback = cacheService!.getCachedMatchLineup(
          matchId,
          homeTeamId,
          awayTeamId,
        );
        if (fallback != null) return fallback;
      }
      rethrow;
    }
  }

  List<MatchModel> _parseMatches(dynamic responseData) {
    if (responseData is List) {
      return responseData
          .whereType<Map<String, dynamic>>()
          .map((item) => MatchModel.fromMap(item))
          .toList();
    } else if (responseData is Map<String, dynamic>) {
      final list = responseData['data'] ?? responseData['matches'];
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => MatchModel.fromMap(item))
            .toList();
      }
    }
    return [];
  }

  List<MatchEventModel> _parseEvents(dynamic responseData) {
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
}

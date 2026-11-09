import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/match_model.dart';
import '../models/match_info_model.dart';
import '../models/match_event_model.dart';
import '../models/match_lineup_model.dart';
import '../models/match_statistics_model.dart';

/// Represents a cached match result with metadata regarding staleness.
class MatchesCacheResult {
  final List<MatchModel> matches;
  final DateTime cachedAt;
  final bool isExpired;

  const MatchesCacheResult({
    required this.matches,
    required this.cachedAt,
    required this.isExpired,
  });
}

/// Service providing local persistence and TTL-based caching for matches and match details.
///
/// Implements the Stale-While-Revalidate pattern:
/// - Today matches: 2-minute TTL (live score updates).
/// - Future matches: 30-minute TTL (schedule adjustments).
/// - Finished / past matches: 24-hour TTL (immutable scores/outcomes).
class MatchesCacheService {
  final SharedPreferences prefs;

  MatchesCacheService({required this.prefs});

  static MatchesCacheService? _instance;

  /// Returns the already instantiated singleton if available.
  static MatchesCacheService? get currentInstance => _instance;

  /// Returns the singleton or a newly initialized [MatchesCacheService].
  static Future<MatchesCacheService> getInstance() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = MatchesCacheService(prefs: prefs);
    return _instance!;
  }

  static const String _prefixMatches = 'cache_matches_v2_';
  static const String _prefixInfo = 'cache_info_v2_';
  static const String _prefixEvents = 'cache_events_v2_';
  static const String _prefixStats = 'cache_stats_v2_';
  static const String _prefixLineup = 'cache_lineup_v2_';

  /// Determines the TTL duration based on target date string (YYYY-MM-DD).
  Duration getTtlForDate(String dateStr) {
    try {
      final now = DateTime.now();
      final todayStr =
          "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      if (dateStr == todayStr) {
        return const Duration(minutes: 2);
      }

      final targetDate = DateTime.tryParse(dateStr);
      if (targetDate != null) {
        final todayStart = DateTime(now.year, now.month, now.day);
        if (targetDate.isBefore(todayStart)) {
          return const Duration(hours: 24);
        } else {
          return const Duration(minutes: 30);
        }
      }
    } catch (_) {}
    return const Duration(minutes: 2);
  }

  /// Saves raw API matches response to local storage with timestamp.
  Future<void> saveMatches(String dateStr, dynamic rawData) async {
    try {
      final key = '$_prefixMatches$dateStr';
      final payload = {
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'data': rawData,
      };
      await prefs.setString(key, jsonEncode(payload));
    } catch (e) {
      debugPrint('[MatchesCache] Error saving matches cache for $dateStr: $e');
    }
  }

  /// Retrieves cached matches for [dateStr], if available.
  MatchesCacheResult? getCachedMatches(String dateStr) {
    try {
      final key = '$_prefixMatches$dateStr';
      final rawJson = prefs.getString(key);
      if (rawJson == null || rawJson.isEmpty) return null;

      final Map<String, dynamic> decoded = jsonDecode(rawJson);
      final timestamp = decoded['cached_at'] as int?;
      final rawData = decoded['data'];

      if (timestamp == null || rawData == null) return null;

      final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final ttl = getTtlForDate(dateStr);
      final isExpired = DateTime.now().difference(cachedAt) > ttl;

      List<MatchModel> matches = [];
      if (rawData is List) {
        matches = rawData
            .whereType<Map<String, dynamic>>()
            .map((item) => MatchModel.fromMap(item))
            .toList();
      } else if (rawData is Map<String, dynamic>) {
        final list = rawData['data'] ?? rawData['matches'];
        if (list is List) {
          matches = list
              .whereType<Map<String, dynamic>>()
              .map((item) => MatchModel.fromMap(item))
              .toList();
        }
      }

      if (matches.isEmpty) return null;

      return MatchesCacheResult(
        matches: matches,
        cachedAt: cachedAt,
        isExpired: isExpired,
      );
    } catch (e) {
      debugPrint('[MatchesCache] Error reading cache for $dateStr: $e');
      return null;
    }
  }

  /// Invalidates the cache for a given date (used during pull-to-refresh).
  Future<void> invalidateMatches(String dateStr) async {
    try {
      final key = '$_prefixMatches$dateStr';
      await prefs.remove(key);
    } catch (e) {
      debugPrint('[MatchesCache] Error invalidating matches for $dateStr: $e');
    }
  }

  // ---------------- Match Details Caches ----------------

  Future<void> saveMatchInfo(String matchId, Map<String, dynamic> data) async {
    try {
      final key = '$_prefixInfo$matchId';
      final payload = {
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };
      await prefs.setString(key, jsonEncode(payload));
    } catch (_) {}
  }

  MatchInfoModel? getCachedMatchInfo(String matchId) {
    try {
      final key = '$_prefixInfo$matchId';
      final rawJson = prefs.getString(key);
      if (rawJson == null) return null;
      final decoded = jsonDecode(rawJson);
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return MatchInfoModel.fromMap(data);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveMatchEvents(String matchId, dynamic data) async {
    try {
      final key = '$_prefixEvents$matchId';
      final payload = {
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };
      await prefs.setString(key, jsonEncode(payload));
    } catch (_) {}
  }

  List<MatchEventModel>? getCachedMatchEvents(String matchId) {
    try {
      final key = '$_prefixEvents$matchId';
      final rawJson = prefs.getString(key);
      if (rawJson == null) return null;
      final decoded = jsonDecode(rawJson);
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final list = data['events'];
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map((e) => MatchEventModel.fromMap(e))
              .toList();
        }
      } else if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((e) => MatchEventModel.fromMap(e))
            .toList();
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveMatchStatistics(String matchId, dynamic data) async {
    try {
      final key = '$_prefixStats$matchId';
      final payload = {
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };
      await prefs.setString(key, jsonEncode(payload));
    } catch (_) {}
  }

  MatchStatisticsModel? getCachedMatchStatistics(
    String matchId,
    dynamic homeTeamId,
    dynamic awayTeamId,
  ) {
    try {
      final key = '$_prefixStats$matchId';
      final rawJson = prefs.getString(key);
      if (rawJson == null) return null;
      final decoded = jsonDecode(rawJson);
      return MatchStatisticsModel.fromResponse(
        decoded['data'],
        homeTeamId,
        awayTeamId,
      );
    } catch (_) {}
    return null;
  }

  Future<void> saveMatchLineup(String matchId, dynamic data) async {
    try {
      final key = '$_prefixLineup$matchId';
      final payload = {
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };
      await prefs.setString(key, jsonEncode(payload));
    } catch (_) {}
  }

  MatchLineupModel? getCachedMatchLineup(
    String matchId,
    dynamic homeTeamId,
    dynamic awayTeamId,
  ) {
    try {
      final key = '$_prefixLineup$matchId';
      final rawJson = prefs.getString(key);
      if (rawJson == null) return null;
      final decoded = jsonDecode(rawJson);
      return MatchLineupModel.fromResponse(
        decoded['data'],
        homeTeamId,
        awayTeamId,
      );
    } catch (_) {}
    return null;
  }
}

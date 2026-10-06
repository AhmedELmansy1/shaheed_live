import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/match_model.dart';

/// Lightweight Hive-based cache for matches & leagues.
/// - No codegen, pure JSON strings.
/// - Graceful fallback: if Hive not ready, all ops are no-ops.
class CacheService {
  static const String _matchesBoxName = 'matches_cache_v1';
  static const String _metaBoxName = 'meta_cache_v1';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Hive.initFlutter();
      await Hive.openBox<String>(_matchesBoxName);
      await Hive.openBox<String>(_metaBoxName);
      _initialized = true;
      debugPrint('[CacheService] Hive initialized.');
    } catch (e) {
      debugPrint('[CacheService] Init failed (non-fatal): $e');
    }
  }

  Box<String>? get _matchesBox =>
      _initialized ? Hive.box<String>(_matchesBoxName) : null;
  Box<String>? get _metaBox =>
      _initialized ? Hive.box<String>(_metaBoxName) : null;

  // --- Matches per date (YYYY-MM-DD) ---

  Future<void> saveMatchesForDate(
    String dateStr,
    List<MatchModel> matches,
  ) async {
    try {
      final box = _matchesBox;
      if (box == null) return;
      // Serialize via toMap-like minimal representation using MatchModel.fromMap reverse
      // We store the raw API list as JSON strings if available; here we store lightweight maps.
      final list = matches
          .map(
            (m) => {
              'match_id': m.matchId,
              'match_date': m.matchDate,
              'match_time': m.matchTime,
              'live': m.isLive ? 1 : 0,
              'admin_badge': m.adminBadge,
              'admin_title': m.adminTitle,
              'event_status': m.eventStatus,
              'championship': {
                'id': m.championship.id,
                'title': m.championship.title,
                'image': m.championship.image,
              },
              'home_team': {
                'row_id': m.homeTeam.rowId,
                'title': m.homeTeam.title,
                'image': m.homeTeam.image,
              },
              'away_team': {
                'row_id': m.awayTeam.rowId,
                'title': m.awayTeam.title,
                'image': m.awayTeam.image,
              },
              'home_scores': m.homeScore,
              'away_scores': m.awayScore,
            },
          )
          .toList();
      await box.put(dateStr, jsonEncode(list));
      await _metaBox?.put(
        'last_cache_$dateStr',
        DateTime.now().toIso8601String(),
      );
      debugPrint(
        '[CacheService] Cached ${matches.length} matches for $dateStr',
      );
    } catch (e) {
      debugPrint('[CacheService] saveMatchesForDate error: $e');
    }
  }

  List<MatchModel> getCachedMatchesForDate(String dateStr) {
    try {
      final box = _matchesBox;
      if (box == null) return [];
      final raw = box.get(dateStr);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((m) => MatchModel.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint('[CacheService] getCachedMatchesForDate error: $e');
      return [];
    }
  }

  DateTime? getLastCacheTime(String dateStr) {
    try {
      final raw = _metaBox?.get('last_cache_$dateStr');
      if (raw == null) return null;
      return DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  bool isCacheFresh(
    String dateStr, {
    Duration maxAge = const Duration(minutes: 2),
  }) {
    final t = getLastCacheTime(dateStr);
    if (t == null) return false;
    return DateTime.now().difference(t) < maxAge;
  }

  Future<void> clearAll() async {
    try {
      await _matchesBox?.clear();
      await _metaBox?.clear();
    } catch (e) {
      debugPrint('[CacheService] clearAll error: $e');
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/match_model.dart';
import '../../data/models/team_model.dart';

/// Mapping layer that resolves onboarding team slugs (e.g. 'barcelona', 'real_madrid')
/// to real API team `row_id` integers (e.g. 8634, 8633), ensuring FCM subscriptions
/// subscribe to `team_{apiRowId}` matching the watcher's FCM push conditions.
class TeamResolverService {
  static const String _storageKey = 'team_slug_to_api_row_id';

  /// Pre-seeded mappings for verified clubs from API responses.
  static const Map<String, int> _seededMappings = {
    'real_madrid': 8633,
    'barcelona': 8634,
    'atletico_madrid': 9906,
    'villarreal': 10205,
    'real_betis': 8603,
    'athletic_bilbao': 8315,
    'arsenal': 9825,
    'man_city': 8456,
    'liverpool': 8650,
    'man_utd': 10260,
    'chelsea': 8455,
    'tottenham': 8586,
    'aston_villa': 10252,
    'newcastle': 10261,
    'dortmund': 9789,
    'bayern_munich': 9823,
    'leverkusen': 8178,
    'inter': 8636,
    'milan': 8564,
    'juventus': 9885,
    'fiorentina': 8535,
    'napoli': 9875,
    'roma': 8686,
    'lazio': 8543,
    'atalanta': 8524,
    'monaco': 9829,
    'marseille': 8592,
    'ahly': 102008,
    'zamalek': 102009,
    'hilal': 102769,
    'nassr': 102770,
  };

  static Map<String, int>? _memoryCache;

  /// Loads all mappings from SharedPreferences merged with pre-seeded mappings.
  static Future<Map<String, int>> getMappings() async {
    if (_memoryCache != null) return _memoryCache!;
    final map = Map<String, int>.from(_seededMappings);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final val = int.tryParse(entry.value.toString());
          if (val != null) map[entry.key] = val;
        }
      }
    } catch (e) {
      debugPrint('[TeamResolver] Error loading cached team mappings: $e');
    }
    _memoryCache = map;
    return map;
  }

  /// Resolves a single team ID or slug to its integer API `row_id`.
  /// Returns immediately if already numeric.
  static Future<int?> resolveToApiRowId(String teamIdOrSlug) async {
    final asInt = int.tryParse(teamIdOrSlug.trim());
    if (asInt != null) return asInt;
    final mappings = await getMappings();
    return mappings[teamIdOrSlug.trim().toLowerCase()];
  }

  /// Dynamically updates mappings by matching Arabic and English team names
  /// from fetched API matches against known [allTeams].
  static Future<void> updateMappingsFromMatches(
    List<MatchModel> matches,
    List<TeamModel> allTeams,
  ) async {
    if (matches.isEmpty || allTeams.isEmpty) return;
    final current = await getMappings();
    bool changed = false;

    for (final match in matches) {
      void checkTeam(int? rowId, String title) {
        if (rowId == null || title.trim().isEmpty) return;
        final tLower = title.trim().toLowerCase();
        for (final t in allTeams) {
          if (current.containsKey(t.id)) continue;
          final name = t.name.trim().toLowerCase();
          final nameEn = t.nameEn.trim().toLowerCase();
          if (name.isNotEmpty &&
              (tLower.contains(name) || name.contains(tLower))) {
            current[t.id] = rowId;
            changed = true;
          } else if (nameEn.isNotEmpty &&
              (tLower.contains(nameEn) || nameEn.contains(tLower))) {
            current[t.id] = rowId;
            changed = true;
          }
        }
      }

      checkTeam(match.homeTeam.rowId, match.homeTeam.title);
      checkTeam(match.awayTeam.rowId, match.awayTeam.title);
    }

    if (changed) {
      _memoryCache = current;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageKey, jsonEncode(current));
        debugPrint(
          '[TeamResolver] Updated cached team mappings (${current.length} mapped).',
        );
      } catch (e) {
        debugPrint('[TeamResolver] Error persisting team mappings: $e');
      }
    }
  }
}

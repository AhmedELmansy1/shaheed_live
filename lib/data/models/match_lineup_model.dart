/// Data model for single lineup player node or substitute.
class LineupPlayer {
  final dynamic id;
  final String name;
  final int number;
  final String? position; // e.g. "G", "D", "M", "F" or "G", "D", "C", "A"
  final String? positionTitle; // Arabic position title if provided
  final bool isSubstitute;

  const LineupPlayer({
    required this.id,
    required this.name,
    required this.number,
    this.position,
    this.positionTitle,
    this.isSubstitute = false,
  });

  factory LineupPlayer.fromMap(Map<String, dynamic> map, {bool isSubstitute = false}) {
    int parseNum(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    String extractName() {
      final candidates = [
        map['short_title'],
        map['player_name'],
        map['name'],
        map['title'],
        map['name_ar'],
        map['player_short_name'],
        map['short_name'],
        map['ar_name'],
        map['player_title'],
        map['nickname'],
        if (map['player'] is Map) ...[
          map['player']['short_title'],
          map['player']['name'],
          map['player']['title'],
          map['player']['player_name'],
        ],
      ];

      for (final candidate in candidates) {
        if (candidate != null) {
          final trimmed = candidate.toString().trim();
          if (trimmed.isNotEmpty && trimmed != 'null') {
            return trimmed;
          }
        }
      }
      return 'لاعب';
    }

    return LineupPlayer(
      id: map['player_id'] ?? map['id'] ?? map['person_id'] ?? 0,
      name: extractName(),
      number: parseNum(
        map['shirt_number'] ??
            map['number'] ??
            map['shirt_no'] ??
            map['jersey_number'] ??
            map['num'],
      ),
      position: (map['pos'] ?? map['position'] ?? map['pos_short'] ?? map['position_short'])?.toString(),
      positionTitle: (map['pos_title'] ?? map['position_name'] ?? map['pos_name'])?.toString(),
      isSubstitute: isSubstitute,
    );
  }
}

/// Lineup data for a single team.
class TeamLineupData {
  final String? formation;
  final String? coach;
  final List<LineupPlayer> startingXI;
  final List<LineupPlayer> substitutes;

  const TeamLineupData({
    this.formation,
    this.coach,
    this.startingXI = const [],
    this.substitutes = const [],
  });
}

/// Data model for match lineup endpoint (`type=matches_lineup&id={id}`).
///
/// REAL API RESPONSE FIELDS (Empirically Verified):
/// - `data["0"]` contains formation & coach metadata (`home_formation`, `away_formation`, `home_coach`, `away_coach`).
/// - `data["lineup"]` contains `{ "{home_team_id}": {"lineup": [...], "substitutions": [...]}, ... }`.
/// - Upcoming matches return `"data": {}` (empty map). Parsing safely returns `null`.
class MatchLineupModel {
  final TeamLineupData homeLineup;
  final TeamLineupData awayLineup;

  const MatchLineupModel({
    required this.homeLineup,
    required this.awayLineup,
  });

  static MatchLineupModel? fromResponse(dynamic data, dynamic homeTeamId, dynamic awayTeamId) {
    if (data == null || data is! Map<String, dynamic> || data.isEmpty) return null;

    // Extract metadata from "0" object if available
    final meta = data['0'] as Map<String, dynamic>?;
    final homeFormation = meta?['home_formation']?.toString();
    final awayFormation = meta?['away_formation']?.toString();

    String? extractCoach(dynamic raw) {
      if (raw == null) return null;
      if (raw is Map<String, dynamic>) {
        return (raw['title'] ?? raw['name'])?.toString();
      }
      return raw.toString();
    }

    final homeCoach = extractCoach(meta?['home_coach']);
    final awayCoach = extractCoach(meta?['away_coach']);

    final lineupMap = data['lineup'];
    if (lineupMap == null || lineupMap is! Map<String, dynamic>) {
      return null;
    }

    final homeKey = homeTeamId.toString();
    final awayKey = awayTeamId.toString();

    Map<String, dynamic>? homeTeamObj = lineupMap[homeKey] as Map<String, dynamic>?;
    Map<String, dynamic>? awayTeamObj = lineupMap[awayKey] as Map<String, dynamic>?;

    // Fallback if keys don't match exactly
    if (homeTeamObj == null && lineupMap.values.isNotEmpty) {
      homeTeamObj = lineupMap.values.first as Map<String, dynamic>?;
    }
    if (awayTeamObj == null && lineupMap.values.length > 1) {
      awayTeamObj = lineupMap.values.last as Map<String, dynamic>?;
    }

    List<LineupPlayer> parseList(dynamic rawList, {bool isSubstitute = false}) {
      if (rawList == null || rawList is! List) return [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((m) => LineupPlayer.fromMap(m, isSubstitute: isSubstitute))
          .toList();
    }

    final homeXI = parseList(homeTeamObj?['lineup']);
    final homeSubs = parseList(homeTeamObj?['substitutions'], isSubstitute: true);

    final awayXI = parseList(awayTeamObj?['lineup']);
    final awaySubs = parseList(awayTeamObj?['substitutions'], isSubstitute: true);

    return MatchLineupModel(
      homeLineup: TeamLineupData(
        formation: homeFormation,
        coach: homeCoach,
        startingXI: homeXI,
        substitutes: homeSubs,
      ),
      awayLineup: TeamLineupData(
        formation: awayFormation,
        coach: awayCoach,
        startingXI: awayXI,
        substitutes: awaySubs,
      ),
    );
  }
}

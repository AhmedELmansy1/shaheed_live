import 'package:flutter/foundation.dart';

/// Data model for single lineup player node or substitute.
class LineupPlayer {
  final dynamic id;
  final String name;
  final int number;
  final String? position; // e.g. "G", "D", "M", "F" or "G", "D", "C", "A"
  final String? positionTitle; // Arabic position title if provided
  final String? photoUrl;
  final bool isSubstitute;

  const LineupPlayer({
    required this.id,
    required this.name,
    required this.number,
    this.position,
    this.positionTitle,
    this.photoUrl,
    this.isSubstitute = false,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]} ${parts[1][0]}';
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0];
    }
    return '$number';
  }

  factory LineupPlayer.fromMap(
    Map<String, dynamic> map, {
    bool isSubstitute = false,
  }) {
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

    String? extractImage() {
      dynamic img =
          map['image'] ??
          map['photo'] ??
          map['photo_url'] ??
          map['player_photo'] ??
          map['player_image'] ??
          map['img'] ??
          map['avatar'] ??
          map['player_avatar'] ??
          map['pic'] ??
          map['picture'] ??
          map['logo'] ??
          map['person_image'] ??
          (map['player'] is Map
              ? (map['player']['image'] ??
                  map['player']['photo'] ??
                  map['player']['photo_url'] ??
                  map['player']['player_photo'] ??
                  map['player']['player_image'] ??
                  map['player']['avatar'] ??
                  map['player']['player_avatar'] ??
                  map['player']['img'] ??
                  map['player']['pic'])
              : null) ??
          (map['person'] is Map
              ? (map['person']['image'] ??
                  map['person']['photo'] ??
                  map['person']['photo_url'] ??
                  map['person']['avatar'] ??
                  map['person']['img'])
              : null);
      if (img != null) {
        final str = img.toString().trim();
        if (str.isNotEmpty && str != 'null') {
          if (str.startsWith('http://') || str.startsWith('https://')) {
            return str;
          }
          return 'https://imgs.ysscores.com/players/128/$str';
        }
      }
      return null;
    }

    final parsedPhoto = extractImage();
    final playerName = extractName();
    final playerNum = parseNum(
      map['shirt_number'] ??
          map['number'] ??
          map['shirt_no'] ??
          map['jersey_number'] ??
          map['num'] ??
          (map['player'] is Map ? map['player']['player_number'] : null),
    );

    if (isSubstitute) {
      debugPrint(
        '[LineupPlayer] Substitute: "$playerName" (#$playerNum) photo: $parsedPhoto',
      );
    }

    return LineupPlayer(
      id: map['player_id'] ?? map['id'] ?? map['person_id'] ?? 0,
      name: playerName,
      number: playerNum,
      position:
          (map['pos'] ??
                  map['position'] ??
                  map['pos_short'] ??
                  map['position_short'] ??
                  (map['player'] is Map ? map['player']['position'] : null))
              ?.toString(),
      positionTitle:
          (map['pos_title'] ?? map['position_name'] ?? map['pos_name'])
              ?.toString(),
      photoUrl: parsedPhoto,
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
class MatchLineupModel {
  final TeamLineupData homeLineup;
  final TeamLineupData awayLineup;

  const MatchLineupModel({required this.homeLineup, required this.awayLineup});

  static MatchLineupModel? fromResponse(
    dynamic data,
    dynamic homeTeamId,
    dynamic awayTeamId,
  ) {
    if (data == null || data is! Map<String, dynamic> || data.isEmpty) {
      return null;
    }

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

    Map<String, dynamic>? homeTeamObj =
        lineupMap[homeKey] as Map<String, dynamic>?;
    Map<String, dynamic>? awayTeamObj =
        lineupMap[awayKey] as Map<String, dynamic>?;

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
    final homeSubs = parseList(
      homeTeamObj?['substitutions'] ??
          homeTeamObj?['substitutes'] ??
          homeTeamObj?['subs'] ??
          homeTeamObj?['bench'],
      isSubstitute: true,
    );

    final awayXI = parseList(awayTeamObj?['lineup']);
    final awaySubs = parseList(
      awayTeamObj?['substitutions'] ??
          awayTeamObj?['substitutes'] ??
          awayTeamObj?['subs'] ??
          awayTeamObj?['bench'],
      isSubstitute: true,
    );

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

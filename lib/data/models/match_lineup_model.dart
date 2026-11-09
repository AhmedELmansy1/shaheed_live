import 'package:flutter/foundation.dart';

import '../../data/api/match_score_api.dart' as api;

/// Data model for single lineup player node or substitute.
class LineupPlayer {
  final dynamic id;
  final String name;
  final int number;
  final String? position;
  final String? positionTitle;
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

  /// Creates a [LineupPlayer] from an [api.LineupPlayer] parsed by [api.LineupParser].
  /// Uses the initials fallback from [api.LineupPlayer.initials] when no photo is available.
  factory LineupPlayer.fromApiPlayer(
    api.LineupPlayer p, {
    bool isSubstitute = false,
  }) {
    if (isSubstitute) {
      debugPrint(
        '[LineupPlayer] Substitute: "${p.displayName}" (#${p.number}) photo: ${p.imageUrl}',
      );
    }
    return LineupPlayer(
      id: p.id,
      name: p.displayName.isNotEmpty ? p.displayName : (p.name.isNotEmpty ? p.name : 'لاعب'),
      number: p.number,
      position: p.position,
      positionTitle: null,
      // '' means no photo → caller shows initials avatar via p.initials
      photoUrl: p.imageUrl.isNotEmpty ? p.imageUrl : null,
      isSubstitute: isSubstitute,
    );
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

  /// Parses lineup response by delegating to [api.LineupParser.parse].
  /// Falls back to null when the lineup is not announced.
  static MatchLineupModel? fromResponse(
    dynamic data,
    dynamic homeTeamId,
    dynamic awayTeamId,
  ) {
    if (data == null) return null;

    final matchLineup = api.LineupParser.parse(
      data,
      homeId: int.tryParse(homeTeamId.toString()),
      awayId: int.tryParse(awayTeamId.toString()),
    );

    if (matchLineup == null) return null;

    return MatchLineupModel(
      homeLineup: TeamLineupData(
        formation: matchLineup.home.formation,
        coach: matchLineup.home.coach.isNotEmpty ? matchLineup.home.coach : null,
        startingXI: matchLineup.home.starters
            .map((p) => LineupPlayer.fromApiPlayer(p))
            .toList(),
        substitutes: matchLineup.home.substitutes
            .map((p) => LineupPlayer.fromApiPlayer(p, isSubstitute: true))
            .toList(),
      ),
      awayLineup: TeamLineupData(
        formation: matchLineup.away.formation,
        coach: matchLineup.away.coach.isNotEmpty ? matchLineup.away.coach : null,
        startingXI: matchLineup.away.starters
            .map((p) => LineupPlayer.fromApiPlayer(p))
            .toList(),
        substitutes: matchLineup.away.substitutes
            .map((p) => LineupPlayer.fromApiPlayer(p, isSubstitute: true))
            .toList(),
      ),
    );
  }
}

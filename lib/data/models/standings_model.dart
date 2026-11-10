/// Model representing a team's standing row in a league table,
/// built strictly from real fields returned by YsScores `get_league_rank`.
class StandingRowModel {
  final int rank;
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDiff;
  final int points;
  final String? color;

  const StandingRowModel({
    required this.rank,
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDiff,
    required this.points,
    this.color,
  });

  StandingRowModel copyWith({
    int? rank,
    int? teamId,
    String? teamName,
    String? teamLogo,
    int? played,
    int? won,
    int? drawn,
    int? lost,
    int? goalsFor,
    int? goalsAgainst,
    int? goalDiff,
    int? points,
    String? color,
  }) {
    return StandingRowModel(
      rank: rank ?? this.rank,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamLogo: teamLogo ?? this.teamLogo,
      played: played ?? this.played,
      won: won ?? this.won,
      drawn: drawn ?? this.drawn,
      lost: lost ?? this.lost,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      goalDiff: goalDiff ?? this.goalDiff,
      points: points ?? this.points,
      color: color ?? this.color,
    );
  }

  factory StandingRowModel.fromMap(Map<String, dynamic> map, {int? fallbackRank}) {
    final teamNameObj = map['team_name'];
    String title = '';
    String? logo;

    if (teamNameObj is Map<String, dynamic>) {
      title = (teamNameObj['title'] ?? teamNameObj['short_title'] ?? teamNameObj['full_title'] ?? '').toString();
      logo = teamNameObj['image']?.toString();
    } else {
      title = (map['name'] ?? '').toString();
    }

    if (logo == null || logo.isEmpty) {
      logo = map['image']?.toString() ?? map['logo']?.toString() ?? map['team_logo']?.toString();
    }

    // Upstream API often returns standing: 0 and last_stand: null; real rank is fallbackRank (map key)
    final parsedStanding = int.tryParse(map['standing']?.toString() ?? '');
    final parsedLastStand = int.tryParse(map['last_stand']?.toString() ?? '');
    final parsedRank = (parsedLastStand != null && parsedLastStand > 0)
        ? parsedLastStand
        : ((parsedStanding != null && parsedStanding > 0)
            ? parsedStanding
            : (fallbackRank != null && fallbackRank > 0 ? fallbackRank : 0));

    final teamId = int.tryParse(map['team_id']?.toString() ?? '') ??
        (teamNameObj is Map ? int.tryParse(teamNameObj['row_id']?.toString() ?? '') : null) ??
        0;

    return StandingRowModel(
      rank: parsedRank,
      teamId: teamId,
      teamName: title.isNotEmpty ? title : (map['name']?.toString() ?? 'فريق'),
      teamLogo: logo,
      played: int.tryParse(map['play']?.toString() ?? '') ?? 0,
      won: int.tryParse(map['wins']?.toString() ?? '') ?? 0,
      drawn: int.tryParse(map['draw']?.toString() ?? '') ?? 0,
      lost: int.tryParse(map['lose']?.toString() ?? '') ?? 0,
      goalsFor: int.tryParse(map['for']?.toString() ?? '') ?? 0,
      goalsAgainst: int.tryParse(map['against']?.toString() ?? '') ?? 0,
      goalDiff: int.tryParse(map['diff']?.toString() ?? '') ?? 0,
      points: int.tryParse(map['points']?.toString() ?? '') ?? 0,
      color: map['color']?.toString(),
    );
  }

  /// Parses raw JSON response from `get_league_rank` into sorted [StandingRowModel] list.
  static List<StandingRowModel> fromResponse(dynamic data) {
    if (data == null) return [];

    final rows = <StandingRowModel>[];

    void parseMapOfRows(Map<String, dynamic> rowMap) {
      for (final entry in rowMap.entries) {
        if (entry.value is Map<String, dynamic>) {
          final rankFromKey = int.tryParse(entry.key);
          rows.add(
            StandingRowModel.fromMap(
              entry.value as Map<String, dynamic>,
              fallbackRank: rankFromKey,
            ),
          );
        }
      }
    }

    if (data is Map<String, dynamic>) {
      final listMatch = data['list_match'];
      if (listMatch is List && listMatch.isNotEmpty) {
        for (final item in listMatch) {
          if (item is Map<String, dynamic>) {
            // Can be "1": {row}, "2": {row} or a direct row
            if (item.containsKey('team_id') || item.containsKey('play')) {
              rows.add(StandingRowModel.fromMap(item));
            } else {
              parseMapOfRows(item);
            }
          }
        }
      } else if (data.containsKey('team_id') || data.containsKey('play')) {
        rows.add(StandingRowModel.fromMap(data));
      } else if (data.keys.any((k) => int.tryParse(k.toString()) != null)) {
        parseMapOfRows(data);
      }
    } else if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          if (item.containsKey('team_id') || item.containsKey('play')) {
            rows.add(StandingRowModel.fromMap(item));
          } else {
            parseMapOfRows(item);
          }
        }
      }
    }

    rows.sort((a, b) {
      if (a.rank != b.rank && a.rank > 0 && b.rank > 0) {
        return a.rank.compareTo(b.rank);
      }
      return b.points.compareTo(a.points);
    });

    // Ensure strictly positive 1-based ranks (if rank is 0, assign index + 1)
    final sanitizedRows = <StandingRowModel>[];
    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      if (r.rank <= 0) {
        sanitizedRows.add(r.copyWith(rank: i + 1));
      } else {
        sanitizedRows.add(r);
      }
    }

    return sanitizedRows;
  }
}

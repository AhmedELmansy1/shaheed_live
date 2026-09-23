/// Single team's statistics payload.
class TeamStats {
  final dynamic teamId;
  final int possession;
  final int totalShots;
  final int shotsOnGoal;
  final int shotsOffGoal;
  final int corners;
  final int fouls;
  final int yellowCards;
  final int redCards;
  final int offsides;
  final int saves;

  const TeamStats({
    required this.teamId,
    this.possession = 0,
    this.totalShots = 0,
    this.shotsOnGoal = 0,
    this.shotsOffGoal = 0,
    this.corners = 0,
    this.fouls = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.offsides = 0,
    this.saves = 0,
  });

  factory TeamStats.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return TeamStats(
      teamId: map['team_id'],
      possession: parseInt(map['ball_possession']),
      totalShots: parseInt(map['total_shots']),
      shotsOnGoal: parseInt(map['shots_on_goal']),
      shotsOffGoal: parseInt(map['shots_off_goal']),
      corners: parseInt(map['corner_kicks']),
      fouls: parseInt(map['fouls']),
      yellowCards: parseInt(map['yellow_cards']),
      redCards: parseInt(map['red_cards']),
      offsides: parseInt(map['offsides']),
      saves: parseInt(map['goalkeeper_saves']),
    );
  }
}

/// Data model for match statistics endpoint (`type=statics_match&id={id}`).
///
/// REAL API RESPONSE FIELDS (Empirically Verified):
/// - Data payload is `{"statics": {"{home_team_id}": {...}, "{away_team_id}": {...}}}`.
/// - Upcoming matches return `"data": []` (empty list). The parser safely returns `null`.
class MatchStatisticsModel {
  final TeamStats homeStats;
  final TeamStats awayStats;

  const MatchStatisticsModel({
    required this.homeStats,
    required this.awayStats,
  });

  static MatchStatisticsModel? fromResponse(dynamic data, dynamic homeTeamId, dynamic awayTeamId) {
    if (data == null || data is! Map<String, dynamic>) return null;

    final staticsMap = data['statics'];
    if (staticsMap == null || staticsMap is! Map<String, dynamic>) return null;

    final homeKey = homeTeamId.toString();
    final awayKey = awayTeamId.toString();

    final homeMap = staticsMap[homeKey] as Map<String, dynamic>? ??
        staticsMap.values.firstOrNull as Map<String, dynamic>?;

    final awayMap = staticsMap[awayKey] as Map<String, dynamic>? ??
        staticsMap.values.lastOrNull as Map<String, dynamic>?;

    if (homeMap == null || awayMap == null) return null;

    return MatchStatisticsModel(
      homeStats: TeamStats.fromMap(homeMap),
      awayStats: TeamStats.fromMap(awayMap),
    );
  }
}

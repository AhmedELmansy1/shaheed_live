/// Recent match encounter or outcome representation
class RecentMatchOutcome {
  final String title;
  final String result; // 'win', 'draw', 'lose'

  const RecentMatchOutcome({required this.title, required this.result});

  factory RecentMatchOutcome.fromMap(Map<String, dynamic> map) {
    return RecentMatchOutcome(
      title: (map['title'] ?? '').toString(),
      result: (map['result'] ?? 'draw').toString(),
    );
  }
}

/// Team recent form and head-to-head statistics
class TeamFormModel {
  final String teamName;
  final int wins;
  final int draws;
  final int losses;
  final List<RecentMatchOutcome> recentMatches;

  const TeamFormModel({
    required this.teamName,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.recentMatches,
  });

  factory TeamFormModel.fromMap(Map<String, dynamic> map) {
    final rawMatches = map['recent_matches'] as List<dynamic>? ?? [];
    return TeamFormModel(
      teamName: (map['team_name'] ?? '').toString(),
      wins: int.tryParse(map['wins']?.toString() ?? '') ?? 0,
      draws: int.tryParse(map['draws']?.toString() ?? '') ?? 0,
      losses: int.tryParse(map['losses']?.toString() ?? '') ?? 0,
      recentMatches: rawMatches
          .whereType<Map<String, dynamic>>()
          .map((m) => RecentMatchOutcome.fromMap(m))
          .toList(),
    );
  }
}

/// Data model for match information endpoint (`type=match_info&id={id}`).
///
/// Supports all historical and new field variations from Worker/Next.js backend:
/// - `stadium` / `stadium_name` / `Stadium`
/// - `referees` / `referee_name` / `referee`
/// - `channel` / `channel_name`
/// - `commentator` / `commentator_name`
/// - `round`
/// - `championship` / `championship_title` / `championship_image`
/// - `events`, `lineup`, `statics`: Flags or integers.
/// - `home_form`, `away_form`: Recent 5 matches and form history.
class MatchInfoModel {
  final int matchId;
  final String? stadium;
  final String? refereeName;
  final String? round;
  final String? championshipTitle;
  final String? championshipImage;
  final String? channel;
  final String? commentator;
  final bool hasEvents;
  final bool hasLineup;
  final bool hasStatics;
  final TeamFormModel? homeForm;
  final TeamFormModel? awayForm;
  final String? kickoffAt;
  final String? kickoffTzSource;

  /// Known unannounced, empty, or placeholder strings from upstream feeds and dashboards.
  static const Set<String> knownPlaceholders = {
    '',
    '-',
    '--',
    '---',
    '----',
    '—',
    'null',
    'undefined',
    'غير محدد',
    'التفاصيل',
    'تفاصيل',
    'معلومات',
    'لا يوجد',
    'لم يحدد',
  };

  /// Evaluates whether a raw string is empty, null, or a recognized placeholder.
  static bool isPlaceholder(String? val) {
    if (val == null) return true;
    final clean = val.trim().toLowerCase();
    return knownPlaceholders.contains(clean);
  }

  const MatchInfoModel({
    required this.matchId,
    this.stadium,
    this.refereeName,
    this.round,
    this.championshipTitle,
    this.championshipImage,
    this.channel,
    this.commentator,
    this.hasEvents = false,
    this.hasLineup = false,
    this.hasStatics = false,
    this.homeForm,
    this.awayForm,
    this.kickoffAt,
    this.kickoffTzSource,
  });

  factory MatchInfoModel.fromMap(Map<String, dynamic> map) {
    final champ = map['championship'] as Map<String, dynamic>?;
    final refs = map['referees'] as Map<String, dynamic>?;

    String? cleanString(dynamic v) {
      if (v == null) return null;
      final str = v.toString().trim();
      if (isPlaceholder(str)) return null;
      return str;
    }

    int parseId(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    bool parseFlag(dynamic v) {
      if (v == 1 || v == true || v == '1' || v == 'true') return true;
      return false;
    }

    return MatchInfoModel(
      matchId: parseId(map['match_id'] ?? map['id']),
      stadium: cleanString(map['stadium']) ??
          cleanString(map['stadium_name']) ??
          cleanString(map['Stadium']),
      refereeName: cleanString(refs?['title']) ??
          cleanString(map['referee_name']) ??
          cleanString(map['referee']),
      round: cleanString(map['round']),
      championshipTitle: cleanString(champ?['title']) ??
          cleanString(map['championship_title']),
      championshipImage: cleanString(champ?['image']) ??
          cleanString(map['championship_image']),
      channel: cleanString(map['channel_name']) ??
          cleanString(map['channel']),
      commentator: cleanString(map['commentator_name']) ??
          cleanString(map['commentator']),
      hasEvents: parseFlag(map['events']),
      hasLineup: parseFlag(map['lineup']),
      hasStatics: parseFlag(map['statics']),
      homeForm: map['home_form'] is Map<String, dynamic>
          ? TeamFormModel.fromMap(map['home_form'] as Map<String, dynamic>)
          : null,
      awayForm: map['away_form'] is Map<String, dynamic>
          ? TeamFormModel.fromMap(map['away_form'] as Map<String, dynamic>)
          : null,
      kickoffAt: (map['kickoff_at'] ?? map['kickoffAt'])?.toString().trim(),
      kickoffTzSource:
          (map['kickoff_tz_source'] ?? map['kickoffTzSource'])?.toString().trim(),
    );
  }
}

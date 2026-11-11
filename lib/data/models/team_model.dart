/// Data model representing a football club or team.
class TeamModel {
  final String id;
  final String name;
  final String nameEn;
  final String? logoUrl;
  final String leagueId;

  const TeamModel({
    required this.id,
    required this.name,
    required this.nameEn,
    this.logoUrl,
    required this.leagueId,
  });

  factory TeamModel.fromMap(Map<String, dynamic> map) {
    final rawLogo = map['logo_url'] ?? map['logo'] ?? map['image'];
    return TeamModel(
      id: (map['id'] ?? map['row_id'] ?? map['team_id'] ?? '').toString(),
      name: (map['name'] ?? map['title'] ?? map['team_name'] ?? '').toString(),
      nameEn: (map['name_en'] ?? '').toString(),
      logoUrl: (rawLogo != null && rawLogo.toString().trim().isNotEmpty && rawLogo.toString().trim() != 'null')
          ? rawLogo.toString().trim()
          : null,
      leagueId: (map['league_id'] ?? map['champ_id'] ?? '').toString(),
    );
  }

  /// Tolerantly parses teams from either a plain [List] or an envelope [Map]
  /// like `{"teams": [...]}` or `{"data": [...]}`.
  static List<TeamModel> fromListOrMap(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(TeamModel.fromMap)
          .toList();
    }
    if (raw is Map) {
      final list = raw['teams'] ?? raw['data'];
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(TeamModel.fromMap)
            .toList();
      }
    }
    return const [];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'logo_url': logoUrl,
      'league_id': leagueId,
    };
  }
}

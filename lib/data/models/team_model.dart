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
    return TeamModel(
      id: (map['id'] ?? map['row_id'] ?? '').toString(),
      name: (map['name'] ?? map['title'] ?? '').toString(),
      nameEn: (map['name_en'] ?? '').toString(),
      logoUrl: (map['logo_url'] ?? map['logo'] ?? map['image']) as String?,
      leagueId: (map['league_id'] ?? map['champ_id'] ?? '').toString(),
    );
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

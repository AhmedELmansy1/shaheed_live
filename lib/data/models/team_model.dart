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
      id: map['id'] as String,
      name: map['name'] as String,
      nameEn: map['name_en'] as String,
      logoUrl: map['logo_url'] as String?,
      leagueId: map['league_id'] as String,
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

/// Data model representing a football league or competition.
class LeagueModel {
  final String id;
  final String name;
  final String nameEn;
  final String? logoUrl;
  final String country;

  const LeagueModel({
    required this.id,
    required this.name,
    required this.nameEn,
    this.logoUrl,
    required this.country,
  });

  factory LeagueModel.fromMap(Map<String, dynamic> map) {
    return LeagueModel(
      id: map['id'] as String,
      name: map['name'] as String,
      nameEn: map['name_en'] as String,
      logoUrl: map['logo_url'] as String?,
      country: map['country'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'logo_url': logoUrl,
      'country': country,
    };
  }
}

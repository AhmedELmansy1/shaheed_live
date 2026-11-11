/// Data model representing a football league or competition.
class LeagueModel {
  final String id;
  final String name;
  final String nameEn;
  final String? logoUrl;
  final String country;
  final bool isPopular;
  final int displayOrder;

  const LeagueModel({
    required this.id,
    required this.name,
    required this.nameEn,
    this.logoUrl,
    required this.country,
    this.isPopular = false,
    this.displayOrder = 100,
  });

  factory LeagueModel.fromMap(Map<String, dynamic> map) {
    final rawLogo = map['logo_url'] ?? map['logo'] ?? map['image'];
    return LeagueModel(
      id: (map['id'] ?? map['champ_id'] ?? '').toString(),
      name: (map['name'] ?? map['title'] ?? '').toString(),
      nameEn: (map['name_en'] ?? map['slug'] ?? '').toString(),
      logoUrl: (rawLogo != null && rawLogo.toString().trim().isNotEmpty && rawLogo.toString().trim() != 'null')
          ? rawLogo.toString().trim()
          : null,
      country: (map['country'] ?? 'أخرى').toString(),
      isPopular: map['is_popular'] == true,
      displayOrder: map['display_order'] is num
          ? (map['display_order'] as num).toInt()
          : (int.tryParse(map['display_order']?.toString() ?? '') ?? 100),
    );
  }

  /// Tolerantly parses leagues from either a plain [List] or an envelope [Map]
  /// like `{"leagues": [...]}` or `{"data": [...]}`.
  static List<LeagueModel> fromListOrMap(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(LeagueModel.fromMap)
          .toList();
    }
    if (raw is Map) {
      final list = raw['leagues'] ?? raw['data'];
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(LeagueModel.fromMap)
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
      'country': country,
      'is_popular': isPopular,
      'display_order': displayOrder,
    };
  }
}

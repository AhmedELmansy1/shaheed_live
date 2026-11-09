/// Model representing a news article associated with a match,
/// built strictly from real fields returned by YsScores `get_match_news`.
class MatchNewsItemModel {
  final int id;
  final String title;
  final String? slug;
  final String description;
  final String? imageUrl;
  final String? date;
  final String? link;

  const MatchNewsItemModel({
    required this.id,
    required this.title,
    this.slug,
    required this.description,
    this.imageUrl,
    this.date,
    this.link,
  });

  factory MatchNewsItemModel.fromMap(Map<String, dynamic> map) {
    String? parsedDate;
    final rawDate = map['created_at'];
    if (rawDate is Map<String, dynamic>) {
      parsedDate = rawDate['date']?.toString();
    } else if (rawDate is String) {
      parsedDate = rawDate;
    }

    return MatchNewsItemModel(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      title: (map['title'] ?? '').toString(),
      slug: map['slug']?.toString(),
      description: (map['news_desc'] ?? map['desc'] ?? '').toString(),
      imageUrl: map['image']?.toString(),
      date: parsedDate,
      link: map['link']?.toString(),
    );
  }

  /// Parses raw JSON response from `get_match_news` into a list of [MatchNewsItemModel].
  static List<MatchNewsItemModel> fromResponse(dynamic data) {
    if (data == null) return [];

    final list = <MatchNewsItemModel>[];

    if (data is Map<String, dynamic>) {
      final items = data['items'];
      if (items is List) {
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            list.add(MatchNewsItemModel.fromMap(item));
          }
        }
      }
    } else if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          list.add(MatchNewsItemModel.fromMap(item));
        }
      }
    }

    return list;
  }
}

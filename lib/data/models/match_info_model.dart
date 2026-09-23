/// Data model for match information endpoint (`type=match_info&id={id}`).
///
/// REAL API RESPONSE FIELDS (Empirically Verified):
/// - `Stadium`: String stadium name (e.g., "استاد حمد بن خليفة").
/// - `referees`: Object `{"title": "محمد ناصر", "referee_type": "حكم الساحة"}`.
/// - `round`: String round description (e.g., "الجولة 1").
/// - `championship`: Object containing title and logo image URL.
/// - `events`, `lineup`, `statics`: Integer flags (`1` if available, `0` if not/upcoming).
class MatchInfoModel {
  final int matchId;
  final String? stadium;
  final String? refereeName;
  final String? round;
  final String? championshipTitle;
  final String? championshipImage;
  final bool hasEvents;
  final bool hasLineup;
  final bool hasStatics;

  const MatchInfoModel({
    required this.matchId,
    this.stadium,
    this.refereeName,
    this.round,
    this.championshipTitle,
    this.championshipImage,
    this.hasEvents = false,
    this.hasLineup = false,
    this.hasStatics = false,
  });

  factory MatchInfoModel.fromMap(Map<String, dynamic> map) {
    final champ = map['championship'] as Map<String, dynamic>?;
    final refs = map['referees'] as Map<String, dynamic>?;

    return MatchInfoModel(
      matchId: (map['match_id'] as num?)?.toInt() ?? 0,
      stadium: map['Stadium'] as String?,
      refereeName: refs?['title'] as String?,
      round: map['round'] as String?,
      championshipTitle: champ?['title'] as String?,
      championshipImage: champ?['image'] as String?,
      hasEvents: map['events'] == 1,
      hasLineup: map['lineup'] == 1,
      hasStatics: map['statics'] == 1,
    );
  }
}

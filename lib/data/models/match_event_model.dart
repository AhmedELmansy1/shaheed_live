import '../../core/utils/date_formatter.dart';

enum MatchEventType {
  goal,
  yellowCard,
  redCard,
  substitution,
  periodMarker,
  unknown,
}

/// Data model for match timeline events (`type=matches_event&id={id}`).
///
/// REAL API RESPONSE FIELDS (Empirically Verified):
/// - `events`: Array sorted latest-minute-first (e.g. min 120, 55, 45, 11, 0).
/// - `type`: Integer code (`1` = goal, `2` = yellow, `3` = red, `4` = substitution, `100` = period marker).
/// - `status_name`: Server-provided Arabic text description for the event (e.g. "هدف", "بطاقة صفراء", "تبديل").
/// - `time_minute` & `time_plus`: Minute and stoppage time (e.g., 45 + 2 -> "٤٥+٢").
/// - Upcoming matches return `"data": {}` (empty map) with no events, returning empty `[]`.
class MatchEventModel {
  final int eventId;
  final dynamic teamId;
  final MatchEventType eventType;
  final String statusName;
  final int minute;
  final int stoppageMinute;
  final String? playerName;
  final String? assistPlayerName;

  const MatchEventModel({
    required this.eventId,
    required this.teamId,
    required this.eventType,
    required this.statusName,
    required this.minute,
    this.stoppageMinute = 0,
    this.playerName,
    this.assistPlayerName,
  });

  factory MatchEventModel.fromMap(Map<String, dynamic> map) {
    final typeInt = (map['type'] as num?)?.toInt() ?? 0;
    final statusNameStr = (map['status_name'] as String?) ?? '';

    MatchEventType parseType() {
      if (typeInt == 1 || statusNameStr.contains('هدف')) return MatchEventType.goal;
      if (typeInt == 2 || statusNameStr.contains('صفراء')) return MatchEventType.yellowCard;
      if (typeInt == 3 || statusNameStr.contains('حمراء')) return MatchEventType.redCard;
      if (typeInt == 4 || statusNameStr.contains('تبديل')) return MatchEventType.substitution;
      if (typeInt == 100) return MatchEventType.periodMarker;
      return MatchEventType.unknown;
    }

    String? extractPlayerName(dynamic val) {
      if (val == null) return null;
      if (val is Map<String, dynamic>) {
        return (val['short_title'] ?? val['title']) as String?;
      }
      return val.toString();
    }

    return MatchEventModel(
      eventId: (map['event_id'] as num?)?.toInt() ?? 0,
      teamId: map['team_id'] ?? 0,
      eventType: parseType(),
      statusName: statusNameStr,
      minute: (map['time_minute'] as num?)?.toInt() ?? 0,
      stoppageMinute: (map['time_plus'] as num?)?.toInt() ?? 0,
      playerName: extractPlayerName(map['player_name']),
      assistPlayerName: extractPlayerName(map['assist_player_name']),
    );
  }

  String get formattedMinute {
    if (stoppageMinute > 0) {
      return DateFormatter.toArabicNumerals('$minute+$stoppageMinute\'');
    }
    return DateFormatter.toArabicNumerals('$minute\'');
  }
}

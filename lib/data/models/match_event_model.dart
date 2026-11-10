import '../../core/utils/app_number_format.dart';
import '../api/match_score_api.dart' as api;

/// Extended event type enum covering all types from EventMapper.
enum MatchEventType {
  goal,
  ownGoal,
  penaltyScored,
  penaltyMissed,
  varDisallowed,
  yellowCard,
  redCard,
  secondYellow,
  substitution,
  save,
  crossbar,
  missedChance,
  periodMarker,
  unknown,
}

/// Data model for match timeline events (`type=matches_event&id={id}`).
///
/// REAL API RESPONSE FIELDS (Empirically Verified):
/// - `events`: Array sorted latest-minute-first (e.g. min 120, 55, 45, 11, 0).
/// - `type`: Integer code — mapped via [EventMapper] in match_score_api.dart.
/// - `status_name`: Server-provided Arabic text description for the event (e.g. "هدف", "بطاقة صفراء", "تبديل").
/// - `time_minute` & `time_plus`: Minute and stoppage time (e.g., 45 + 2 -> "٤٥+٢").
/// - Upcoming matches return `"data": {}` (empty map) with no events, returning empty `[]`.
class MatchEventModel {
  final int eventId;
  final dynamic teamId;
  final MatchEventType eventType;

  /// Arabic label from EventMapper (e.g. "هدف", "بطاقة صفراء", "ركلة جزاء ضائعة").
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
    // Delegate event type mapping to EventMapper for full type coverage
    final parsed = api.EventMapper.parse(map);

    final MatchEventType eventType = switch (parsed.kind) {
      api.MatchEventKind.goal => MatchEventType.goal,
      api.MatchEventKind.ownGoal => MatchEventType.ownGoal,
      api.MatchEventKind.penaltyScored => MatchEventType.penaltyScored,
      api.MatchEventKind.penaltyMissed => MatchEventType.penaltyMissed,
      api.MatchEventKind.varDisallowed => MatchEventType.varDisallowed,
      api.MatchEventKind.yellowCard => MatchEventType.yellowCard,
      api.MatchEventKind.redCard => MatchEventType.redCard,
      api.MatchEventKind.secondYellow => MatchEventType.secondYellow,
      api.MatchEventKind.substitution => MatchEventType.substitution,
      api.MatchEventKind.save => MatchEventType.save,
      api.MatchEventKind.crossbar => MatchEventType.crossbar,
      api.MatchEventKind.missedChance => MatchEventType.missedChance,
      api.MatchEventKind.periodMarker => MatchEventType.periodMarker,
      api.MatchEventKind.other => MatchEventType.unknown,
    };

    return MatchEventModel(
      eventId: parsed.id,
      teamId: parsed.teamId,
      eventType: eventType,
      statusName: parsed.label,
      minute: parsed.minute ~/ 100,
      stoppageMinute: parsed.minute % 100,
      playerName: parsed.player.isNotEmpty ? parsed.player : null,
      assistPlayerName:
          parsed.relatedPlayer.isNotEmpty ? parsed.relatedPlayer : null,
    );
  }

  String get formattedMinute {
    return AppNumberFormat.formatMinute(minute, stoppageMinute > 0 ? stoppageMinute : null);
  }

  /// Sortable minute value for timeline chronological ordering.
  /// Milestones have dedicated values to sit cleanly between match periods:
  /// - Full Time (انتهت المباراة): 9999 (top of reverse-chronological list)
  /// - Half Time (نهاية الشوط الأول): 4550 (between 45+X' and 46')
  /// - Kickoff (بدأت المباراة): -1 (bottom of reverse-chronological list)
  int get sortMinute {
    if (eventType == MatchEventType.periodMarker) {
      final name = statusName.trim();
      if (name.contains('انتهت')) return 9999;
      if (name.contains('الشوط الإضافي الثاني')) return 9998;
      if (name.contains('الشوط الإضافي الأول')) return 9050;
      if (name.contains('الشوط الأول') || name.contains('استراحة')) return 4550;
      if (name.contains('بدأت')) return -1;
      return minute > 0 ? (minute * 100 + stoppageMinute) : 0;
    }
    return minute * 100 + stoppageMinute;
  }
}

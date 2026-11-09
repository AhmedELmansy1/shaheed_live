import '../../core/utils/date_formatter.dart';
import '../api/match_score_api.dart' as api;

/// Enum representing the normalized lifecycle status of a football match.
enum MatchStatus { notStarted, live, paused, finished, postponed, cancelled }

/// Championship / League metadata attached to a match.
class ChampionshipInfo {
  final dynamic id;
  final String title;
  final String? image;

  const ChampionshipInfo({required this.id, required this.title, this.image});

  factory ChampionshipInfo.fromMap(Map<String, dynamic> map) {
    return ChampionshipInfo(
      id: map['id'] ?? map['url_id'] ?? 0,
      title: (map['title'] as String?) ?? 'دوري غير محدد',
      image: map['image'] as String?,
    );
  }
}

/// Team / Club metadata attached to a match.
class TeamInfo {
  final dynamic rowId;
  final String title;
  final String? image;

  const TeamInfo({required this.rowId, required this.title, this.image});

  factory TeamInfo.fromMap(Map<String, dynamic> map) {
    return TeamInfo(
      rowId: map['row_id'] ?? 0,
      title: (map['title'] as String?) ?? 'فريق غير محدد',
      image: map['image'] as String?,
    );
  }
}

/// Data model representing a football match object from the Worker API.
class MatchModel {
  final int matchId;
  final String? matchDate;
  final String? matchTime;
  final bool isLive;
  final MatchStatus status;
  final ChampionshipInfo championship;
  final TeamInfo homeTeam;
  final TeamInfo awayTeam;
  final String? homeScore;
  final String? awayScore;
  final String? adminBadge;
  final String? adminTitle;
  final String? eventStatus;

  const MatchModel({
    required this.matchId,
    this.matchDate,
    this.matchTime,
    required this.isLive,
    required this.status,
    required this.championship,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.adminBadge,
    this.adminTitle,
    this.eventStatus,
  });

  // Convenience Getters for presentation layer
  String get id => matchId.toString();
  dynamic get homeTeamId => homeTeam.rowId;
  dynamic get awayTeamId => awayTeam.rowId;
  String get homeTeamName => homeTeam.title;
  String get awayTeamName => awayTeam.title;
  String? get homeTeamLogo => homeTeam.image;
  String? get awayTeamLogo => awayTeam.image;
  String get leagueName => championship.title;
  String? get leagueLogo => championship.image;
  bool get isFinished => status == MatchStatus.finished;
  String get displayDate => matchDate ?? '';
  String get formattedLocalTime =>
      DateFormatter.formatMatchTime(matchDate, matchTime);
  DateTime? get kickoffDateTime =>
      DateFormatter.parseCairoMatchDateTime(matchDate, matchTime);

  /// Returns the formatted live minute or status (e.g. "٤٥'", "٩٠+٤'", "استراحة"), or null if not live.
  String? get currentMinute {
    if (!isLive) return null;
    if (adminTitle == null || adminTitle!.trim().isEmpty) return null;
    final trimmed = adminTitle!.trim();
    if (trimmed == 'لم تبدأ' ||
        trimmed == 'انتهت' ||
        trimmed == 'تأجلت' ||
        trimmed == 'ملغاة') {
      return null;
    }
    return DateFormatter.toArabicNumerals(trimmed);
  }

  String get statusName {
    if (adminTitle != null && adminTitle!.isNotEmpty) {
      return adminTitle!;
    }
    if (isLive) return 'مباشر';
    if (isFinished) return 'انتهت';
    if (status == MatchStatus.postponed) return 'تأجلت';
    if (status == MatchStatus.cancelled) return 'إلغاء';
    return 'لم تبدأ';
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    final adminTitleStr = map['admin_title'] as String?;

    // Delegate to the single authoritative status resolver
    final apiStatus = api.MatchStatusResolver.resolve(map);

    MatchStatus computedStatus;
    switch (apiStatus.state) {
      case api.MatchState.live:
        computedStatus = MatchStatus.live;
      case api.MatchState.halfTime:
        computedStatus = MatchStatus.paused;
      case api.MatchState.finished:
        computedStatus = MatchStatus.finished;
      case api.MatchState.postponed:
        computedStatus = MatchStatus.postponed;
      case api.MatchState.cancelled:
        computedStatus = MatchStatus.cancelled;
      case api.MatchState.notStarted:
        computedStatus = MatchStatus.notStarted;
    }

    final isActuallyLive =
        computedStatus == MatchStatus.live ||
        computedStatus == MatchStatus.paused;

    String? parseScore(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      if (str.isEmpty || str == 'null') return null;
      return DateFormatter.toArabicNumerals(str);
    }

    int parseMatchId(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val.trim()) ?? 0;
      return 0;
    }

    return MatchModel(
      matchId: parseMatchId(map['match_id'] ?? map['id']),
      matchDate: map['match_date'] as String?,
      matchTime: map['match_time'] as String?,
      isLive: isActuallyLive,
      status: computedStatus,
      championship: ChampionshipInfo.fromMap(
        (map['championship'] as Map<String, dynamic>?) ?? {},
      ),
      homeTeam: TeamInfo.fromMap(
        (map['home_team'] as Map<String, dynamic>?) ?? {},
      ),
      awayTeam: TeamInfo.fromMap(
        (map['away_team'] as Map<String, dynamic>?) ?? {},
      ),
      homeScore: parseScore(map['home_scores']),
      awayScore: parseScore(map['away_scores']),
      adminBadge: (map['admin_badge'] as String?)?.toLowerCase(),
      adminTitle: adminTitleStr,
      eventStatus: (map['event_status'] as String?)?.toLowerCase(),
    );
  }
}

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

  factory ChampionshipInfo.fromMap(dynamic raw) {
    if (raw == null) {
      return const ChampionshipInfo(id: 0, title: 'دوري غير محدد');
    }
    if (raw is! Map) {
      return ChampionshipInfo(id: raw, title: 'دوري غير محدد');
    }
    final map = raw;
    final id = map['id'] ?? map['url_id'] ?? 0;
    final dynamic titleCandidate = map['title'] ?? map['name'] ?? map['champ_title'];
    final titleStr = titleCandidate?.toString().trim() ?? '';
    final cleanTitle =
        (titleStr.isNotEmpty && titleStr != 'null') ? titleStr : 'دوري غير محدد';
    final imageStr = (map['image'] ?? map['logo'] ?? map['champ_image'])?.toString();

    return ChampionshipInfo(
      id: id,
      title: cleanTitle,
      image: (imageStr != null && imageStr.isNotEmpty && imageStr != 'null')
          ? imageStr
          : null,
    );
  }
}

/// Team / Club metadata attached to a match.
class TeamInfo {
  final dynamic rowId;
  final String title;
  final String? image;

  const TeamInfo({required this.rowId, required this.title, this.image});

  factory TeamInfo.fromMap(dynamic raw) {
    if (raw == null) {
      return const TeamInfo(rowId: 0, title: 'فريق غير محدد');
    }
    if (raw is! Map) {
      return TeamInfo(rowId: raw, title: 'فريق غير محدد');
    }
    final map = raw;
    final rowId = map['row_id'] ?? map['id'] ?? map['team_id'] ?? 0;
    final dynamic titleCandidate = map['title'] ??
        map['name'] ??
        map['team_name'] ??
        map['ar_title'] ??
        map['team_title'] ??
        map['short_title'];
    final titleStr = titleCandidate?.toString().trim() ?? '';
    final cleanTitle =
        (titleStr.isNotEmpty && titleStr != 'null') ? titleStr : 'فريق غير محدد';
    final imageStr = (map['image'] ?? map['logo'] ?? map['team_image'])?.toString();

    return TeamInfo(
      rowId: rowId,
      title: cleanTitle,
      image: (imageStr != null && imageStr.isNotEmpty && imageStr != 'null')
          ? imageStr
          : null,
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
  final String? channel;
  final String? commentator;

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
    this.channel,
    this.commentator,
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
  String formatLocalTime({int offsetHours = 0}) =>
      DateFormatter.formatMatchTime(matchDate, matchTime, offsetHours: offsetHours);
  DateTime? get kickoffDateTime =>
      DateFormatter.parseCairoMatchDateTime(matchDate, matchTime);
  DateTime? getKickoffDateTime({int offsetHours = 0}) =>
      DateFormatter.parseCairoMatchDateTime(matchDate, matchTime, offsetHours: offsetHours);

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

    var homeTeam = TeamInfo.fromMap(map['home_team']);
    if (homeTeam.title == 'فريق غير محدد' && map['home_name'] != null) {
      final hName = map['home_name'].toString().trim();
      if (hName.isNotEmpty) {
        homeTeam = TeamInfo(
          rowId: homeTeam.rowId != 0 ? homeTeam.rowId : (map['home_id'] ?? 0),
          title: hName,
          image: homeTeam.image ?? map['home_image']?.toString(),
        );
      }
    }

    var awayTeam = TeamInfo.fromMap(map['away_team']);
    if (awayTeam.title == 'فريق غير محدد' && map['away_name'] != null) {
      final aName = map['away_name'].toString().trim();
      if (aName.isNotEmpty) {
        awayTeam = TeamInfo(
          rowId: awayTeam.rowId != 0 ? awayTeam.rowId : (map['away_id'] ?? 0),
          title: aName,
          image: awayTeam.image ?? map['away_image']?.toString(),
        );
      }
    }

    final rawChannel =
        (map['channel'] ?? map['channel_name'] ?? map['tv_channel'])?.toString().trim();
    final rawCommentator =
        (map['commentator'] ?? map['commentator_name'])?.toString().trim();

    return MatchModel(
      matchId: parseMatchId(map['match_id'] ?? map['id']),
      matchDate: map['match_date'] as String?,
      matchTime: map['match_time'] as String?,
      isLive: isActuallyLive,
      status: computedStatus,
      championship: ChampionshipInfo.fromMap(map['championship']),
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeScore: parseScore(map['home_scores']),
      awayScore: parseScore(map['away_scores']),
      adminBadge: (map['admin_badge'] as String?)?.toLowerCase(),
      adminTitle: adminTitleStr,
      eventStatus: (map['event_status'] as String?)?.toLowerCase(),
      channel: (rawChannel != null && rawChannel.isNotEmpty && rawChannel != 'null')
          ? rawChannel
          : null,
      commentator:
          (rawCommentator != null && rawCommentator.isNotEmpty && rawCommentator != 'null')
              ? rawCommentator
              : null,
    );
  }
}

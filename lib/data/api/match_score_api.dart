// ============================================================================
// match_score_api.dart
// ----------------------------------------------------------------------------
// One self-contained file that merges:
//   (1) the Worker API map from API.txt (matches_*, match_info, statics_match,
//       matches_event, matches_lineup), and
//   (2) the useful logic found in the Yalla WordPress plugin (status rules,
//       event-type codes, lineup/formation layout, image URL building).
//
// Dependencies (already in the project): dio, timezone.
// Put it at: lib/data/api/match_score_api.dart
//
// IMPORTANT - source timezone:
//   The plugin converts kickoff times from 'Asia/Riyadh' (fixed UTC+3, no DST).
//   Earlier we assumed 'Africa/Cairo', but a test done while Egypt was on DST
//   (also UTC+3) cannot tell the two apart. After Egypt leaves DST (end of
//   October) Cairo becomes UTC+2 and Riyadh stays UTC+3, so the wrong choice
//   shifts every kickoff by one hour. Verify once, then change
//   ApiConfig.sourceTimezone if needed.
//
// NOT compiled in the sandbox where this was written - run `flutter analyze`.
// ============================================================================

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:timezone/timezone.dart' as tz;

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
class ApiConfig {
  ApiConfig._();

  /// Overridable at runtime (dashboard `api_base_url_override`).
  static const String defaultWorkerBase =
      'https://shoot-live-admin-dashboard.vercel.app/api/matches';

  /// Timezone of `match_date` + `match_time` returned by the API.
  /// YsScores source feed is published in Cairo time ('Africa/Cairo', UTC+2 standard).
  static const String sourceTimezone = 'Africa/Cairo';

  /// Image CDN used by the data source.
  static const String imgHost = 'https://imgs.ysscores.com';

  /// A match flagged live but kicked off more than this many minutes ago
  /// (or has not kicked off yet) is not trusted as live.
  static const int liveWindowMinutes = 130;
}

// ---------------------------------------------------------------------------
// Small safe-cast helpers
// ---------------------------------------------------------------------------
String _s(dynamic v) => (v ?? '').toString().trim();

int _i(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(_s(v)) ?? 0;
}

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<dynamic> _list(dynamic v) => v is List ? v : const [];

// ---------------------------------------------------------------------------
// Image URLs  (from ysip_build_image_url / ysip_clean_image_url)
// ---------------------------------------------------------------------------
enum ImageKind { team, championship, player }

class ImageUrls {
  ImageUrls._();

  /// Accepts a full URL, a bare filename, or an old-domain URL.
  /// Returns '' when there is nothing usable (show your fallback avatar).
  static String build(String? raw, ImageKind kind) {
    var v = _s(raw);
    if (v.isEmpty) return '';

    // Old domain -> keep only the filename and rebuild on the CDN.
    if (v.contains('api-ar.ysscores.com/public/uploads/')) {
      v = v.split('/').last;
    }

    if (v.startsWith('http')) {
      // Team crests exist in a 128px variant; other kinds left untouched
      // because the larger variant is not confirmed for them.
      return kind == ImageKind.team ? _upscale(v) : v;
    }

    v = v.replaceFirst(RegExp(r'^/+'), '');
    final folder = switch (kind) {
      ImageKind.team => 'teams/128',
      ImageKind.championship => 'championship/48',
      ImageKind.player => 'players/128',
    };
    return '${ApiConfig.imgHost}/$folder/$v';
  }

  static String _upscale(String url) =>
      url.replaceAll(RegExp(r'/(48|64|96|small|thumb|tiny)/'), '/128/');
}

// ---------------------------------------------------------------------------
// Kickoff time  (source timezone -> device local, DST-safe via IANA db)
// Requires tz.initializeTimeZones() at startup (already done in the app).
// ---------------------------------------------------------------------------
class KickoffTime {
  KickoffTime._();

  static tz.TZDateTime? parse(String? date, String? time) {
    try {
      final d = _s(date).split('-');
      final t = (_s(time).isEmpty ? '00:00:00' : _s(time)).split(':');
      final loc = tz.getLocation(ApiConfig.sourceTimezone);
      return tz.TZDateTime(
        loc,
        int.parse(d[0]),
        int.parse(d[1]),
        int.parse(d[2]),
        int.parse(t[0]),
        t.length > 1 ? int.parse(t[1]) : 0,
        t.length > 2 ? int.parse(t[2]) : 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Kickoff as a plain device-local DateTime (null if unparsable).
  static DateTime? toLocal(String? date, String? time) {
    final k = parse(date, time);
    if (k == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(k.millisecondsSinceEpoch);
  }

  /// Minutes since kickoff (negative = not started yet). Null if unparsable.
  static int? minutesSinceKickoff(String? date, String? time, {DateTime? now}) {
    final k = parse(date, time);
    if (k == null) return null;
    final n = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return ((n - k.millisecondsSinceEpoch) / 60000).floor();
  }

  static String apiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Match status  (merges our parseStatus rules + plugin ysip_normalize_match_state)
// ---------------------------------------------------------------------------
enum MatchState { notStarted, live, halfTime, finished, postponed, cancelled }

class MatchStatusInfo {
  const MatchStatusInfo(this.state, this.label);
  final MatchState state;

  /// Server-provided Arabic label (admin_title), e.g. "45'", "استراحة", "انتهت".
  final String label;

  bool get isLive => state == MatchState.live || state == MatchState.halfTime;
}

class MatchStatusResolver {
  MatchStatusResolver._();

  /// Raw `status` codes seen in the plugin:
  /// 1 first half, 2 half-time, 3 second half, 4 ended,
  /// 5/6 extra time, 7/8 penalty shoot-out.
  static const _liveStatusCodes = {1, 3, 5, 6, 7, 8};

  static MatchStatusInfo resolve(Map<String, dynamic> m, {DateTime? now}) {
    final badge = _s(m['admin_badge']).toLowerCase();
    final title = _s(m['admin_title']);
    final ev = _s(m['event_status']).toLowerCase();
    final forced = _s(m['forced_status']).toLowerCase();
    final status = _i(m['status']);
    final liveFlag = _i(m['live']) == 1;

    MatchStatusInfo mk(MatchState s) => MatchStatusInfo(s, title);

    if (badge == 'postponed' || ev == 'postponed') {
      return mk(MatchState.postponed);
    }
    if (badge == 'canceled' ||
        badge == 'cancelled' ||
        ev == 'canceled' ||
        ev == 'cancelled') {
      return mk(MatchState.cancelled);
    }
    if (badge == 'ended' ||
        ev == 'ended' ||
        ev == 'ended_penalty' ||
        forced == 'ended' ||
        status == 4) {
      return mk(MatchState.finished);
    }
    if (badge == 'half' || status == 2 || title.contains('استراحة')) {
      return mk(MatchState.halfTime);
    }
    if (badge == 'live' ||
        ev == 'live' ||
        forced == 'live' ||
        _liveStatusCodes.contains(status)) {
      return mk(MatchState.live);
    }

    // The server explicitly says "not started": trust it over live=1 and any elapsed time calculation.
    // Unstarted matches (status == 0, event_status == "not_started", status_text == "لم تبدأ", badge == "soon")
    // must NEVER be assumed finished just because kickoff time has passed or time difference exists.
    final statusText = _s(m['status_text']).trim();
    final hasStatus = m['status'] != null && _s(m['status']).isNotEmpty;
    if (badge == 'soon' ||
        ev == 'not_started' ||
        (hasStatus && status == 0) ||
        statusText == 'لم تبدأ' ||
        statusText.contains('لم تبدأ') ||
        title == 'لم تبدأ') {
      return mk(MatchState.notStarted);
    }

    final mins = KickoffTime.minutesSinceKickoff(
      _s(m['match_date']),
      _s(m['match_time']),
      now: now,
    );

    // Unreliable live flag: only believe it inside the plausible window.
    if (liveFlag && mins != null && mins >= 0 && mins <= ApiConfig.liveWindowMinutes) {
      return mk(MatchState.live);
    }
    // Long past kickoff with no explicit state -> assume finished.
    if (mins != null && mins > ApiConfig.liveWindowMinutes) {
      return mk(MatchState.finished);
    }
    return mk(MatchState.notStarted);
  }
}

// ---------------------------------------------------------------------------
// Events  (type codes taken from the plugin's timeline renderer)
// ---------------------------------------------------------------------------
enum MatchEventKind {
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
  other,
}

class ParsedEvent {
  const ParsedEvent({
    required this.id,
    required this.kind,
    required this.label,
    required this.minuteLabel,
    required this.minute,
    required this.teamId,
    required this.player,
    required this.relatedPlayer,
    required this.rawStatusName,
  });

  final int id;
  final MatchEventKind kind;

  /// Arabic label, e.g. "هدف", "بطاقة صفراء".
  final String label;

  /// "45'" or "45+2'" in Western digits - pass through your Eastern-numeral helper.
  final String minuteLabel;
  final int minute;
  final int teamId;
  final String player;

  /// Assist for goals, player coming ON for substitutions.
  final String relatedPlayer;
  final String rawStatusName;
}

class EventMapper {
  EventMapper._();

  static ParsedEvent parse(Map<String, dynamic> e) {
    final type = _i(e['type']);
    final status = _i(e['status']);
    final statusName = _s(e['status_name']);
    final player = _name(e['player_name']);
    final related = _name(e['assist_player_name']);

    MatchEventKind kind;
    String label;
    switch (type) {
      case 1:
        final own = statusName.toLowerCase().contains('own') ||
            player.toLowerCase().contains('own');
        kind = own ? MatchEventKind.ownGoal : MatchEventKind.goal;
        label = own ? 'هدف عكسي' : 'هدف';
      case 4:
        kind = MatchEventKind.ownGoal;
        label = 'هدف عكسي';
      case 5:
        kind = MatchEventKind.penaltyScored;
        label = 'هدف (ركلة جزاء)';
      case 6:
        kind = MatchEventKind.penaltyMissed;
        label = 'ركلة جزاء ضائعة';
      case 7:
        kind = MatchEventKind.varDisallowed;
        label = 'هدف ملغي (تسلل)';
      case 15:
      case 17:
        kind = MatchEventKind.varDisallowed;
        label = 'هدف ملغي';
      case 2:
        kind = MatchEventKind.yellowCard;
        label = 'بطاقة صفراء';
      case 3:
        // status 7 on a red card = sent off for a second yellow.
        kind = status == 7 ? MatchEventKind.secondYellow : MatchEventKind.redCard;
        label = status == 7 ? 'طرد (إنذار ثانٍ)' : 'بطاقة حمراء';
      case 8:
        kind = MatchEventKind.substitution;
        label = 'تبديل';
      case 10:
      case 11:
        kind = MatchEventKind.save;
        label = 'تصدي حارس';
      case 14:
      case 22:
        kind = MatchEventKind.crossbar;
        label = 'في العارضة';
      case 21:
        kind = MatchEventKind.missedChance;
        label = 'فرصة ضائعة';
      case 100:
        kind = MatchEventKind.periodMarker;
        label = statusName;
      default:
        kind = MatchEventKind.other;
        label = statusName;
    }

    final minute = _i(e['time_minute']);
    final plus = _i(e['time_plus']);

    return ParsedEvent(
      id: _i(e['event_id']),
      kind: kind,
      label: label,
      minuteLabel: plus > 0 ? "$minute+$plus'" : "$minute'",
      minute: minute * 100 + plus, // sortable
      teamId: _i(e['team_id']),
      player: player,
      relatedPlayer: related,
      rawStatusName: statusName,
    );
  }

  /// The API returns newest first. Set [newestFirst] false for chronological.
  static List<ParsedEvent> parseAll(dynamic raw, {bool newestFirst = true}) {
    final list = _list(raw)
        .whereType<Map>()
        .map((e) => parse(Map<String, dynamic>.from(e)))
        .toList();
    list.sort((a, b) => newestFirst
        ? b.minute.compareTo(a.minute)
        : a.minute.compareTo(b.minute));
    return list;
  }

  static String _name(dynamic v) {
    if (v is Map) {
      final short = _s(v['short_title']);
      return short.isNotEmpty ? short : _s(v['title']);
    }
    return _s(v);
  }
}

// ---------------------------------------------------------------------------
// Statistics  (shape seen: data.statics.{teamId}.{stat})
// ---------------------------------------------------------------------------
const Map<String, String> statLabelsAr = {
  'ball_possession': 'نسبة الاستحواذ',
  'total_shots': 'إجمالي التسديدات',
  'shots_on_goal': 'تسديدات على المرمى',
  'corner_kicks': 'الركنيات',
  'fouls': 'الأخطاء',
};

class StatsParser {
  StatsParser._();

  /// Returns { teamId : { statKey : value } }. Empty map for upcoming matches
  /// (the API returns [] or {} then).
  static Map<int, Map<String, num>> parse(dynamic data) {
    final root = _map(data);
    final statics = _map(root['statics']);
    final out = <int, Map<String, num>>{};
    statics.forEach((teamKey, value) {
      final stats = <String, num>{};
      _map(value).forEach((k, v) {
        if (k == 'team_id') return;
        final n = v is num ? v : num.tryParse(_s(v));
        if (n != null) stats[k] = n;
      });
      final id = int.tryParse(teamKey);
      if (id != null) out[id] = stats;
    });
    return out;
  }
}

// ---------------------------------------------------------------------------
// Lineup  (shape: data['0'] = formations/coaches, data.lineup.{teamId}.lineup[])
// ---------------------------------------------------------------------------
class LineupPlayer {
  const LineupPlayer({
    required this.id,
    required this.name,
    required this.shortName,
    required this.number,
    required this.position,
    required this.imageUrl,
    required this.formationPosition,
    required this.rating,
  });

  final int id;
  final String name;
  final String shortName;
  final int number;

  /// Normalised to G / D / M / F.
  final String position;

  /// '' when no photo -> show initials avatar.
  final String imageUrl;
  final int formationPosition;
  final String rating;

  String get displayName => shortName.isNotEmpty ? shortName : name;
  String get initials {
    final n = displayName.trim();
    return n.isEmpty ? '?' : n.substring(0, 1);
  }
}

class TeamLineup {
  const TeamLineup({
    required this.teamId,
    required this.formation,
    required this.coach,
    required this.starters,
    required this.substitutes,
  });

  final int teamId;
  final String formation;
  final String coach;
  final List<LineupPlayer> starters;
  final List<LineupPlayer> substitutes;
}

class MatchLineup {
  const MatchLineup({required this.home, required this.away});
  final TeamLineup home;
  final TeamLineup away;
}

class PitchLayout {
  const PitchLayout({required this.goalkeeper, required this.rows});

  final LineupPlayer? goalkeeper;

  /// Defence -> attack. One list per formation line, e.g. 4-3-3 -> [4,3,3].
  final List<List<LineupPlayer>> rows;
}

class LineupParser {
  LineupParser._();

  /// [homeId]/[awayId] are fallbacks when the payload lacks team ids.
  /// Returns null when the lineup is not announced (empty list/map).
  static MatchLineup? parse(dynamic data, {int? homeId, int? awayId}) {
    final root = _map(data);
    if (root.isEmpty) return null;

    final info = _map(root['info']).isNotEmpty ? _map(root['info']) : _map(root['0']);
    final lineups = _map(root['lineup']);
    if (lineups.isEmpty) return null;

    // Detect team IDs from info, fallbacks, or the lineup map keys
    var hId = _i(info['home_team']) != 0 ? _i(info['home_team']) : (homeId ?? 0);
    var aId = _i(info['away_team']) != 0 ? _i(info['away_team']) : (awayId ?? 0);

    if (hId == 0 || aId == 0) {
      final keys = lineups.keys.map((k) => int.tryParse(k) ?? 0).where((k) => k > 0).toList();
      if (keys.length >= 2) {
        if (hId == 0) hId = keys[0];
        if (aId == 0) aId = keys[1];
      } else if (keys.length == 1 && hId == 0) {
        hId = keys[0];
      }
    }

    List<LineupPlayer> extractStarters(dynamic block) {
      if (block == null) return const [];
      final b = _map(block);

      // Case 1: direct 'lineup' list inside team block
      if (b.containsKey('lineup') && b['lineup'] != null) {
        return _players(b['lineup']);
      }

      // Case 2: position group maps/lists ('G', 'D', 'M', 'F', 'S')
      final starters = <LineupPlayer>[];
      for (final pos in ['G', 'D', 'M', 'F', 'S']) {
        if (b.containsKey(pos)) {
          final group = b[pos];
          if (group is Map) {
            starters.addAll(_players(group.values));
          } else if (group is List) {
            starters.addAll(_players(group));
          }
        }
      }
      if (starters.isNotEmpty) return starters;

      // Case 3: block is directly a list
      if (block is List) {
        return _players(block);
      }

      return const [];
    }

    List<LineupPlayer> extractSubstitutes(int teamId, dynamic block) {
      final b = _map(block);

      // Helper to unpack subs whether list or map (with optional 'sub' wrapper)
      List<LineupPlayer> unpackSubs(dynamic raw) {
        if (raw == null) return const [];
        if (raw is List) return _players(raw);
        if (raw is Map) {
          if (raw.containsKey('sub')) {
            final inner = raw['sub'];
            if (inner is List) return _players(inner);
            if (inner is Map) return _players(inner.values);
          }
          return _players(raw.values);
        }
        return const [];
      }

      // Case 1: inside block['substitutions']
      if (b.containsKey('substitutions') && b['substitutions'] != null) {
        final res = unpackSubs(b['substitutions']);
        if (res.isNotEmpty) return res;
      }

      // Case 2: inside root['substitutions'][teamId]
      final rootSubs = _map(root['substitutions']);
      if (rootSubs.containsKey(teamId.toString())) {
        final res = unpackSubs(rootSubs[teamId.toString()]);
        if (res.isNotEmpty) return res;
      }

      // Case 3: inside root['substitutes'][teamId]
      final rootSubstitutes = _map(root['substitutes']);
      if (rootSubstitutes.containsKey(teamId.toString())) {
        final res = unpackSubs(rootSubstitutes[teamId.toString()]);
        if (res.isNotEmpty) return res;
      }

      // Case 4: inside block['S']
      if (b.containsKey('S')) {
        final res = unpackSubs(b['S']);
        if (res.isNotEmpty) return res;
      }

      return const [];
    }

    TeamLineup build(int id, String formation, String coach) {
      final block = lineups[id.toString()];
      return TeamLineup(
        teamId: id,
        formation: formation.isEmpty ? '4-4-2' : formation,
        coach: coach,
        starters: extractStarters(block),
        substitutes: extractSubstitutes(id, block),
      );
    }

    String extractCoach(dynamic raw) {
      if (raw is Map) return _s(raw['title'] ?? raw['name']);
      return _s(raw);
    }

    final home = build(
      hId,
      _s(info['home_formation']),
      extractCoach(info['home_coach']),
    );
    final away = build(
      aId,
      _s(info['away_formation']),
      extractCoach(info['away_coach']),
    );

    if (home.starters.isEmpty && away.starters.isEmpty) return null;
    return MatchLineup(home: home, away: away);
  }

  /// Plugin algorithm: sort by line (G,D,M,F) then formation_position,
  /// pull the goalkeeper, then cut rows following the "4-3-3" string.
  static PitchLayout layout(String formation, List<LineupPlayer> starters) {
    final players = [...starters]..sort((a, b) {
        final wa = _weight(a.position);
        final wb = _weight(b.position);
        if (wa != wb) return wa - wb;
        return a.formationPosition - b.formationPosition;
      });

    LineupPlayer? gk;
    if (players.isNotEmpty && players.first.position == 'G') {
      gk = players.removeAt(0);
    }

    final counts = formation
        .split('-')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((n) => n > 0)
        .toList();

    final rows = <List<LineupPlayer>>[];
    for (final c in counts) {
      final row = <LineupPlayer>[];
      for (var i = 0; i < c && players.isNotEmpty; i++) {
        row.add(players.removeAt(0));
      }
      rows.add(row);
    }
    while (players.isNotEmpty) {
      if (rows.isEmpty) rows.add(<LineupPlayer>[]);
      rows.last.add(players.removeAt(0));
    }
    return PitchLayout(goalkeeper: gk, rows: rows);
  }

  // -- internals ------------------------------------------------------------

  static List<LineupPlayer> _players(dynamic raw) {
    final Iterable items;
    if (raw is List) {
      items = raw;
    } else if (raw is Iterable) {
      items = raw;
    } else if (raw is Map) {
      items = raw.values;
    } else {
      items = const [];
    }
    return items
        .whereType<Map>()
        .map((e) => _player(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Items are either wrapped ({player:{...}, position:'D'}) or flat
  /// ({short_title, shirt_number, pos}) depending on the endpoint version.
  static LineupPlayer _player(Map<String, dynamic> item) {
    final p = item['player'] is Map ? _map(item['player']) : item;

    final rawPos = _s(item['position']).isNotEmpty
        ? _s(item['position'])
        : (_s(item['pos']).isNotEmpty ? _s(item['pos']) : _s(p['position']));

    final img = [
      p['image'],
      p['photo'],
      p['img'],
      p['pic'],
      p['player_image'],
      p['avatar'],
    ].map(_s).firstWhere((v) => v.isNotEmpty, orElse: () => '');

    final number = _i(p['player_number']) != 0
        ? _i(p['player_number'])
        : _i(p['shirt_number']);

    final resolvedName = [
      p['title'],
      p['name'],
      p['player_name'],
      p['short_title'],
    ].map(_s).firstWhere((v) => v.isNotEmpty, orElse: () => '');

    return LineupPlayer(
      id: _i(p['row_id']) != 0
          ? _i(p['row_id'])
          : (_i(p['id']) != 0 ? _i(p['id']) : _i(item['player_id'])),
      name: resolvedName,
      shortName: _s(p['short_title']),
      number: number,
      position: _normalisePos(rawPos),
      imageUrl: ImageUrls.build(img, ImageKind.player),
      formationPosition: _i(item['formation_position']),
      rating: _s(item['rating']),
    );
  }

  static String _normalisePos(String raw) {
    final p = raw.toUpperCase().trim();
    if (p == 'G' || p == 'GK' || raw.contains('حارس')) return 'G';
    if (p == 'D' || p.endsWith('B') || raw.contains('دفاع') || raw.contains('ظهير')) return 'D';
    if (p == 'F' || p == 'S' || p == 'ST' || p == 'CF' || p.endsWith('W') || raw.contains('هجوم') || raw.contains('مهاجم') || raw.contains('جناح')) {
      return 'F';
    }
    if (p == 'M' || p.endsWith('M') || raw.contains('وسط')) return 'M';
    return 'M';
  }

  static int _weight(String pos) => switch (pos) {
        'G' => 1,
        'D' => 2,
        'M' => 3,
        'F' => 4,
        _ => 3,
      };
}

// ---------------------------------------------------------------------------
// HTTP client
// ---------------------------------------------------------------------------
class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => 'ApiException: $message';
}

class MatchScoreApi {
  MatchScoreApi({Dio? dio, String? baseUrl})
      : _dio = dio ?? Dio(),
        _baseUrl = baseUrl ?? ApiConfig.defaultWorkerBase {
    _dio.options
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 15)
      ..headers = {
        'Accept': 'application/json',
        'User-Agent': 'MatchScore/1.0 (Flutter)',
      };
  }

  final Dio _dio;
  String _baseUrl;

  /// Call when the dashboard `api_base_url_override` changes.
  void setBaseUrl(String? url) {
    _baseUrl = (url == null || url.trim().isEmpty)
        ? ApiConfig.defaultWorkerBase
        : url.trim();
  }

  // -- schedule -------------------------------------------------------------

  /// Use this for ALL day tabs (yesterday/today/tomorrow/custom) with a date
  /// computed from the device's local calendar day.
  Future<List<Map<String, dynamic>>> matchesForDate(DateTime localDay) =>
      _matches({'type': 'matches_by_date', 'date': KickoffTime.apiDate(localDay)});

  /// Server-bucketed variants (not recommended for the UI - kept for tools).
  Future<List<Map<String, dynamic>>> matchesToday() =>
      _matches({'type': 'matches_today'});
  Future<List<Map<String, dynamic>>> matchesTomorrow() =>
      _matches({'type': 'matches_tomorrow'});
  Future<List<Map<String, dynamic>>> matchesYesterday() =>
      _matches({'type': 'matches_yesterday'});

  // -- match details --------------------------------------------------------

  Future<Map<String, dynamic>> matchInfo(int id) async =>
      _map(await _get({'type': 'match_info', 'id': id}));

  Future<Map<int, Map<String, num>>> statistics(int id) async =>
      StatsParser.parse(await _get({'type': 'statics_match', 'id': id}));

  Future<List<ParsedEvent>> events(int id, {bool newestFirst = true}) async {
    final data = _map(await _get({'type': 'matches_event', 'id': id}));
    return EventMapper.parseAll(data['events'], newestFirst: newestFirst);
  }

  Future<MatchLineup?> lineup(int id, {int? homeId, int? awayId}) async =>
      LineupParser.parse(
        await _get({'type': 'matches_lineup', 'id': id}),
        homeId: homeId,
        awayId: awayId,
      );

  // -- internals ------------------------------------------------------------

  Future<List<Map<String, dynamic>>> _matches(Map<String, dynamic> q) async {
    final data = await _get(q);
    List<dynamic> raw;
    if (data is List) {
      raw = data;
    } else if (data is Map) {
      raw = _list(data['data']).isNotEmpty
          ? _list(data['data'])
          : _list(data['matches']);
    } else {
      raw = const [];
    }
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Returns the unwrapped `data` value (may be a List, Map, or empty).
  /// Upcoming matches legitimately return [] or {} - that is NOT an error.
  Future<dynamic> _get(Map<String, dynamic> query, {int retries = 1}) async {
    for (var attempt = 0;; attempt++) {
      try {
        final res = await _dio.get<dynamic>(_baseUrl, queryParameters: query);
        var body = res.data;
        if (body is String) body = jsonDecode(body);
        if (body is Map && body['ok'] == false) {
          throw ApiException(_s(body['message']).isEmpty
              ? 'API returned ok:false'
              : _s(body['message']));
        }
        return body is Map && body.containsKey('data') ? body['data'] : body;
      } on DioException catch (e) {
        if (attempt >= retries) {
          throw ApiException(e.message ?? 'Network error');
        }
      } on FormatException {
        throw ApiException('Invalid JSON from API');
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Extra data source: standings + news (+ raw lineup/events) from the site the
// plugin reads (ysscores.com). Endpoints taken from the plugin:
//   get_league_rank?match_code=ID   -> league table for that match's league
//   get_match_news?match_code=ID    -> news items about the match
//   match_lineup?match_code=ID      -> raw lineup (different shape from Worker)
//   get_match_events?match_code=ID  -> raw events (different shape from Worker)
//
// The response shapes of rank/news are NOT documented in the plugin (it stores
// them raw), so the methods below return the first list of maps found in the
// response. Capture a real sample and build typed models from it.
//
// This is a third-party site: you can route it through your own proxy/Worker
// later by passing [baseUrl] - nothing else in the app has to change.
// ---------------------------------------------------------------------------
class YsscoresSource {
  YsscoresSource({Dio? dio, String? baseUrl})
      : _dio = dio ?? Dio(),
        _baseUrl = (baseUrl ?? defaultBase).replaceAll(RegExp(r'/+$'), '') {
    _dio.options
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 15)
      ..headers = {
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'Accept-Language': 'ar,en-US;q=0.9,en;q=0.8',
        'Referer': 'https://www.ysscores.com/ar/index',
        'X-Requested-With': 'XMLHttpRequest',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/129.0.0.0 Mobile Safari/537.36',
      };
  }

  static const String defaultBase = 'https://www.ysscores.com/ar';

  final Dio _dio;
  final String _baseUrl;

  /// League table rows for the league of match [matchId].
  Future<List<Map<String, dynamic>>> leagueRank(int matchId) async =>
      firstMapList(await _get('get_league_rank', matchId));

  /// News items for match [matchId].
  Future<List<Map<String, dynamic>>> matchNews(int matchId) async =>
      firstMapList(await _get('get_match_news', matchId));

  /// Raw payloads (shape differs from the Worker endpoints).
  Future<dynamic> rawLeagueRank(int matchId) => _get('get_league_rank', matchId);
  Future<dynamic> rawMatchNews(int matchId) => _get('get_match_news', matchId);
  Future<dynamic> rawLineup(int matchId) => _get('match_lineup', matchId);
  Future<dynamic> rawEvents(int matchId) => _get('get_match_events', matchId);

  /// Depth-first search for the first non-empty List<Map> in a JSON tree.
  static List<Map<String, dynamic>> firstMapList(dynamic node) {
    if (node is List) {
      final maps = node.whereType<Map>().toList();
      if (maps.isNotEmpty && maps.length == node.length) {
        return maps.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      for (final e in node) {
        final r = firstMapList(e);
        if (r.isNotEmpty) return r;
      }
    } else if (node is Map) {
      for (final v in node.values) {
        final r = firstMapList(v);
        if (r.isNotEmpty) return r;
      }
    }
    return const [];
  }

  Future<dynamic> _get(String path, int matchId) async {
    try {
      final res = await _dio.get<dynamic>(
        '$_baseUrl/$path',
        queryParameters: {'match_code': matchId},
      );
      var body = res.data;
      if (body is String) body = jsonDecode(body);
      return body;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Network error');
    } on FormatException {
      throw ApiException('Invalid JSON from source');
    }
  }
}

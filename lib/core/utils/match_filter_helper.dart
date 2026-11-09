import 'package:flutter/foundation.dart';

import '../../data/models/league_model.dart';
import '../../data/models/match_model.dart';
import '../../data/models/team_model.dart';
import '../services/league_resolver_service.dart';

/// Checks if a match involves one of the user's favorite/followed teams.
bool isFavoriteTeamMatch(
  MatchModel m,
  List<String> selectedTeamIds,
  List<TeamModel> allTeams,
) {
  if (selectedTeamIds.isEmpty) return false;

  final homeId = m.homeTeam.rowId?.toString() ?? '';
  final awayId = m.awayTeam.rowId?.toString() ?? '';
  final homeTitle = m.homeTeam.title.trim().toLowerCase();
  final awayTitle = m.awayTeam.title.trim().toLowerCase();

  // 1. Direct ID match
  if (selectedTeamIds.contains(homeId) || selectedTeamIds.contains(awayId)) {
    return true;
  }

  // 2. Arabic & English name match from available teams
  final selectedTeams = allTeams
      .where((t) => selectedTeamIds.contains(t.id))
      .toList();

  for (final team in selectedTeams) {
    final name = team.name.trim().toLowerCase();
    final nameEn = team.nameEn.trim().toLowerCase();
    if (name.isNotEmpty &&
        (homeTitle.contains(name) ||
            name.contains(homeTitle) ||
            awayTitle.contains(name) ||
            name.contains(awayTitle))) {
      return true;
    }
    if (nameEn.isNotEmpty &&
        (homeTitle.contains(nameEn) || awayTitle.contains(nameEn))) {
      return true;
    }
  }

  // 3. Fallback check on raw selectedTeamIds (e.g. 'ahly', 'liverpool', 'barcelona')
  for (final id in selectedTeamIds) {
    final idLower = id.toLowerCase().replaceAll('_', ' ');
    if (idLower.isNotEmpty &&
        (homeTitle.contains(idLower) || awayTitle.contains(idLower))) {
      return true;
    }
  }

  return false;
}

/// Checks if a match belongs to one of the user's favorite/followed leagues.
/// Matches by ID first, with a fallback on normalized Arabic and English names
/// to bridge any inconsistencies across API responses.
bool isFavoriteLeagueMatch(
  MatchModel m,
  List<String> selectedLeagueIds,
  List<LeagueModel> allLeagues,
) {
  if (selectedLeagueIds.isEmpty) return false;

  // 1. Resolve via LeagueResolverService (normalizes base names, cuts stage suffix, handles cached IDs)
  final resolvedLeagueId = LeagueResolverService.resolveToOnboardingLeagueId(
    champId: m.championship.id,
    champTitle: m.championship.title,
    allLeagues: allLeagues,
  );
  if (resolvedLeagueId != null &&
      selectedLeagueIds.contains(resolvedLeagueId)) {
    return true;
  }

  final champId = m.championship.id?.toString().trim().toLowerCase() ?? '';
  final champTitle = m.championship.title.trim().toLowerCase();

  // 2. Direct ID match
  if (champId.isNotEmpty &&
      selectedLeagueIds.any((id) => id.toLowerCase() == champId)) {
    return true;
  }

  // 2. Arabic & English name match from Onboarding leagues
  final selectedLeagues = allLeagues
      .where((l) => selectedLeagueIds.contains(l.id))
      .toList();

  for (final league in selectedLeagues) {
    final name = league.name.trim().toLowerCase();
    final nameEn = league.nameEn.trim().toLowerCase();

    if (name.isNotEmpty &&
        (champTitle.contains(name) || name.contains(champTitle))) {
      return true;
    }

    if (nameEn.isNotEmpty &&
        (champTitle.contains(nameEn) || nameEn.contains(champTitle))) {
      return true;
    }

    final nameRoots = name
        .replaceAll('الممتاز', '')
        .replaceAll('للمحترفين', '')
        .trim();
    if (nameRoots.length >= 5 && champTitle.contains(nameRoots)) {
      return true;
    }
  }

  // 3. Documented fallback on common league identifiers in selectedLeagueIds
  for (final id in selectedLeagueIds) {
    final idLower = id.toLowerCase();
    if (idLower == 'eng_1' &&
        (champTitle.contains('إنجليزي') || champTitle.contains('premier'))) {
      return true;
    }
    if (idLower == 'esp_1' &&
        (champTitle.contains('إسباني') ||
            champTitle.contains('la liga') ||
            champTitle.contains('laliga'))) {
      return true;
    }
    if (idLower == 'ita_1' &&
        (champTitle.contains('إيطالي') || champTitle.contains('serie a'))) {
      return true;
    }
    if (idLower == 'ger_1' &&
        (champTitle.contains('ألماني') || champTitle.contains('bundesliga'))) {
      return true;
    }
    if (idLower == 'fra_1' &&
        (champTitle.contains('فرنسي') || champTitle.contains('ligue 1'))) {
      return true;
    }
    if (idLower == 'egy_1' &&
        (champTitle.contains('مصري') || champTitle.contains('egypt'))) {
      return true;
    }
    if (idLower == 'sau_1' &&
        (champTitle.contains('روشن') ||
            champTitle.contains('سعودي') ||
            champTitle.contains('saudi'))) {
      return true;
    }
    if (idLower == 'ucl' &&
        (champTitle.contains('أبطال أوروبا') ||
            champTitle.contains('champions league'))) {
      return true;
    }
    if (idLower == 'caf_cl' &&
        (champTitle.contains('أبطال إفريقيا') || champTitle.contains('caf'))) {
      return true;
    }
    if (idLower == 'uel' &&
        (champTitle.contains('الدوري الأوروبي') ||
            champTitle.contains('europa league'))) {
      return true;
    }
  }

  return false;
}

/// Central rule for filtering matches by user's chosen leagues and followed teams.
///
/// Rules:
/// 1. If [selectedLeagueIds] is empty (legacy users or skipped onboarding), returns true.
/// 2. If the match involves a followed team ([selectedTeamIds]), returns true (team selection wins).
/// 3. Returns true if match belongs to one of the [selectedLeagueIds] (matched by ID or normalized name).
/// 4. Otherwise returns false and logs mismatch in debug.
bool isMatchInUserLeaguesOrFollowedTeams({
  required MatchModel match,
  required List<String> selectedLeagueIds,
  required List<String> selectedTeamIds,
  required List<LeagueModel> allLeagues,
  required List<TeamModel> allTeams,
}) {
  // Edge case 1: Legacy users who selected no leagues -> show everything
  if (selectedLeagueIds.isEmpty) {
    return true;
  }

  // Edge case 2: If a followed team plays in a league the user did NOT select,
  // still show that team's match (team selection wins!)
  if (isFavoriteTeamMatch(match, selectedTeamIds, allTeams)) {
    return true;
  }

  // Match by league ID or normalized name fallback
  final isLeagueMatch = isFavoriteLeagueMatch(
    match,
    selectedLeagueIds,
    allLeagues,
  );

  if (!isLeagueMatch && kDebugMode) {
    debugPrint(
      '[LeagueFilter] Match excluded (not in selected leagues): '
      '"${match.homeTeam.title} × ${match.awayTeam.title}" in league "${match.championship.title}" (ID: ${match.championship.id})',
    );
  }

  return isLeagueMatch;
}

/// Applies automatic match prioritization:
/// Priority 1 (Top): Favorite Teams (Live first, then non-live)
/// Priority 2: Favorite Leagues (Live first, then non-live)
/// Priority 3: Other Matches (Live first, then non-live)
///
/// If neither favorite teams nor favorite leagues are selected, natural order is preserved.
List<MatchModel> prioritizeMatches({
  required List<MatchModel> matches,
  required List<String> selectedTeamIds,
  required List<String> selectedLeagueIds,
  required List<TeamModel> allTeams,
  required List<LeagueModel> allLeagues,
}) {
  if (selectedTeamIds.isEmpty && selectedLeagueIds.isEmpty) {
    return matches;
  }

  final liveFavTeams = <MatchModel>[];
  final liveFavLeagues = <MatchModel>[];
  final liveOther = <MatchModel>[];

  final nonLiveFavTeams = <MatchModel>[];
  final nonLiveFavLeagues = <MatchModel>[];
  final nonLiveOther = <MatchModel>[];

  for (final match in matches) {
    final isTeamFav = isFavoriteTeamMatch(match, selectedTeamIds, allTeams);
    final isLeagueFav = !isTeamFav &&
        isFavoriteLeagueMatch(match, selectedLeagueIds, allLeagues);

    if (match.isLive) {
      if (isTeamFav) {
        liveFavTeams.add(match);
      } else if (isLeagueFav) {
        liveFavLeagues.add(match);
      } else {
        liveOther.add(match);
      }
    } else {
      if (isTeamFav) {
        nonLiveFavTeams.add(match);
      } else if (isLeagueFav) {
        nonLiveFavLeagues.add(match);
      } else {
        nonLiveOther.add(match);
      }
    }
  }

  return [
    ...liveFavTeams,
    ...liveFavLeagues,
    ...liveOther,
    ...nonLiveFavTeams,
    ...nonLiveFavLeagues,
    ...nonLiveOther,
  ];
}

/// Helper that selects the featured / hero match according to the 4-tier hierarchy:
/// (a) Live match involving a favorite team
/// (b) Any live match (prefer followed league if available)
/// (c) Next upcoming match involving a favorite team (earliest kickoff)
/// (d) Next upcoming match overall (earliest kickoff, preferring followed league)
/// (e) Fallback to first match
MatchModel? selectHeroMatch({
  required List<MatchModel> matches,
  required List<String> selectedTeamIds,
  required List<String> selectedLeagueIds,
  required List<TeamModel> allTeams,
  required List<LeagueModel> allLeagues,
}) {
  if (matches.isEmpty) return null;

  // (a) Live match involving a favorite team
  final liveFavTeamMatches = matches.where(
    (m) => m.isLive && isFavoriteTeamMatch(m, selectedTeamIds, allTeams),
  );
  if (liveFavTeamMatches.isNotEmpty) return liveFavTeamMatches.first;

  // (b) Any live match (prefer followed league if available)
  final liveMatches = matches.where((m) => m.isLive).toList();
  if (liveMatches.isNotEmpty) {
    final liveFavLeague = liveMatches.where(
      (m) => isFavoriteLeagueMatch(m, selectedLeagueIds, allLeagues),
    );
    if (liveFavLeague.isNotEmpty) return liveFavLeague.first;
    return liveMatches.first;
  }

  // (c) Next upcoming match involving a favorite team (earliest kickoff)
  final upcomingFavTeamMatches = matches.where(
    (m) =>
        !m.isLive &&
        !m.isFinished &&
        isFavoriteTeamMatch(m, selectedTeamIds, allTeams),
  ).toList();
  if (upcomingFavTeamMatches.isNotEmpty) {
    upcomingFavTeamMatches.sort((a, b) {
      final aTime = a.kickoffDateTime ?? DateTime(2099);
      final bTime = b.kickoffDateTime ?? DateTime(2099);
      return aTime.compareTo(bTime);
    });
    return upcomingFavTeamMatches.first;
  }

  // (d) Next upcoming match overall (earliest kickoff, preferring followed league)
  final upcomingMatches =
      matches.where((m) => !m.isLive && !m.isFinished).toList();
  if (upcomingMatches.isNotEmpty) {
    final upcomingFavLeague = upcomingMatches.where(
      (m) => isFavoriteLeagueMatch(m, selectedLeagueIds, allLeagues),
    ).toList();
    if (upcomingFavLeague.isNotEmpty) {
      upcomingFavLeague.sort((a, b) {
        final aTime = a.kickoffDateTime ?? DateTime(2099);
        final bTime = b.kickoffDateTime ?? DateTime(2099);
        return aTime.compareTo(bTime);
      });
      return upcomingFavLeague.first;
    }

    upcomingMatches.sort((a, b) {
      final aTime = a.kickoffDateTime ?? DateTime(2099);
      final bTime = b.kickoffDateTime ?? DateTime(2099);
      return aTime.compareTo(bTime);
    });
    return upcomingMatches.first;
  }

  // (e) Fallback to first match
  return matches.first;
}

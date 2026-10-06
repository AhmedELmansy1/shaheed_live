import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/league_model.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/matches_repository.dart';
import '../../onboarding/providers/onboarding_provider.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiMatchesRepository(dioClient: dioClient);
});

enum HomeTab { yesterday, today, tomorrow, customDate }

class ActiveTabNotifier extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.today;

  void setTab(HomeTab tab) {
    state = tab;
  }
}

final activeTabProvider = NotifierProvider<ActiveTabNotifier, HomeTab>(() {
  return ActiveTabNotifier();
});

class SelectedCustomDateNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void setDate(DateTime? date) {
    state = date;
  }
}

final selectedCustomDateProvider =
    NotifierProvider<SelectedCustomDateNotifier, DateTime?>(() {
      return SelectedCustomDateNotifier();
    });

enum MatchFilterType { upcoming, live, favorites, all }

class MatchFilterNotifier extends Notifier<MatchFilterType> {
  @override
  MatchFilterType build() => MatchFilterType.all;

  void setFilter(MatchFilterType filter) {
    state = filter;
  }
}

final matchFilterProvider =
    NotifierProvider<MatchFilterNotifier, MatchFilterType>(() {
      return MatchFilterNotifier();
    });

/// State notifier managing matches fetching, error handling, and 30-second auto-polling for live matches.
class MatchesNotifier extends AsyncNotifier<List<MatchModel>> {
  Timer? _pollingTimer;

  @override
  FutureOr<List<MatchModel>> build() async {
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    return fetchMatches();
  }

  Future<List<MatchModel>> fetchMatches() async {
    final repository = ref.read(matchesRepositoryProvider);
    final activeTab = ref.read(activeTabProvider);
    final customDate = ref.read(selectedCustomDateProvider);

    final now = DateTime.now();
    late DateTime targetDate;

    switch (activeTab) {
      case HomeTab.yesterday:
        targetDate = now.subtract(const Duration(days: 1));
        break;
      case HomeTab.today:
        targetDate = now;
        break;
      case HomeTab.tomorrow:
        targetDate = now.add(const Duration(days: 1));
        break;
      case HomeTab.customDate:
        targetDate = customDate ?? now;
        break;
    }

    final dateStr = DateFormatter.toApiDateString(targetDate);
    final matches = await repository.getMatchesByDate(dateStr);

    _checkAndSchedulePolling(matches);

    return matches;
  }

  void _checkAndSchedulePolling(List<MatchModel> matches) {
    _pollingTimer?.cancel();

    final hasLiveMatches = matches.any((m) => m.isLive);
    if (hasLiveMatches) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        final updatedMatches = await fetchMatches();
        state = AsyncData(updatedMatches);
      });
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => fetchMatches());
  }
}

final matchesProvider =
    AsyncNotifierProvider<MatchesNotifier, List<MatchModel>>(() {
      return MatchesNotifier();
    });

/// Checks if a match involves one of the user's favorite teams.
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

  // 2. Arabic & English name match
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

/// Checks if a match belongs to one of the user's favorite leagues.
bool isFavoriteLeagueMatch(
  MatchModel m,
  List<String> selectedLeagueIds,
  List<LeagueModel> allLeagues,
) {
  if (selectedLeagueIds.isEmpty) return false;

  final champId = m.championship.id?.toString().trim().toLowerCase() ?? '';
  final champTitle = m.championship.title.trim().toLowerCase();

  // 1. Direct ID match
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

  // 3. Fallback on common league identifiers in selectedLeagueIds
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

/// Provider that returns matches filtered by the active [MatchFilterType]
/// with automatic priority for favorite teams and leagues.
final filteredMatchesProvider = Provider<AsyncValue<List<MatchModel>>>((ref) {
  final rawAsync = ref.watch(matchesProvider);
  final filter = ref.watch(matchFilterProvider);
  final onboardingState = ref.watch(onboardingProvider);
  final selectedTeamIds = onboardingState.selectedTeamIds;
  final selectedLeagueIds = onboardingState.selectedLeagueIds;
  final allTeams = onboardingState.filteredTeams;
  final allLeagues = onboardingState.leagues;

  return rawAsync.whenData((matches) {
    List<MatchModel> result;
    switch (filter) {
      case MatchFilterType.all:
        result = matches;
        break;
      case MatchFilterType.live:
        result = matches.where((m) => m.isLive).toList();
        break;
      case MatchFilterType.upcoming:
        result = matches.where((m) => !m.isLive && !m.isFinished).toList();
        break;
      case MatchFilterType.favorites:
        if (selectedTeamIds.isEmpty && selectedLeagueIds.isEmpty) {
          return [];
        }
        final favMatches = matches.where((m) {
          return isFavoriteTeamMatch(m, selectedTeamIds, allTeams) ||
              isFavoriteLeagueMatch(m, selectedLeagueIds, allLeagues);
        }).toList();

        return prioritizeMatches(
          matches: favMatches,
          selectedTeamIds: selectedTeamIds,
          selectedLeagueIds: selectedLeagueIds,
          allTeams: allTeams,
          allLeagues: allLeagues,
        );
    }

    return prioritizeMatches(
      matches: result,
      selectedTeamIds: selectedTeamIds,
      selectedLeagueIds: selectedLeagueIds,
      allTeams: allTeams,
      allLeagues: allLeagues,
    );
  });
});

/// Data structure representing a championship/league group on the Home screen.
class LeagueGroupData {
  final String leagueTitle;
  final String? leagueLogo;
  final bool isFollowed;
  final List<MatchModel> matches;

  const LeagueGroupData({
    required this.leagueTitle,
    required this.leagueLogo,
    required this.isFollowed,
    required this.matches,
  });
}

/// Comprehensive, pre-sorted data structure for the Home screen presentation layer.
class HomeSectionData {
  final MatchModel? heroMatch;
  final List<MatchModel> favoriteMatches; // Matches of user's favorite teams
  final List<LeagueGroupData> leagueGroups; // Followed leagues first!
  final List<MatchModel> liveMatches;
  final List<MatchModel> allFilteredMatches;

  const HomeSectionData({
    required this.heroMatch,
    required this.favoriteMatches,
    required this.leagueGroups,
    required this.liveMatches,
    required this.allFilteredMatches,
  });

  bool get isEmpty => allFilteredMatches.isEmpty;
}

/// Helper that selects the featured / hero match according to the 4-tier hierarchy:
/// (a) Live match involving a favorite team
/// (b) Any live match
/// (c) Next upcoming match involving a favorite team (earliest kickoff)
/// (d) Next upcoming match overall (earliest kickoff)
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
    (m) => !m.isLive && !m.isFinished && isFavoriteTeamMatch(m, selectedTeamIds, allTeams),
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
  final upcomingMatches = matches.where((m) => !m.isLive && !m.isFinished).toList();
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

/// Provider that computes and memoizes structured sections for the Home screen:
/// - Hero match with priority
/// - "مبارياتك" section for user favorite teams
/// - Grouped leagues below, with user's followed leagues ordered FIRST
final homeSectionDataProvider = Provider<AsyncValue<HomeSectionData>>((ref) {
  final filteredAsync = ref.watch(filteredMatchesProvider);
  final onboardingState = ref.watch(onboardingProvider);
  final selectedTeamIds = onboardingState.selectedTeamIds;
  final selectedLeagueIds = onboardingState.selectedLeagueIds;
  final allTeams = onboardingState.filteredTeams;
  final allLeagues = onboardingState.leagues;

  return filteredAsync.whenData((matches) {
    if (matches.isEmpty) {
      return const HomeSectionData(
        heroMatch: null,
        favoriteMatches: [],
        leagueGroups: [],
        liveMatches: [],
        allFilteredMatches: [],
      );
    }

    // 1. Hero match
    final heroMatch = selectHeroMatch(
      matches: matches,
      selectedTeamIds: selectedTeamIds,
      selectedLeagueIds: selectedLeagueIds,
      allTeams: allTeams,
      allLeagues: allLeagues,
    );

    // 2. Favorite team matches (for "مبارياتك" top section)
    final favoriteMatches = selectedTeamIds.isNotEmpty
        ? matches
            .where((m) => isFavoriteTeamMatch(m, selectedTeamIds, allTeams))
            .toList()
        : <MatchModel>[];

    // 3. Rest of matches (to be grouped by league)
    // Avoid duplicating favorite team matches if they're already in the top section
    final restMatches = favoriteMatches.isNotEmpty
        ? matches.where((m) => !favoriteMatches.contains(m)).toList()
        : matches;

    // 4. Group rest of matches by championship
    final Map<String, List<MatchModel>> rawGroups = {};
    for (final m in restMatches) {
      rawGroups.putIfAbsent(m.championship.title, () => []).add(m);
    }

    // 5. Build LeagueGroupData and order followed leagues FIRST
    final leagueGroups = rawGroups.entries.map((entry) {
      final title = entry.key;
      final groupMatches = entry.value;
      final logo = groupMatches.isNotEmpty ? groupMatches.first.championship.image : null;
      final isFollowed = isFavoriteLeagueMatch(groupMatches.first, selectedLeagueIds, allLeagues);

      return LeagueGroupData(
        leagueTitle: title,
        leagueLogo: logo,
        isFollowed: isFollowed,
        matches: groupMatches,
      );
    }).toList();

    // Sort: followed leagues first!
    leagueGroups.sort((a, b) {
      if (a.isFollowed && !b.isFollowed) return -1;
      if (!a.isFollowed && b.isFollowed) return 1;

      // Secondary: leagues with active live matches come first
      final aHasLive = a.matches.any((m) => m.isLive);
      final bHasLive = b.matches.any((m) => m.isLive);
      if (aHasLive && !bHasLive) return -1;
      if (!aHasLive && bHasLive) return 1;

      return 0; // maintain natural order
    });

    final liveMatches = matches.where((m) => m.isLive).toList();

    return HomeSectionData(
      heroMatch: heroMatch,
      favoriteMatches: favoriteMatches,
      leagueGroups: leagueGroups,
      liveMatches: liveMatches,
      allFilteredMatches: matches,
    );
  });
});

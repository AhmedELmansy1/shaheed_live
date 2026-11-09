import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/services/league_resolver_service.dart';
import '../../../core/services/team_resolver_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/match_filter_helper.dart';
import '../../../data/cache/matches_cache_service.dart';
import '../../../data/models/match_model.dart';
import '../../../data/repositories/matches_repository.dart';
import '../../onboarding/providers/onboarding_provider.dart';

export '../../../core/utils/match_filter_helper.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final matchesCacheServiceProvider = Provider<MatchesCacheService?>((ref) {
  return MatchesCacheService.currentInstance;
});

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final cacheService = ref.watch(matchesCacheServiceProvider);
  return ApiMatchesRepository(dioClient: dioClient, cacheService: cacheService);
});

/// Indicator whether current displayed matches are loaded from stale/offline cache
class OfflineFallbackNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setOffline(bool value) => state = value;
}

final offlineFallbackProvider =
    NotifierProvider<OfflineFallbackNotifier, bool>(() {
  return OfflineFallbackNotifier();
});

/// Generic date-based matches provider for looking up fixtures by YYYY-MM-DD.
final matchesByDateProvider =
    FutureProvider.family<List<MatchModel>, String>((ref, dateStr) async {
  final repo = ref.watch(matchesRepositoryProvider);
  return repo.getMatchesByDate(dateStr);
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

enum MatchFilterType { upcoming, live, finished, favorites, all }

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

/// State notifier managing matches fetching, error handling, Stale-While-Revalidate caching,
/// and 30-second auto-polling for live matches.
class MatchesNotifier extends AsyncNotifier<List<MatchModel>> {
  Timer? _pollingTimer;

  String _getDateStr(HomeTab tab, DateTime? customDate) {
    final now = DateTime.now();
    late DateTime targetDate;

    switch (tab) {
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
    return DateFormatter.toApiDateString(targetDate);
  }

  Future<void> _processMatches(List<MatchModel> matches) async {
    final onboardingState = ref.read(onboardingProvider);
    final allTeams = onboardingState.filteredTeams.isNotEmpty
        ? onboardingState.filteredTeams
        : ref.read(onboardingRepositoryProvider).getPopularTeams();
    TeamResolverService.updateMappingsFromMatches(matches, allTeams);
    final allLeagues = onboardingState.leagues.isNotEmpty
        ? onboardingState.leagues
        : await ref.read(onboardingRepositoryProvider).getPopularLeagues();
    LeagueResolverService.updateMappingsFromMatches(
      matches,
      allLeagues,
    );

    assert(() {
      for (var i = 0; i < matches.length && i < 3; i++) {
        final m = matches[i];
        DateFormatter.debugLogKickoff(m.id, m.matchDate, m.matchTime);
      }
      return true;
    }());
  }

  @override
  FutureOr<List<MatchModel>> build() async {
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    final activeTab = ref.watch(activeTabProvider);
    final customDate = ref.watch(selectedCustomDateProvider);
    final dateStr = _getDateStr(activeTab, customDate);

    // Stale-While-Revalidate step 1: Check if local cache exists
    final cacheService = await MatchesCacheService.getInstance();
    final cached = cacheService.getCachedMatches(dateStr);

    if (cached != null) {
      await _processMatches(cached.matches);
      _checkAndSchedulePolling(cached.matches);

      // Revalidate in background if cache is expired or if matches are currently live
      final hasLive = cached.matches.any((m) => m.isLive);
      if (cached.isExpired || hasLive) {
        Future.microtask(() => _revalidate(dateStr, cacheService));
      }

      // Return instantly without blocking UI or showing skeleton!
      return cached.matches;
    }

    // No cache found: fetch fresh
    return fetchMatches(forceRefresh: false);
  }

  Future<void> _revalidate(String dateStr, MatchesCacheService cacheService) async {
    try {
      final repository = ref.read(matchesRepositoryProvider);
      final freshMatches = await repository.getMatchesByDate(dateStr, forceRefresh: true);
      await _processMatches(freshMatches);
      ref.read(offlineFallbackProvider.notifier).setOffline(false);
      state = AsyncData(freshMatches);
      _checkAndSchedulePolling(freshMatches);
    } catch (e) {
      debugPrint('[MatchesNotifier] Background revalidate offline/failed: $e');
      ref.read(offlineFallbackProvider.notifier).setOffline(true);
    }
  }

  Future<List<MatchModel>> fetchMatches({bool forceRefresh = false}) async {
    final repository = ref.read(matchesRepositoryProvider);
    final activeTab = ref.read(activeTabProvider);
    final customDate = ref.read(selectedCustomDateProvider);
    final dateStr = _getDateStr(activeTab, customDate);

    final matches = await repository.getMatchesByDate(dateStr, forceRefresh: forceRefresh);
    await _processMatches(matches);
    ref.read(offlineFallbackProvider.notifier).setOffline(false);
    _checkAndSchedulePolling(matches);

    return matches;
  }

  void _checkAndSchedulePolling(List<MatchModel> matches) {
    _pollingTimer?.cancel();

    final hasLiveMatches = matches.any((m) => m.isLive);
    if (hasLiveMatches) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        try {
          final updatedMatches = await fetchMatches(forceRefresh: true);
          state = AsyncData(updatedMatches);
        } catch (_) {}
      });
    }
  }

  Future<void> refresh({bool forceRefresh = true}) async {
    final activeTab = ref.read(activeTabProvider);
    final customDate = ref.read(selectedCustomDateProvider);
    final dateStr = _getDateStr(activeTab, customDate);

    if (forceRefresh) {
      final cacheService = await MatchesCacheService.getInstance();
      await cacheService.invalidateMatches(dateStr);
    }

    // Only transition to AsyncLoading if there is no existing data
    if (!state.hasValue) {
      state = const AsyncLoading();
    }

    try {
      final matches = await fetchMatches(forceRefresh: forceRefresh);
      state = AsyncData(matches);
    } catch (e, st) {
      // If we already had cached data displayed, preserve it and flag offline
      if (state.hasValue && state.value!.isNotEmpty) {
        ref.read(offlineFallbackProvider.notifier).setOffline(true);
      } else {
        state = AsyncError(e, st);
      }
    }
  }
}

final matchesProvider =
    AsyncNotifierProvider<MatchesNotifier, List<MatchModel>>(() {
      return MatchesNotifier();
    });

/// Provider that returns matches filtered by the active [MatchFilterType]
/// and strictly constrained to user's selected leagues (with team selection winning),
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
    // 1. Central Leagues-Only Filter:
    // Only matches belonging to user's chosen leagues are retained.
    // Edge case: if a followed team plays in a non-selected league, that match
    // is still retained (team selection wins!).
    // Edge case: if user selected no leagues (legacy), all matches are retained.
    final leaguesOnlyMatches = matches.where((m) {
      return isMatchInUserLeaguesOrFollowedTeams(
        match: m,
        selectedLeagueIds: selectedLeagueIds,
        selectedTeamIds: selectedTeamIds,
        allLeagues: allLeagues,
        allTeams: allTeams,
      );
    }).toList();

    List<MatchModel> result;
    switch (filter) {
      case MatchFilterType.all:
        result = leaguesOnlyMatches;
        break;
      case MatchFilterType.live:
        result = leaguesOnlyMatches.where((m) => m.isLive).toList();
        break;
      case MatchFilterType.upcoming:
        result =
            leaguesOnlyMatches.where((m) => !m.isLive && !m.isFinished).toList();
        break;
      case MatchFilterType.finished:
        result = leaguesOnlyMatches.where((m) => m.isFinished).toList();
        break;
      case MatchFilterType.favorites:
        if (selectedTeamIds.isEmpty && selectedLeagueIds.isEmpty) {
          return [];
        }
        final favMatches = leaguesOnlyMatches.where((m) {
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

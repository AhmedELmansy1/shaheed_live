import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/league_resolver_service.dart';
import '../../../core/services/team_resolver_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/match_filter_helper.dart';
import '../../../data/cache/matches_cache_service.dart';
import '../../../data/models/league_model.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/matches_repository.dart';
import '../../match_details/providers/match_stream_provider.dart';
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

enum HomeFeedScope { myMatches, allMatches }

class HomeFeedScopeNotifier extends Notifier<HomeFeedScope> {
  static const String _prefKey = 'home_feed_scope_mode';

  @override
  HomeFeedScope build() {
    // Default view: ALWAYS all matches across all leagues
    Future.microtask(() => migrateAndLoad());
    return HomeFeedScope.allMatches;
  }

  Future<void> migrateAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    // Explicit migration: migrate any stored 'myMatches' mode to 'allMatches'
    if (saved == 'myMatches' || saved == 'my_matches') {
      debugPrint('[HomeFeedScopeNotifier] Migrating stored myMatches to allMatches');
      await prefs.setString(_prefKey, 'allMatches');
      state = HomeFeedScope.allMatches;
    }
  }

  Future<void> toggleMyMatches() async {
    final next = state == HomeFeedScope.myMatches
        ? HomeFeedScope.allMatches
        : HomeFeedScope.myMatches;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, next.name);
  }

  Future<void> setScope(HomeFeedScope scope) async {
    if (state == scope) return;
    state = scope;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, scope.name);
  }
}

final homeFeedScopeProvider =
    NotifierProvider<HomeFeedScopeNotifier, HomeFeedScope>(() {
  return HomeFeedScopeNotifier();
});

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
    final List<TeamModel> allTeams = onboardingState.filteredTeams.isNotEmpty
        ? onboardingState.filteredTeams
        : await ref.read(onboardingRepositoryProvider).getPopularTeams();
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

class ChannelFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setChannel(String? channel) => state = channel;
}

/// Provider for active Channel filter (e.g. 'beIN Sports 1 HD')
final selectedChannelFilterProvider =
    NotifierProvider<ChannelFilterNotifier, String?>(() => ChannelFilterNotifier());

class CommentatorFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setCommentator(String? commentator) => state = commentator;
}

/// Provider for active Commentator filter (e.g. 'عصام الشوالي')
final selectedCommentatorFilterProvider =
    NotifierProvider<CommentatorFilterNotifier, String?>(() => CommentatorFilterNotifier());

/// Extracts active broadcast channels available in current matches
final availableChannelsProvider = Provider<List<String>>((ref) {
  final matchesAsync = ref.watch(matchesProvider);
  return matchesAsync.maybeWhen(
    data: (matches) {
      final channels = <String>{};
      for (final m in matches) {
        if (m.channel != null && m.channel!.trim().isNotEmpty) {
          channels.add(m.channel!.trim());
        }
      }
      if (channels.isEmpty) {
        return const [
          'beIN Sports 1 HD',
          'beIN Sports 2 HD',
          'OnTime Sports 1',
          'OnTime Sports 2',
          'SSC Sports 1 HD',
          'الكأس HD',
        ];
      }
      return channels.toList()..sort();
    },
    orElse: () => const [
      'beIN Sports 1 HD',
      'OnTime Sports 1',
      'SSC Sports 1 HD',
    ],
  );
});

/// Extracts active commentators available in current matches
final availableCommentatorsProvider = Provider<List<String>>((ref) {
  final matchesAsync = ref.watch(matchesProvider);
  return matchesAsync.maybeWhen(
    data: (matches) {
      final commentators = <String>{};
      for (final m in matches) {
        if (m.commentator != null && m.commentator!.trim().isNotEmpty) {
          commentators.add(m.commentator!.trim());
        }
      }
      if (commentators.isEmpty) {
        return const [
          'عصام الشوالي',
          'فهد العتيبي',
          'حفيظ دراجي',
          'خليل البلوشي',
          'فارس عوض',
          'مدحت شلبي',
          'أيمن الكاشف',
        ];
      }
      return commentators.toList()..sort();
    },
    orElse: () => const [
      'عصام الشوالي',
      'فهد العتيبي',
      'حفيظ دراجي',
      'خليل البلوشي',
      'فارس عوض',
    ],
  );
});

/// Provider that returns matches filtered by the active [MatchFilterType]
/// and strictly constrained to user's selected leagues (with team selection winning),
/// with automatic priority for favorite teams and leagues.
final filteredMatchesProvider = Provider<AsyncValue<List<MatchModel>>>((ref) {
  final rawAsync = ref.watch(matchesProvider);
  final filter = ref.watch(matchFilterProvider);
  final scope = ref.watch(homeFeedScopeProvider);
  final onboardingState = ref.watch(onboardingProvider);
  final selectedTeamIds = onboardingState.selectedTeamIds;
  final selectedLeagueIds = onboardingState.selectedLeagueIds;
  final allTeams = onboardingState.filteredTeams;
  final allLeagues = onboardingState.leagues;

  return rawAsync.whenData((matches) {
    final hasSelections =
        selectedLeagueIds.isNotEmpty || selectedTeamIds.isNotEmpty;

    // Scope filter:
    // When in myMatches mode and user has selections, retain ONLY matches of user's chosen leagues/teams.
    // When in allMatches mode (or if user selected nothing), retain all matches.
    final scopedMatches = (scope == HomeFeedScope.myMatches && hasSelections)
        ? matches.where((m) {
            return isMatchInUserLeaguesOrFollowedTeams(
              match: m,
              selectedLeagueIds: selectedLeagueIds,
              selectedTeamIds: selectedTeamIds,
              allLeagues: allLeagues,
              allTeams: allTeams,
            );
          }).toList()
        : matches;

    List<MatchModel> result;
    switch (filter) {
      case MatchFilterType.all:
        result = scopedMatches;
        break;
      case MatchFilterType.live:
        result = scopedMatches.where((m) => m.isLive).toList();
        break;
      case MatchFilterType.upcoming:
        result =
            scopedMatches.where((m) => !m.isLive && !m.isFinished).toList();
        break;
      case MatchFilterType.finished:
        result = scopedMatches.where((m) => m.isFinished).toList();
        break;
      case MatchFilterType.favorites:
        if (selectedTeamIds.isEmpty && selectedLeagueIds.isEmpty) {
          return [];
        }
        final favMatches = scopedMatches.where((m) {
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

    final selectedChannel = ref.watch(selectedChannelFilterProvider);
    final selectedCommentator = ref.watch(selectedCommentatorFilterProvider);

    var filteredList = result;
    if (selectedChannel != null && selectedChannel.trim().isNotEmpty) {
      final chLower = selectedChannel.trim().toLowerCase();
      filteredList = filteredList.where((m) {
        final mChannel = m.channel?.trim().toLowerCase() ?? '';
        final badge = m.adminBadge?.trim().toLowerCase() ?? '';
        return mChannel.contains(chLower) ||
            chLower.contains(mChannel) ||
            badge.contains(chLower);
      }).toList();
    }

    if (selectedCommentator != null && selectedCommentator.trim().isNotEmpty) {
      final commLower = selectedCommentator.trim().toLowerCase();
      filteredList = filteredList.where((m) {
        final mComm = m.commentator?.trim().toLowerCase() ?? '';
        final badge = m.adminBadge?.trim().toLowerCase() ?? '';
        return mComm.contains(commLower) ||
            commLower.contains(mComm) ||
            badge.contains(commLower);
      }).toList();
    }

    return prioritizeMatches(
      matches: filteredList,
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
  final bool isPopular;
  final int displayOrder;
  final List<MatchModel> matches;

  const LeagueGroupData({
    required this.leagueTitle,
    required this.leagueLogo,
    required this.isFollowed,
    this.isPopular = false,
    this.displayOrder = 100,
    required this.matches,
  });
}

/// Comprehensive, pre-sorted data structure for the Home screen presentation layer.
class HomeSectionData {
  final MatchModel? heroMatch;
  final List<MatchModel> favoriteMatches; // Matches of user's favorite teams
  final List<LeagueGroupData> leagueGroups; // Followed leagues first, then popular!
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

/// Helper function to sort a list of matches: live matches first, then by kickoff time.
List<MatchModel> sortMatchesLiveFirstThenTime(List<MatchModel> list) {
  final sorted = List<MatchModel>.from(list);
  sorted.sort((m1, m2) {
    if (m1.isLive && !m2.isLive) return -1;
    if (!m1.isLive && m2.isLive) return 1;

    // Both live or both non-live: sort by kickoff time
    final t1 = m1.matchTime ?? '';
    final t2 = m2.matchTime ?? '';
    return t1.compareTo(t2);
  });
  return sorted;
}

/// Provider that computes and memoizes structured sections for the Home screen:
/// - Hero match with priority
/// - (a) Pinned section "مبارياتك" for user favorite teams
/// - (b) Matches of followed leagues
/// - (c) Everything else grouped by league (popular leagues first)
/// Inside each group: live matches first, then by kickoff time.
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
    final featuredMatchId = AppConstants.enableStreaming
        ? ref.watch(featuredMatchIdStreamProvider).value
        : null;

    final heroMatch = selectHeroMatch(
      matches: matches,
      selectedTeamIds: selectedTeamIds,
      selectedLeagueIds: selectedLeagueIds,
      allTeams: allTeams,
      allLeagues: allLeagues,
      featuredMatchId: featuredMatchId,
    );

    // 2. Favorite team matches (for pinned "مبارياتك" top section)
    final rawFavorites = selectedTeamIds.isNotEmpty
        ? matches
            .where((m) => isFavoriteTeamMatch(m, selectedTeamIds, allTeams))
            .toList()
        : <MatchModel>[];
    final favoriteMatches = sortMatchesLiveFirstThenTime(rawFavorites);

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

    // 5. Build LeagueGroupData: inside each group, live matches first then kickoff time
    final leagueGroups = rawGroups.entries.map((entry) {
      final title = entry.key;
      final groupMatches = sortMatchesLiveFirstThenTime(entry.value);
      final firstMatch = groupMatches.first;
      final logo = firstMatch.championship.image;
      final isFollowed = isFavoriteLeagueMatch(firstMatch, selectedLeagueIds, allLeagues);

      // Find matching LeagueModel to retrieve isPopular and displayOrder
      final resolvedLeague = allLeagues.cast<LeagueModel?>().firstWhere(
            (l) =>
                l?.id == firstMatch.championship.id.toString() ||
                (l != null && l.name.isNotEmpty && title.contains(l.name)),
            orElse: () => null,
          );

      return LeagueGroupData(
        leagueTitle: title,
        leagueLogo: logo,
        isFollowed: isFollowed,
        isPopular: resolvedLeague?.isPopular ?? false,
        displayOrder: resolvedLeague?.displayOrder ?? 100,
        matches: groupMatches,
      );
    }).toList();

    // 6. Sort league groups:
    // (b) Matches of followed leagues first
    // (c) Remaining leagues: popular leagues first, then by displayOrder, then live matches
    leagueGroups.sort((a, b) {
      // Followed leagues first
      if (a.isFollowed && !b.isFollowed) return -1;
      if (!a.isFollowed && b.isFollowed) return 1;

      // Popular leagues first
      if (a.isPopular && !b.isPopular) return -1;
      if (!a.isPopular && b.isPopular) return 1;

      // Display order (smaller order = higher priority)
      if (a.displayOrder != b.displayOrder) {
        return a.displayOrder.compareTo(b.displayOrder);
      }

      // Active live matches inside league
      final aHasLive = a.matches.any((m) => m.isLive);
      final bHasLive = b.matches.any((m) => m.isLive);
      if (aHasLive && !bHasLive) return -1;
      if (!aHasLive && bHasLive) return 1;

      return a.leagueTitle.compareTo(b.leagueTitle);
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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/services/match_reminder_service.dart';
import '../../../core/services/user_sync_service.dart';
import '../../../data/models/league_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return MockOnboardingRepository();
  }
  final dioClient = ref.watch(dioClientProvider);
  return ApiOnboardingRepository(dioClient: dioClient);
});

class OnboardingState {
  final bool isLoading;
  final String? errorMessage;
  final bool hasCompletedNotificationSetup;
  final bool hasCompletedOnboarding;
  final List<LeagueModel> leagues;
  final List<String> selectedLeagueIds;
  final List<TeamModel> filteredTeams;
  final List<String> selectedTeamIds;

  // Per-league lazy loading maps
  final Map<String, List<TeamModel>> leagueTeams;
  final Map<String, bool> leagueLoading;
  final Map<String, String?> leagueErrors;

  const OnboardingState({
    this.isLoading = true,
    this.errorMessage,
    this.hasCompletedNotificationSetup = false,
    this.hasCompletedOnboarding = false,
    this.leagues = const [],
    this.selectedLeagueIds = const [],
    this.filteredTeams = const [],
    this.selectedTeamIds = const [],
    this.leagueTeams = const {},
    this.leagueLoading = const {},
    this.leagueErrors = const {},
  });

  /// O(1) set lookup for fast selection rendering
  Set<String> get selectedTeamIdsSet => selectedTeamIds.toSet();

  OnboardingState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? hasCompletedNotificationSetup,
    bool? hasCompletedOnboarding,
    List<LeagueModel>? leagues,
    List<String>? selectedLeagueIds,
    List<TeamModel>? filteredTeams,
    List<String>? selectedTeamIds,
    Map<String, List<TeamModel>>? leagueTeams,
    Map<String, bool>? leagueLoading,
    Map<String, String?>? leagueErrors,
  }) {
    return OnboardingState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasCompletedNotificationSetup:
          hasCompletedNotificationSetup ?? this.hasCompletedNotificationSetup,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      leagues: leagues ?? this.leagues,
      selectedLeagueIds: selectedLeagueIds ?? this.selectedLeagueIds,
      filteredTeams: filteredTeams ?? this.filteredTeams,
      selectedTeamIds: selectedTeamIds ?? this.selectedTeamIds,
      leagueTeams: leagueTeams ?? this.leagueTeams,
      leagueLoading: leagueLoading ?? this.leagueLoading,
      leagueErrors: leagueErrors ?? this.leagueErrors,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    Future.microtask(() => init());
    return const OnboardingState(isLoading: true);
  }

  /// Helper to determine if an ID is a legacy synthetic mock ID (e.g. 'egy_1', 'eng_ahly')
  /// Real API IDs from YsScores are positive integers (numeric strings like '937599', '8650').
  static bool isSyntheticId(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return true;
    return int.tryParse(trimmed) == null;
  }

  Future<void> retry() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await init();
  }

  Future<void> init() async {
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      final prefs = await SharedPreferences.getInstance();

      final notifSetup =
          prefs.getBool('hasCompletedNotificationSetup') ?? false;
      final onboardingDone = prefs.getBool('hasCompletedOnboarding') ?? false;

      // 1. Synthetic ID Migration: detect and safely purge legacy mock IDs ('egy_1', etc.)
      final rawLeagues = prefs.getStringList('selected_leagues') ?? [];
      final rawTeams = prefs.getStringList('selected_teams') ?? [];

      final cleanedLeagues = rawLeagues.where((id) => !isSyntheticId(id)).toList();
      final cleanedTeams = rawTeams.where((id) => !isSyntheticId(id)).toList();

      if (cleanedLeagues.length != rawLeagues.length) {
        debugPrint(
          '[OnboardingNotifier] Migrated synthetic league IDs: removed ${rawLeagues.length - cleanedLeagues.length} fake items',
        );
        await prefs.setStringList('selected_leagues', cleanedLeagues);
      }
      if (cleanedTeams.length != rawTeams.length) {
        debugPrint(
          '[OnboardingNotifier] Migrated synthetic team IDs: removed ${rawTeams.length - cleanedTeams.length} fake items',
        );
        await prefs.setStringList('selected_teams', cleanedTeams);
      }

      // 2. Fetch real catalog from API or local cache
      final leagues = await repository.getPopularLeagues();

      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        clearError: true,
        hasCompletedNotificationSetup: notifSetup,
        hasCompletedOnboarding: onboardingDone,
        leagues: leagues,
        selectedLeagueIds: cleanedLeagues,
        selectedTeamIds: cleanedTeams,
      );

      // 3. Load teams for selected leagues if any
      if (cleanedLeagues.isNotEmpty) {
        for (final lId in cleanedLeagues) {
          loadTeamsForLeague(lId);
        }
      }
    } catch (e, st) {
      debugPrint('[OnboardingNotifier] Error in init(): $e\n$st');
      if (ref.mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  void toggleLeagueSelection(String leagueId) {
    final current = List<String>.from(state.selectedLeagueIds);
    if (current.contains(leagueId)) {
      current.remove(leagueId);
    } else {
      current.add(leagueId);
    }
    state = state.copyWith(selectedLeagueIds: current);
  }

  Future<void> saveSelectedLeagues() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_leagues', state.selectedLeagueIds);

    // Kick off lazy loads for each selected league
    for (final leagueId in state.selectedLeagueIds) {
      if (!state.leagueTeams.containsKey(leagueId) || (state.leagueTeams[leagueId]?.isEmpty ?? true)) {
        loadTeamsForLeague(leagueId);
      }
    }

    _pushToFirestoreAsync();
  }

  /// Lazily fetches the full team list for an individual league
  Future<void> loadTeamsForLeague(String leagueId, {bool forceRefresh = false}) async {
    final updatedLoading = Map<String, bool>.from(state.leagueLoading);
    final updatedErrors = Map<String, String?>.from(state.leagueErrors);
    updatedLoading[leagueId] = true;
    updatedErrors.remove(leagueId);
    state = state.copyWith(leagueLoading: updatedLoading, leagueErrors: updatedErrors);

    try {
      final repository = ref.read(onboardingRepositoryProvider);
      final teams = await repository.getTeamsByLeagueId(leagueId, forceRefresh: forceRefresh);

      if (!ref.mounted) return;

      final updatedTeams = Map<String, List<TeamModel>>.from(state.leagueTeams);
      updatedTeams[leagueId] = teams;

      // Update combined filteredTeams
      final allLoadedTeams = <TeamModel>[];
      for (final list in updatedTeams.values) {
        allLoadedTeams.addAll(list);
      }

      final finishLoading = Map<String, bool>.from(state.leagueLoading);
      finishLoading[leagueId] = false;

      state = state.copyWith(
        leagueTeams: updatedTeams,
        leagueLoading: finishLoading,
        filteredTeams: allLoadedTeams,
      );
    } catch (e) {
      debugPrint('[OnboardingNotifier] Error loading teams for league $leagueId: $e');
      if (!ref.mounted) return;
      final finishLoading = Map<String, bool>.from(state.leagueLoading);
      finishLoading[leagueId] = false;
      final finishErrors = Map<String, String?>.from(state.leagueErrors);
      finishErrors[leagueId] = 'تعذر تحميل الفرق لهذا الدوري';

      state = state.copyWith(
        leagueLoading: finishLoading,
        leagueErrors: finishErrors,
      );
    }
  }

  /// Retries fetching teams for a specific league on failure
  Future<void> retryLeagueTeams(String leagueId) async {
    await loadTeamsForLeague(leagueId, forceRefresh: true);
  }

  void toggleTeamSelection(String teamId) {
    final current = Set<String>.from(state.selectedTeamIds);
    if (current.contains(teamId)) {
      current.remove(teamId);
    } else {
      current.add(teamId);
    }
    state = state.copyWith(selectedTeamIds: current.toList());
  }

  /// High-performance instant onboarding completion:
  /// Batches local storage writes, updates state instantly, and offloads network sync to the background.
  Future<void> fastCompleteOnboarding() async {
    final selectedTeams = List<String>.from(state.selectedTeamIds);
    state = state.copyWith(hasCompletedOnboarding: true);

    // 1. Single synchronous/batch persistent write
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_teams', selectedTeams);
    await prefs.setBool('hasCompletedOnboarding', true);

    // 2. Offload network/FCM tasks to background without awaiting
    Future.microtask(() async {
      try {
        final reminderService = ref.read(matchReminderServiceProvider);
        await reminderService.syncTeamTopicSubscriptions(selectedTeams);
      } catch (e) {
        debugPrint('[OnboardingNotifier] Background FCM sync notice: $e');
      }

      _pushToFirestoreAsync();
    });
  }

  Future<void> saveSelectedTeams() async {
    await fastCompleteOnboarding();
  }

  Future<void> completeNotificationSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedNotificationSetup', true);
    state = state.copyWith(hasCompletedNotificationSetup: true);
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_leagues');
    await prefs.remove('selected_teams');
    await prefs.setBool('hasCompletedOnboarding', false);
    state = state.copyWith(
      hasCompletedOnboarding: false,
      selectedLeagueIds: [],
      selectedTeamIds: [],
      leagueTeams: {},
      leagueLoading: {},
      leagueErrors: {},
    );
  }

  void _pushToFirestoreAsync() {
    Future.microtask(() async {
      try {
        final syncService = ref.read(userSyncServiceProvider);
        await syncService.pushLocalToFirestore();
      } catch (e) {
        debugPrint('[OnboardingNotifier] Background Firestore sync failed: $e');
      }
    });
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(() {
  return OnboardingNotifier();
});

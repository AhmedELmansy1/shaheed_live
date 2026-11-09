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

  const OnboardingState({
    this.isLoading = true,
    this.errorMessage,
    this.hasCompletedNotificationSetup = false,
    this.hasCompletedOnboarding = false,
    this.leagues = const [],
    this.selectedLeagueIds = const [],
    this.filteredTeams = const [],
    this.selectedTeamIds = const [],
  });

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
      List<TeamModel> teams = [];
      if (cleanedLeagues.isNotEmpty) {
        teams = await repository.getTeamsForLeagues(cleanedLeagues);
      } else {
        teams = await repository.getPopularTeams();
      }

      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        clearError: true,
        hasCompletedNotificationSetup: notifSetup,
        hasCompletedOnboarding: onboardingDone,
        leagues: leagues,
        selectedLeagueIds: cleanedLeagues,
        filteredTeams: teams,
        selectedTeamIds: cleanedTeams,
      );
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
    final repository = ref.read(onboardingRepositoryProvider);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_leagues', state.selectedLeagueIds);

    // Load teams matching selected leagues
    final teams = await repository.getTeamsForLeagues(state.selectedLeagueIds);
    state = state.copyWith(filteredTeams: teams);

    // Sync updated leagues to Firestore in background
    _pushToFirestoreAsync();
  }

  void toggleTeamSelection(String teamId) {
    final current = List<String>.from(state.selectedTeamIds);
    if (current.contains(teamId)) {
      current.remove(teamId);
    } else {
      current.add(teamId);
    }
    state = state.copyWith(selectedTeamIds: current);
  }

  Future<void> saveSelectedTeams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_teams', state.selectedTeamIds);
    await prefs.setBool('hasCompletedOnboarding', true);

    state = state.copyWith(hasCompletedOnboarding: true);

    // Auto-subscribe chosen clubs to FCM team topics (and unsubscribe removed ones)
    try {
      final reminderService = ref.read(matchReminderServiceProvider);
      await reminderService.syncTeamTopicSubscriptions(state.selectedTeamIds);
    } catch (e) {
      debugPrint('[OnboardingNotifier] Error syncing team FCM topics: $e');
    }

    _pushToFirestoreAsync();
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

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/match_reminder_service.dart';
import '../../../core/services/user_sync_service.dart';
import '../../../data/models/league_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return MockOnboardingRepository();
});

class OnboardingState {
  final bool isLoading;
  final bool hasCompletedNotificationSetup;
  final bool hasCompletedOnboarding;
  final List<LeagueModel> leagues;
  final List<String> selectedLeagueIds;
  final List<TeamModel> filteredTeams;
  final List<String> selectedTeamIds;

  const OnboardingState({
    this.isLoading = true,
    this.hasCompletedNotificationSetup = false,
    this.hasCompletedOnboarding = false,
    this.leagues = const [],
    this.selectedLeagueIds = const [],
    this.filteredTeams = const [],
    this.selectedTeamIds = const [],
  });

  OnboardingState copyWith({
    bool? isLoading,
    bool? hasCompletedNotificationSetup,
    bool? hasCompletedOnboarding,
    List<LeagueModel>? leagues,
    List<String>? selectedLeagueIds,
    List<TeamModel>? filteredTeams,
    List<String>? selectedTeamIds,
  }) {
    return OnboardingState(
      isLoading: isLoading ?? this.isLoading,
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
    // ignore: avoid_print
    print('[OnboardingNotifier] build() called.');
    Future.microtask(() => init());
    return const OnboardingState(isLoading: true);
  }

  Future<void> init() async {
    // ignore: avoid_print
    print('[OnboardingNotifier] init() started.');
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      final prefs = await SharedPreferences.getInstance();
      final notifSetup =
          prefs.getBool('hasCompletedNotificationSetup') ?? false;
      final onboardingDone = prefs.getBool('hasCompletedOnboarding') ?? false;
      final savedLeagues = prefs.getStringList('selected_leagues') ?? [];
      final savedTeams = prefs.getStringList('selected_teams') ?? [];

      // ignore: avoid_print
      print('[OnboardingNotifier] Fetching popular leagues from repository...');
      final leagues = await repository.getPopularLeagues();
      // ignore: avoid_print
      print('[OnboardingNotifier] Received ${leagues.length} leagues.');
      List<TeamModel> teams = [];
      if (savedLeagues.isNotEmpty) {
        teams = await repository.getTeamsForLeagues(savedLeagues);
      }

      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        hasCompletedNotificationSetup: notifSetup,
        hasCompletedOnboarding: onboardingDone,
        leagues: leagues,
        selectedLeagueIds: savedLeagues,
        filteredTeams: teams,
        selectedTeamIds: savedTeams,
      );
      // ignore: avoid_print
      print(
        '[OnboardingNotifier] State updated with isLoading: false, leagues: ${state.leagues.length}',
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('[OnboardingNotifier] ERROR IN init(): $e\n$st');
      if (ref.mounted) {
        state = state.copyWith(isLoading: false);
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

    // Fire-and-forget: push selections to Firestore without blocking navigation.
    // This runs asynchronously — if it fails, shared_preferences is still the
    // source of truth and the user can navigate to the home screen immediately.
    _pushToFirestoreAsync();
  }

  /// Pushes local selections to Firestore in the background.
  /// Intentionally not awaited by the caller.
  void _pushToFirestoreAsync() {
    try {
      final syncService = ref.read(userSyncServiceProvider);
      syncService
          .pushLocalToFirestore()
          .then((_) {
            debugPrint(
              '[OnboardingNotifier] Firestore push completed in background.',
            );
          })
          .catchError((e) {
            debugPrint(
              '[OnboardingNotifier] Firestore push failed in background (non-fatal): $e',
            );
          });
    } catch (e) {
      debugPrint(
        '[OnboardingNotifier] Failed to read userSyncServiceProvider (non-fatal): $e',
      );
    }
  }

  Future<void> completeNotificationSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedNotificationSetup', true);

    state = state.copyWith(hasCompletedNotificationSetup: true);
  }

  /// Helper debug method for clearing onboarding state
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasCompletedNotificationSetup');
    await prefs.remove('hasCompletedOnboarding');
    await prefs.remove('selected_leagues');
    await prefs.remove('selected_teams');

    state = const OnboardingState();
    await init();
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(() {
      return OnboardingNotifier();
    });

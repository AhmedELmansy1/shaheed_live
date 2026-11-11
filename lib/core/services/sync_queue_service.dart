import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_ready_provider.dart';
import 'match_reminder_service.dart';
import 'user_sync_service.dart';

class SyncQueueService {
  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isProcessing = false;

  static const String keyPendingOnboardingSync = 'pending_onboarding_sync';
  static const String keyPendingSyncTeams = 'pending_sync_teams';
  static const String keyPendingSyncLeagues = 'pending_sync_leagues';

  SyncQueueService(this._ref);

  /// Checks if there is any pending onboarding/team synchronization.
  Future<bool> hasPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyPendingOnboardingSync) ?? false;
  }

  /// Records that onboarding completion or team/league modification needs cloud sync reconciliation.
  Future<void> enqueueOnboardingSync(
    List<String> teamIds, {
    List<String>? leagueIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyPendingOnboardingSync, true);
    await prefs.setStringList(keyPendingSyncTeams, teamIds);
    if (leagueIds != null) {
      await prefs.setStringList(keyPendingSyncLeagues, leagueIds);
    }
    debugPrint(
      '[SyncQueueService] Enqueued pending sync for ${teamIds.length} teams and ${leagueIds?.length ?? 0} leagues.',
    );
  }

  /// Attempts to reconcile pending FCM topic subscriptions and Firestore user document sync.
  /// Safe to call repeatedly; guarded against concurrent processing.
  Future<bool> processPendingSync({bool force = false}) async {
    if (_isProcessing) {
      debugPrint('[SyncQueueService] Sync already in progress, skipping duplicate call.');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final isPending = prefs.getBool(keyPendingOnboardingSync) ?? false;
    if (!isPending && !force) {
      return true;
    }

    _isProcessing = true;
    try {
      final teams = prefs.getStringList(keyPendingSyncTeams) ??
          prefs.getStringList('selected_teams') ??
          <String>[];
      final leagues = prefs.getStringList(keyPendingSyncLeagues) ??
          prefs.getStringList('selected_leagues') ??
          <String>[];

      // 1. Wait for Firebase to be ready (up to 5 seconds timeout)
      final isFirebaseReady = await _ref
          .read(firebaseReadyProvider.notifier)
          .awaitReady(timeout: const Duration(seconds: 5));

      if (!isFirebaseReady) {
        debugPrint('[SyncQueueService] Firebase not ready yet; postponing sync reconciliation.');
        return false;
      }

      bool fcmSuccess = false;
      bool firestoreSuccess = false;

      // 2. Reconcile FCM topic subscriptions for selected teams & leagues
      try {
        final reminderService = _ref.read(matchReminderServiceProvider);
        await reminderService.syncTeamTopicSubscriptions(teams);
        await reminderService.syncLeagueTopicSubscriptions(leagues);
        fcmSuccess = true;
      } catch (e) {
        debugPrint('[SyncQueueService] FCM topic sync failed: $e');
      }

      // 3. Reconcile Firestore user document
      try {
        final userSync = _ref.read(userSyncServiceProvider);
        await userSync.pushLocalToFirestore();
        firestoreSuccess = true;
      } catch (e) {
        debugPrint('[SyncQueueService] Firestore pushLocalToFirestore failed: $e');
      }

      if (fcmSuccess && firestoreSuccess) {
        await prefs.setBool(keyPendingOnboardingSync, false);
        await prefs.remove(keyPendingSyncTeams);
        await prefs.remove(keyPendingSyncLeagues);
        debugPrint(
          '[SyncQueueService] Successfully reconciled deferred sync for ${teams.length} teams and ${leagues.length} leagues.',
        );
        return true;
      } else {
        debugPrint(
          '[SyncQueueService] Sync reconciliation incomplete (fcm: $fcmSuccess, firestore: $firestoreSuccess). Flag remains pending for retry.',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[SyncQueueService] Unexpected error processing pending sync: $e');
      return false;
    } finally {
      _isProcessing = false;
    }
  }

  /// Starts listening to network connectivity events and retries sync as soon as internet is restored.
  void startConnectivityMonitoring() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) async {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        final pending = await hasPendingSync();
        if (pending) {
          debugPrint('[SyncQueueService] Network connection restored — triggering pending sync reconciliation.');
          await processPendingSync();
        }
      }
    });
  }

  /// Human-readable description of current sync state for diagnostics.
  Future<String> getSyncStatusDescription() async {
    final prefs = await SharedPreferences.getInstance();
    final isPending = prefs.getBool(keyPendingOnboardingSync) ?? false;
    if (!isPending) {
      return 'متزامن بالكامل (Synced)';
    }
    final teams = prefs.getStringList(keyPendingSyncTeams) ?? [];
    return 'معلق — إعادة المحاولة مجدولة (${teams.length} فرق)';
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final service = SyncQueueService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});


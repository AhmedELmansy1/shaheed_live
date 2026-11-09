import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/match_reminder_service.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/services/update_service.dart';
import '../../core/services/user_sync_service.dart';
import '../../firebase_options.dart';

/// Controller responsible for app startup initialization and target route determination.
///
/// Startup sequence:
/// 1. Initialize Firebase (try/catch — non-blocking on failure)
/// 2. Authenticate anonymously via AuthService (try/catch — non-blocking)
/// 3. Pull Firestore data to local if cloud is newer (try/catch — non-blocking)
/// 4. Reschedule all pending match reminders
/// 5. Check remote config and force update
/// 6. Read SharedPreferences for onboarding state
/// 7. Determine target route
class SplashController {
  final Ref _ref;

  SplashController(this._ref);

  /// Performs asynchronous startup tasks and returns target route path.
  Future<String> initializeApp() async {
    // 1. Check or initialize Firebase safely without duplicate calls
    bool firebaseReady = Firebase.apps.isNotEmpty;
    if (!firebaseReady) {
      try {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } catch (_) {
          await Firebase.initializeApp();
        }
        firebaseReady = true;
        debugPrint('[SplashController] Firebase initialized successfully.');
      } catch (e) {
        debugPrint(
          '[SplashController] WARNING: Firebase initialization skipped or failed: $e. '
          'App will run in offline/local-only mode.',
        );
      }
    }

    // 2. Reschedule pending match notifications in background
    Future.microtask(() async {
      try {
        final reminderService = _ref.read(matchReminderServiceProvider);
        await reminderService.rescheduleAllReminders();
        debugPrint(
          '[SplashController] Match reminders successfully rescheduled in background.',
        );
      } catch (e) {
        debugPrint(
          '[SplashController] WARNING: Match reminder reschedule error: $e',
        );
      }
    });

    // 3. Parallelize Auth, Remote Config check, and SharedPreferences reading
    final authFuture = () async {
      if (!firebaseReady) return;
      try {
        final authService = _ref.read(authServiceProvider);
        await authService.ensureAuthenticated();
        // Non-blocking additive Firestore pull
        _ref.read(userSyncServiceProvider).pullFirestoreToLocal().catchError((e) {
          debugPrint(
            '[SplashController] WARNING: Firestore pull sync failed: $e',
          );
        });
      } catch (e) {
        debugPrint('[SplashController] WARNING: Auth service failed: $e');
      }
    }();

    final remoteConfigFuture = () async {
      if (!firebaseReady) return false;
      try {
        final remoteConfig = await _ref
            .read(remoteConfigServiceProvider)
            .fetchInitialConfig();
        final currentVersion = await _ref.read(
          currentAppVersionProvider.future,
        );
        final updateInfo = UpdateService.evaluate(
          currentVersion: currentVersion,
          config: remoteConfig,
        );
        debugPrint(
          '[SplashController] Evaluated AppUpdateInfo: isHardBlocked=${updateInfo.isHardBlocked}, '
          'status=${updateInfo.status}, current="${updateInfo.currentVersion}", latest="${updateInfo.latestVersion}"',
        );
        return updateInfo.isHardBlocked;
      } catch (e) {
        debugPrint(
          '[SplashController] WARNING: Remote config check in splash failed: $e',
        );
        return false;
      }
    }();

    final prefsFuture = SharedPreferences.getInstance();

    final results = await Future.wait([
      authFuture,
      remoteConfigFuture,
      prefsFuture,
    ]);

    final isHardBlocked = results[1] as bool;
    if (isHardBlocked) {
      debugPrint(
        '[SplashController] Hard block detected during startup -> routing to /force-update',
      );
      return '/force-update';
    }

    final prefs = results[2] as SharedPreferences;
    final hasCompletedNotificationSetup =
        prefs.getBool('hasCompletedNotificationSetup') ?? false;
    final hasCompletedOnboarding =
        prefs.getBool('hasCompletedOnboarding') ?? false;

    // 4. Determine onboarding routing destination
    if (!hasCompletedNotificationSetup) {
      return '/onboarding/notifications';
    } else if (!hasCompletedOnboarding) {
      return '/onboarding/leagues';
    } else {
      return '/home';
    }
  }
}

final splashControllerProvider = Provider<SplashController>((ref) {
  return SplashController(ref);
});

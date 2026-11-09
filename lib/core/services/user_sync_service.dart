import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that synchronizes local shared_preferences data with Firestore
/// at `users/{uid}`.
///
/// Design principles:
/// - shared_preferences is ALWAYS the primary local source of truth.
/// - Firestore is an ADDITIVE cloud sync layer — never a hard dependency.
/// - All Firestore operations are wrapped in try/catch and never throw to callers.
/// - Failures log warnings and silently no-op.
///
/// CONFLICT RESOLUTION RULE (plain language):
/// ──────────────────────────────────────────
/// When pulling from Firestore on app startup:
///   • If the Firestore document's `updated_at` timestamp is STRICTLY NEWER
///     than the locally-tracked `last_sync_timestamp` (stored in
///     shared_preferences), Firestore data WINS and overwrites local selections.
///   • Otherwise, local data stays authoritative and will be pushed UP to
///     Firestore on the next sync opportunity.
///
/// Rationale: This handles the case where a returning anonymous session
/// (e.g., after reinstall where Firebase persisted the uid) has more recent
/// cloud data than a fresh local state. In normal operation (single device,
/// continuous session), local and cloud stay in sync via push-after-onboarding,
/// so the conflict path rarely triggers.
class UserSyncService {
  final FirebaseFirestore? _explicitFirestore;
  final FirebaseAuth? _explicitAuth;

  UserSyncService([this._explicitFirestore, this._explicitAuth]);

  FirebaseFirestore? get _firestore {
    if (_explicitFirestore != null) return _explicitFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    if (_explicitAuth != null) return _explicitAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// The Firestore document path for the current user.
  String? get _userDocPath {
    final uid = _auth?.currentUser?.uid;
    if (uid == null) return null;
    return 'users/$uid';
  }

  /// Pushes the current shared_preferences selections to Firestore `users/{uid}`.
  ///
  /// Called fire-and-forget after onboarding completes and on manual "Sync Now".
  /// Never throws.
  Future<void> pushLocalToFirestore() async {
    try {
      final docPath = _userDocPath;
      if (docPath == null) {
        debugPrint(
          '[UserSyncService] pushLocalToFirestore: No authenticated user — skipping.',
        );
        return;
      }

      final fs = _firestore;
      if (fs == null) {
        debugPrint(
          '[UserSyncService] pushLocalToFirestore: Firestore not available — skipping.',
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final selectedLeagues = prefs.getStringList('selected_leagues') ?? [];
      final selectedTeams = prefs.getStringList('selected_teams') ?? [];
      final subscribedTeamTopics =
          prefs.getStringList('subscribed_team_topics') ?? [];

      // Build device info
      String appVersion = 'unknown';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      } catch (_) {
        // PackageInfo can fail in test environments
      }

      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';

      final docRef = fs.doc(docPath);
      final docSnapshot = await docRef.get();

      final data = <String, dynamic>{
        'selected_leagues': selectedLeagues,
        'selected_teams': selectedTeams,
        'subscribed_team_topics': subscribedTeamTopics,
        'updated_at': FieldValue.serverTimestamp(),
        'device_info': {'platform': platform, 'app_version': appVersion},
      };

      // Only set notification_preferences and created_at on first write
      if (!docSnapshot.exists) {
        data['notification_preferences'] = {
          'goal_alerts': true,
          'lineup_alerts': true,
          'match_start_alerts': true,
        };
        data['created_at'] = FieldValue.serverTimestamp();
      }

      await docRef.set(data, SetOptions(merge: true));

      // Update the local last-sync timestamp so pullFirestoreToLocal
      // knows this local state has been synced.
      await prefs.setInt(
        'last_sync_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('[UserSyncService] pushLocalToFirestore: SUCCESS → $docPath');
    } catch (e) {
      debugPrint(
        '[UserSyncService] pushLocalToFirestore: FAILED (non-fatal): $e',
      );
    }
  }

  /// Pulls Firestore `users/{uid}` data and overwrites local shared_preferences
  /// IF the cloud data is strictly newer than the locally-tracked sync timestamp.
  ///
  /// Called during SplashController startup after auth resolves.
  /// Never throws.
  Future<void> pullFirestoreToLocal() async {
    try {
      final docPath = _userDocPath;
      if (docPath == null) {
        debugPrint(
          '[UserSyncService] pullFirestoreToLocal: No authenticated user — skipping.',
        );
        return;
      }

      final fs = _firestore;
      if (fs == null) {
        debugPrint(
          '[UserSyncService] pullFirestoreToLocal: Firestore not available — skipping.',
        );
        return;
      }

      final docRef = fs.doc(docPath);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        debugPrint(
          '[UserSyncService] pullFirestoreToLocal: No Firestore doc exists — skipping.',
        );
        return;
      }

      final cloudData = docSnapshot.data();
      if (cloudData == null) return;

      final prefs = await SharedPreferences.getInstance();
      final localLastSync = prefs.getInt('last_sync_timestamp') ?? 0;

      // Extract cloud updated_at timestamp
      final cloudUpdatedAt = cloudData['updated_at'];
      int cloudTimestampMs = 0;
      if (cloudUpdatedAt is Timestamp) {
        cloudTimestampMs = cloudUpdatedAt.millisecondsSinceEpoch;
      }

      // CONFLICT RESOLUTION: Firestore wins ONLY if its updated_at is
      // strictly newer than the local last-known sync timestamp.
      if (cloudTimestampMs <= localLastSync) {
        debugPrint(
          '[UserSyncService] pullFirestoreToLocal: Local data is current or newer '
          '(local=$localLastSync, cloud=$cloudTimestampMs) — keeping local.',
        );
        return;
      }

      debugPrint(
        '[UserSyncService] pullFirestoreToLocal: Cloud data is NEWER '
        '(local=$localLastSync, cloud=$cloudTimestampMs) — overwriting local.',
      );

      // Overwrite local selections from cloud
      final cloudLeagues =
          (cloudData['selected_leagues'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final cloudTeams =
          (cloudData['selected_teams'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final cloudTopics =
          (cloudData['subscribed_team_topics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      await prefs.setStringList('selected_leagues', cloudLeagues);
      await prefs.setStringList('selected_teams', cloudTeams);
      if (cloudTopics.isNotEmpty) {
        await prefs.setStringList('subscribed_team_topics', cloudTopics);
      }

      // If cloud has selections, mark onboarding as completed locally
      if (cloudLeagues.isNotEmpty && cloudTeams.isNotEmpty) {
        await prefs.setBool('hasCompletedOnboarding', true);
      }

      // Update local sync timestamp to reflect we've consumed cloud data
      await prefs.setInt('last_sync_timestamp', cloudTimestampMs);

      debugPrint(
        '[UserSyncService] pullFirestoreToLocal: SUCCESS — synced ${cloudLeagues.length} leagues, ${cloudTeams.length} teams.',
      );
    } catch (e) {
      debugPrint(
        '[UserSyncService] pullFirestoreToLocal: FAILED (non-fatal): $e',
      );
    }
  }
}

/// Riverpod provider for [UserSyncService].
final userSyncServiceProvider = Provider<UserSyncService>((ref) {
  return UserSyncService();
});

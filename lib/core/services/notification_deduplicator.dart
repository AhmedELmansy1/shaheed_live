import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for deduplicating push notifications between
/// Firebase Cloud Messaging (FCM) and Firestore dual-delivery (`config/app_settings.latest_notification`).
///
/// Guarantees:
/// - One-time display across both channels (FCM-first or Firestore-first).
/// - Persistence across app restarts (cold-start / app-killed safety).
/// - Content-hash + ID matching to bridge different ID representations between Admin SDK and client FCM.
class NotificationDeduplicator {
  static const String keyLastShownId = 'last_shown_notification_id';
  static const String keyRecentIds = 'recent_shown_notification_ids';
  static const String keyRecentHashes = 'recent_shown_notification_hashes';
  static const String keyLastShownTimestamp = 'last_shown_notification_timestamp';

  final SharedPreferences? _explicitPrefs;

  NotificationDeduplicator([this._explicitPrefs]);

  Future<SharedPreferences> _getPrefs() async {
    if (_explicitPrefs != null) return _explicitPrefs;
    return await SharedPreferences.getInstance();
  }

  /// Normalizes message IDs (e.g. `projects/.../messages/12345` -> `12345`).
  static String normalizeId(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.contains('/messages/')) {
      return trimmed.split('/messages/').last;
    }
    return trimmed;
  }

  /// Generates a normalized signature from notification contents.
  static String computeContentHash({
    required String title,
    required String body,
    String? matchId,
  }) {
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    final cleanMatchId = (matchId ?? '').trim();
    return '$cleanTitle|$cleanBody|$cleanMatchId';
  }

  /// Evaluates whether an incoming notification should be displayed.
  /// If `true`, the notification is atomically registered and subsequent
  /// duplicates across FCM or Firestore will be rejected.
  Future<bool> shouldDisplay({
    required String id,
    required String title,
    required String body,
    String? matchId,
    DateTime? timestamp,
  }) async {
    final cleanId = normalizeId(id);
    final contentHash = computeContentHash(
      title: title,
      body: body,
      matchId: matchId,
    );

    final prefs = await _getPrefs();
    final lastShownId = prefs.getString(keyLastShownId) ?? '';
    final recentIds = prefs.getStringList(keyRecentIds) ?? <String>[];
    final recentHashes = prefs.getStringList(keyRecentHashes) ?? <String>[];
    final lastTimestampMs = prefs.getInt(keyLastShownTimestamp) ?? 0;

    // 1. Check ID duplicates
    if (cleanId.isNotEmpty) {
      if (cleanId == lastShownId || recentIds.contains(cleanId)) {
        debugPrint('[NotificationDedupe] Duplicate ID rejected: $cleanId');
        return false;
      }
    }

    // 2. Check Content Hash duplicates
    if (recentHashes.contains(contentHash)) {
      debugPrint('[NotificationDedupe] Duplicate content hash rejected: $contentHash');
      return false;
    }

    // 3. Stale timestamp check (if a notification has a timestamp older than last shown by > 1 hour)
    if (timestamp != null && lastTimestampMs > 0) {
      final msgMs = timestamp.millisecondsSinceEpoch;
      if (msgMs < (lastTimestampMs - const Duration(hours: 1).inMilliseconds)) {
        debugPrint('[NotificationDedupe] Outdated notification rejected: msg=$msgMs, last=$lastTimestampMs');
        return false;
      }
    }

    // 4. Register as displayed
    final updatedIds = <String>[if (cleanId.isNotEmpty) cleanId, ...recentIds];
    if (updatedIds.length > 50) {
      updatedIds.removeRange(50, updatedIds.length);
    }

    final updatedHashes = <String>[contentHash, ...recentHashes];
    if (updatedHashes.length > 50) {
      updatedHashes.removeRange(50, updatedHashes.length);
    }

    final nowMs = timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
    final effectiveLastMs = nowMs > lastTimestampMs ? nowMs : lastTimestampMs;

    if (cleanId.isNotEmpty) {
      await prefs.setString(keyLastShownId, cleanId);
    }
    await prefs.setStringList(keyRecentIds, updatedIds);
    await prefs.setStringList(keyRecentHashes, updatedHashes);
    await prefs.setInt(keyLastShownTimestamp, effectiveLastMs);

    debugPrint('[NotificationDedupe] ✅ Notification accepted and registered: id=$cleanId, hash=$contentHash');
    return true;
  }
}

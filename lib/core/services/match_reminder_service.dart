import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/match_model.dart';
import '../utils/date_formatter.dart';
import 'notification_service.dart';

class RemindedMatchesNotifier extends Notifier<Set<int>> {
  static const String _storageKey = 'match_reminders';

  @override
  Set<int> build() {
    _loadInitialState();
    return {};
  }

  Future<void> _loadInitialState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_storageKey) ?? [];
      final ids = <int>{};
      for (var jsonStr in stored) {
        try {
          final data = jsonDecode(jsonStr);
          if (data['matchId'] != null) {
            ids.add(data['matchId'] as int);
          }
        } catch (_) {}
      }
      state = ids;
      debugPrint(
        '[MatchReminder] Loaded ${ids.length} active match reminders into memory.',
      );
    } catch (e) {
      debugPrint('[MatchReminder] Error loading initial reminders: $e');
    }
  }

  void add(int matchId) {
    state = {...state, matchId};
  }

  void remove(int matchId) {
    state = state.where((id) => id != matchId).toSet();
  }
}

final remindedMatchIdsProvider =
    NotifierProvider<RemindedMatchesNotifier, Set<int>>(() {
      return RemindedMatchesNotifier();
    });

final isReminderSetProvider = Provider.family<bool, int>((ref, matchId) {
  final remindedIds = ref.watch(remindedMatchIdsProvider);
  return remindedIds.contains(matchId);
});

final matchReminderServiceProvider = Provider<MatchReminderService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return MatchReminderService(notificationService, ref);
});

class MatchReminderService {
  final NotificationService _notificationService;
  final Ref _ref;
  static const String _storageKey = 'match_reminders';

  // Deterministic Notification IDs
  static int getConfirmationNotificationId(int matchId) => matchId * 10;
  static int getReminder1HrId(int matchId) => matchId * 10 + 1;
  static int getReminder15MinId(int matchId) => matchId * 10 + 2;

  MatchReminderService(this._notificationService, this._ref);

  Future<void> toggleReminder(MatchModel match) async {
    final matchId = match.matchId;
    if (matchId <= 0) {
      debugPrint('[MatchReminder] Invalid matchId ($matchId). Aborting.');
      return;
    }

    final homeName = match.homeTeam.title;
    final awayName = match.awayTeam.title;
    final compName = match.championship.title;

    debugPrint('[MatchReminder] ========================================');
    debugPrint(
      '[MatchReminder] 🔔 Bell tapped for Match #$matchId: "$homeName × $awayName" ($compName)',
    );

    final prefs = await SharedPreferences.getInstance();
    final storedReminders = prefs.getStringList(_storageKey) ?? [];

    final existingIndex = storedReminders.indexWhere((jsonStr) {
      try {
        final data = jsonDecode(jsonStr);
        return data['matchId'] == matchId;
      } catch (_) {
        return false;
      }
    });

    if (existingIndex != -1) {
      // 1. UNTOGGLE / CANCEL BOTH TIERS
      debugPrint(
        '[MatchReminder] -> State is currently ON. Canceling reminders for Match #$matchId...',
      );
      storedReminders.removeAt(existingIndex);
      await prefs.setStringList(_storageKey, storedReminders);

      _ref.read(remindedMatchIdsProvider.notifier).remove(matchId);

      final pendingBefore = await _notificationService
          .getPendingNotificationRequests();
      debugPrint(
        '[MatchReminder] Pending notifications count before cancellation: ${pendingBefore.length}',
      );

      // Cancel 1-hour tier, 15-min tier, confirmation, and legacy matchId
      final id1Hr = getReminder1HrId(matchId);
      final id15Min = getReminder15MinId(matchId);
      final idConfirm = getConfirmationNotificationId(matchId);

      await _notificationService.cancelNotification(id1Hr);
      await _notificationService.cancelNotification(id15Min);
      await _notificationService.cancelNotification(idConfirm);
      await _notificationService.cancelNotification(matchId);

      final pendingAfter = await _notificationService
          .getPendingNotificationRequests();
      debugPrint(
        '[MatchReminder] Cancelled notification IDs: 1hr (#$id1Hr), 15min (#$id15Min), legacy (#$matchId)',
      );
      debugPrint(
        '[MatchReminder] Pending notifications count after cancellation: ${pendingAfter.length}',
      );

      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(
          'match_${matchId}_events',
        );
        debugPrint(
          '[MatchReminder] FCM unsubscribed from topic: match_${matchId}_events',
        );
      } catch (e) {
        debugPrint('[MatchReminder] FCM unsubscribe error: $e');
      }

      debugPrint(
        '[MatchReminder] Toggle OFF complete. Active reminders: ${storedReminders.length}',
      );
    } else {
      // 2. TOGGLE / SCHEDULE BOTH TIERS (1-Hour & 15-Minutes) + IMMEDIATE CONFIRMATION
      debugPrint(
        '[MatchReminder] -> State is currently OFF. Enabling reminders for Match #$matchId...',
      );

      // Optimistically update memory state immediately for instant UI feedback
      _ref.read(remindedMatchIdsProvider.notifier).add(matchId);

      final reminderData = {
        'matchId': matchId,
        'matchDate': match.matchDate,
        'matchTime': match.matchTime,
        'homeName': homeName,
        'awayName': awayName,
        'competition': compName,
      };

      storedReminders.add(jsonEncode(reminderData));
      await prefs.setStringList(_storageKey, storedReminders);
      debugPrint(
        '[MatchReminder] Stored reminder in SharedPreferences for Match #$matchId.',
      );

      // FEATURE 1: Immediate confirmation system notification in tray
      final confirmId = getConfirmationNotificationId(matchId);
      final confirmTitle = '🔔 تم تفعيل التنبيه';
      final confirmBody = DateFormatter.toArabicNumerals(
        'سيتم تذكيرك بمباراة $homeName × $awayName',
      );
      final reminderPayload = jsonEncode({
        'type': 'match_reminder',
        'matchId': matchId.toString(),
      });

      try {
        await _notificationService.showNotification(
          confirmId,
          confirmTitle,
          confirmBody,
          payload: reminderPayload,
          channelId: NotificationService.channelMatches,
        );
        debugPrint(
          '[MatchReminder] [FEATURE 1] Fired immediate confirmation notification #$confirmId: "$confirmTitle" - "$confirmBody"',
        );
      } catch (e) {
        debugPrint(
          '[MatchReminder] Error showing immediate confirmation notification: $e',
        );
      }

      // SERVER-SIDE DISPATCH: 1-hour and 15-minute reminders, kickoff, and live events
      // are dispatched server-side via shoot_live_watcher over FCM topic `match_{matchId}_events`.
      // This bypasses aggressive OEM background kill policies (e.g., MIUI OP_AUTO_START).
      try {
        final topic = 'match_${matchId}_events';
        debugPrint(
          '[MatchReminder] 📡 Attempting FCM subscribe to topic: $topic...',
        );
        await FirebaseMessaging.instance.subscribeToTopic(topic);
        debugPrint(
          '[MatchReminder] ✅ FCM subscribe SUCCESS for topic: $topic at ${DateTime.now().toIso8601String()}',
        );
      } catch (e, st) {
        debugPrint('[MatchReminder] ❌ FCM subscribe FAILED for Match #$matchId: $e');
        debugPrint('[MatchReminder] StackTrace: $st');
      }

      debugPrint(
        '[MatchReminder] Toggle ON complete. Active reminders: ${storedReminders.length}',
      );
    }
    debugPrint('[MatchReminder] ========================================');
  }

  Future<bool> isReminderSet(int matchId) async {
    final prefs = await SharedPreferences.getInstance();
    final storedReminders = prefs.getStringList(_storageKey) ?? [];

    return storedReminders.any((jsonStr) {
      try {
        final data = jsonDecode(jsonStr);
        return data['matchId'] == matchId;
      } catch (_) {
        return false;
      }
    });
  }

  /// Re-applies all active topic subscriptions (called on token refresh or startup)
  Future<void> reapplyAllTopicSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final storedReminders = prefs.getStringList(_storageKey) ?? [];
    debugPrint(
      '[MatchReminder] 🔄 Re-applying FCM topic subscriptions for ${storedReminders.length} stored reminders...',
    );

    for (var jsonStr in storedReminders) {
      try {
        final data = jsonDecode(jsonStr);
        final matchId = data['matchId'] as int?;
        if (matchId != null && matchId > 0) {
          final topic = 'match_${matchId}_events';
          await FirebaseMessaging.instance.subscribeToTopic(topic);
          debugPrint('[MatchReminder] ✅ Restored FCM topic: $topic');
        }
      } catch (e) {
        debugPrint('[MatchReminder] ❌ Error restoring topic subscription: $e');
      }
    }
  }

  Future<void> rescheduleAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final storedReminders = prefs.getStringList(_storageKey) ?? [];
    final updatedReminders = <String>[];

    debugPrint(
      '[MatchReminder] Syncing ${storedReminders.length} active reminders on startup...',
    );

    final now = tz.TZDateTime.now(tz.local);

    for (var jsonStr in storedReminders) {
      try {
        final data = jsonDecode(jsonStr);
        final matchId = data['matchId'] as int?;
        final date = data['matchDate'] as String?;
        final time = data['matchTime'] as String?;

        if (matchId == null) continue;

        final kickoff = _computeKickoffTime(date, time);

        // Keep reminder active until match is concluded (~3 hours after kickoff)
        if (kickoff == null ||
            kickoff.add(const Duration(hours: 3)).isAfter(now)) {
          updatedReminders.add(jsonStr);
          // Ensure FCM topic subscription is maintained and awaited
          try {
            final topic = 'match_${matchId}_events';
            await FirebaseMessaging.instance.subscribeToTopic(topic);
            debugPrint(
              '[MatchReminder] ✅ Verified active topic subscription: $topic',
            );
          } catch (topicErr) {
            debugPrint(
              '[MatchReminder] ⚠️ Could not verify topic for Match #$matchId: $topicErr',
            );
          }
        }
      } catch (e) {
        debugPrint('[MatchReminder] Error syncing reminder item: $e');
      }
    }

    await prefs.setStringList(_storageKey, updatedReminders);
    _ref.read(remindedMatchIdsProvider.notifier)._loadInitialState();
  }

  tz.TZDateTime? _computeKickoffTime(String? matchDate, String? matchTime) {
    if (matchDate == null ||
        matchTime == null ||
        matchDate.isEmpty ||
        matchTime.isEmpty) {
      return null;
    }
    try {
      final dateParts = matchDate.trim().split('-');
      final timeParts = matchTime.trim().split(':');

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

      final cairoLocation = tz.getLocation('Africa/Cairo');
      final cairoTZDateTime = tz.TZDateTime(
        cairoLocation,
        year,
        month,
        day,
        hour,
        minute,
        second,
      );

      final localDateTime = cairoTZDateTime.toLocal();
      return tz.TZDateTime.from(localDateTime, tz.local);
    } catch (e) {
      debugPrint('[MatchReminder] Error parsing match date/time: $e');
      return null;
    }
  }
}

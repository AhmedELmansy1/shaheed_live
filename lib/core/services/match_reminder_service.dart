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
      debugPrint('[MatchReminder] Loaded ${ids.length} active match reminders into memory.');
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

final remindedMatchIdsProvider = NotifierProvider<RemindedMatchesNotifier, Set<int>>(() {
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
    debugPrint('[MatchReminder] 🔔 Bell tapped for Match #$matchId: "$homeName × $awayName" ($compName)');

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
      debugPrint('[MatchReminder] -> State is currently ON. Canceling reminders for Match #$matchId...');
      storedReminders.removeAt(existingIndex);
      await prefs.setStringList(_storageKey, storedReminders);

      _ref.read(remindedMatchIdsProvider.notifier).remove(matchId);

      final pendingBefore = await _notificationService.getPendingNotificationRequests();
      debugPrint('[MatchReminder] Pending notifications count before cancellation: ${pendingBefore.length}');

      // Cancel 1-hour tier, 15-min tier, confirmation, and legacy matchId
      final id1Hr = getReminder1HrId(matchId);
      final id15Min = getReminder15MinId(matchId);
      final idConfirm = getConfirmationNotificationId(matchId);

      await _notificationService.cancelNotification(id1Hr);
      await _notificationService.cancelNotification(id15Min);
      await _notificationService.cancelNotification(idConfirm);
      await _notificationService.cancelNotification(matchId);

      final pendingAfter = await _notificationService.getPendingNotificationRequests();
      debugPrint('[MatchReminder] Cancelled notification IDs: 1hr (#$id1Hr), 15min (#$id15Min), legacy (#$matchId)');
      debugPrint('[MatchReminder] Pending notifications count after cancellation: ${pendingAfter.length}');

      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic('match_${matchId}_events');
        debugPrint('[MatchReminder] FCM unsubscribed from topic: match_${matchId}_events');
      } catch (e) {
        debugPrint('[MatchReminder] FCM unsubscribe error: $e');
      }

      debugPrint('[MatchReminder] Toggle OFF complete. Active reminders: ${storedReminders.length}');
    } else {
      // 2. TOGGLE / SCHEDULE BOTH TIERS (1-Hour & 15-Minutes) + IMMEDIATE CONFIRMATION
      debugPrint('[MatchReminder] -> State is currently OFF. Enabling reminders for Match #$matchId...');

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
      debugPrint('[MatchReminder] Stored reminder in SharedPreferences for Match #$matchId.');

      // FEATURE 1: Immediate confirmation system notification in tray
      final confirmId = getConfirmationNotificationId(matchId);
      final confirmTitle = '🔔 تم تفعيل التنبيه';
      final confirmBody = DateFormatter.toArabicNumerals('سيتم تذكيرك بمباراة $homeName × $awayName');
      final reminderPayload = jsonEncode({'type': 'match_reminder', 'matchId': matchId.toString()});

      try {
        await _notificationService.showNotification(
          confirmId,
          confirmTitle,
          confirmBody,
          payload: reminderPayload,
          channelId: NotificationService.channelMatches,
        );
        debugPrint('[MatchReminder] [FEATURE 1] Fired immediate confirmation notification #$confirmId: "$confirmTitle" - "$confirmBody"');
      } catch (e) {
        debugPrint('[MatchReminder] Error showing immediate confirmation notification: $e');
      }

      // FEATURE 2: Two-Tier Scheduling (1 Hour before & 15 Minutes before)
      final kickoff = _computeKickoffTime(match.matchDate, match.matchTime);
      final now = tz.TZDateTime.now(tz.local);

      debugPrint('[MatchReminder] [TIME PIPELINE] matchDate: "${match.matchDate}", matchTime: "${match.matchTime}"');
      debugPrint('[MatchReminder] [TIME PIPELINE] Computed Kickoff (tz.local): $kickoff (UTC: ${kickoff?.toUtc()})');
      debugPrint('[MatchReminder] [TIME PIPELINE] Current Device Time (tz.local): $now (UTC: ${now.toUtc()})');

      if (kickoff != null) {
        final time1Hr = kickoff.subtract(const Duration(hours: 1));
        final time15Min = kickoff.subtract(const Duration(minutes: 15));
        final id1Hr = getReminder1HrId(matchId);
        final id15Min = getReminder15MinId(matchId);

        debugPrint('[MatchReminder] [TIME PIPELINE] 1-Hour Target: $time1Hr (isAfter: ${time1Hr.isAfter(now)})');
        debugPrint('[MatchReminder] [TIME PIPELINE] 15-Min Target: $time15Min (isAfter: ${time15Min.isAfter(now)})');

        // Tier 1: 1 Hour Before Kickoff
        if (time1Hr.isAfter(now)) {
          final title1Hr = '⏳ باقي ساعة على الماتش';
          final body1Hr = DateFormatter.toArabicNumerals('$homeName × $awayName تبدأ بعد ساعة');
          await _notificationService.scheduleNotification(
            id1Hr,
            title1Hr,
            body1Hr,
            time1Hr,
            payload: reminderPayload,
          );
          debugPrint('[MatchReminder] [FEATURE 2 - Tier 1] Scheduled 1-hour reminder #$id1Hr for $time1Hr');
        } else {
          debugPrint('[MatchReminder] [FEATURE 2 - Tier 1] Skipped 1-hour tier (kickoff is in less than 60 mins or past)');
        }

        // Tier 2: 15 Minutes Before Kickoff
        if (time15Min.isAfter(now)) {
          final title15Min = '⏰ الماتش بعد ١٥ دقيقة';
          final body15Min = DateFormatter.toArabicNumerals('$homeName × $awayName - $compName');
          await _notificationService.scheduleNotification(
            id15Min,
            title15Min,
            body15Min,
            time15Min,
            payload: reminderPayload,
          );
          debugPrint('[MatchReminder] [FEATURE 2 - Tier 2] Scheduled 15-min reminder #$id15Min for $time15Min');
        } else if (kickoff.isAfter(now)) {
          // Less than 15 minutes to kickoff: schedule imminent reminder
          debugPrint('[MatchReminder] [FEATURE 2 - Tier 2] Imminent kickoff (< 15 mins). Scheduling near-instant reminder alert.');
          final instantTime = now.add(const Duration(seconds: 5));
          await _notificationService.scheduleNotification(
            id15Min,
            '⏰ تذكير بالمباراة',
            DateFormatter.toArabicNumerals('$homeName × $awayName - $compName'),
            instantTime,
            payload: reminderPayload,
          );
        } else {
          debugPrint('[MatchReminder] [FEATURE 2 - Tier 2] Skipped 15-min tier (kickoff has already passed)');
        }
      }

      final pendingAfterSchedule = await _notificationService.getPendingNotificationRequests();
      debugPrint('[MatchReminder] Total pending notifications in system: ${pendingAfterSchedule.length}');

      try {
        await FirebaseMessaging.instance.subscribeToTopic('match_${matchId}_events');
        debugPrint('[MatchReminder] FCM subscribed to topic: match_${matchId}_events');
      } catch (e) {
        debugPrint('[MatchReminder] FCM subscribe error: $e');
      }

      debugPrint('[MatchReminder] Toggle ON complete. Active reminders: ${storedReminders.length}');
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

  Future<void> rescheduleAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final storedReminders = prefs.getStringList(_storageKey) ?? [];
    final updatedReminders = <String>[];

    debugPrint('[MatchReminder] Rescheduling all ${storedReminders.length} reminders on startup...');

    final now = tz.TZDateTime.now(tz.local);

    for (var jsonStr in storedReminders) {
      try {
        final data = jsonDecode(jsonStr);
        final matchId = data['matchId'] as int?;
        final date = data['matchDate'] as String?;
        final time = data['matchTime'] as String?;
        final homeName = data['homeName'] as String? ?? '';
        final awayName = data['awayName'] as String? ?? '';
        final compName = data['competition'] as String? ?? '';

        if (matchId == null) continue;

        final kickoff = _computeKickoffTime(date, time);

        if (kickoff != null && kickoff.isAfter(now)) {
          updatedReminders.add(jsonStr);

          final reminderPayload = jsonEncode({'type': 'match_reminder', 'matchId': matchId.toString()});
          final time1Hr = kickoff.subtract(const Duration(hours: 1));
          final time15Min = kickoff.subtract(const Duration(minutes: 15));
          final id1Hr = getReminder1HrId(matchId);
          final id15Min = getReminder15MinId(matchId);

          // Tier 1: Reschedule 1-hour tier if still in future
          if (time1Hr.isAfter(now)) {
            final title1Hr = '⏳ باقي ساعة على الماتش';
            final body1Hr = DateFormatter.toArabicNumerals('$homeName × $awayName تبدأ بعد ساعة');
            await _notificationService.scheduleNotification(
              id1Hr,
              title1Hr,
              body1Hr,
              time1Hr,
              payload: reminderPayload,
            );
            debugPrint('[MatchReminder] Startup Rescheduled 1-hour tier #$id1Hr for Match #$matchId at $time1Hr');
          }

          // Tier 2: Reschedule 15-min tier if still in future
          if (time15Min.isAfter(now)) {
            final title15Min = '⏰ الماتش بعد ١٥ دقيقة';
            final body15Min = DateFormatter.toArabicNumerals('$homeName × $awayName - $compName');
            await _notificationService.scheduleNotification(
              id15Min,
              title15Min,
              body15Min,
              time15Min,
              payload: reminderPayload,
            );
            debugPrint('[MatchReminder] Startup Rescheduled 15-min tier #$id15Min for Match #$matchId at $time15Min');
          }
        }
      } catch (e) {
        debugPrint('[MatchReminder] Error rescheduling reminder item: $e');
      }
    }

    await prefs.setStringList(_storageKey, updatedReminders);
    _ref.read(remindedMatchIdsProvider.notifier)._loadInitialState();
  }

  tz.TZDateTime? _computeKickoffTime(String? matchDate, String? matchTime) {
    if (matchDate == null || matchTime == null || matchDate.isEmpty || matchTime.isEmpty) {
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

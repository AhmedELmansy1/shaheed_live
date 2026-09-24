import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/match_model.dart';
import '../utils/date_formatter.dart';
import 'notification_service.dart';

final matchReminderServiceProvider = Provider<MatchReminderService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return MatchReminderService(notificationService, ref);
});

final isReminderSetProvider = FutureProvider.family<bool, int>((ref, matchId) async {
  final service = ref.watch(matchReminderServiceProvider);
  return service.isReminderSet(matchId);
});

class MatchReminderService {
  final NotificationService _notificationService;
  final Ref _ref;
  static const String _storageKey = 'match_reminders';

  MatchReminderService(this._notificationService, this._ref);

  Future<void> toggleReminder(MatchModel match) async {
    final prefs = await SharedPreferences.getInstance();
    final storedReminders = prefs.getStringList(_storageKey) ?? [];
    
    final matchId = match.matchId;
    if (matchId <= 0) return;
    
    final existingIndex = storedReminders.indexWhere((jsonStr) {
      try {
        final data = jsonDecode(jsonStr);
        return data['matchId'] == matchId;
      } catch (_) {
        return false;
      }
    });

    if (existingIndex != -1) {
      // Reminder exists, cancel it
      storedReminders.removeAt(existingIndex);
      await prefs.setStringList(_storageKey, storedReminders);
      await _notificationService.cancelNotification(matchId);
      
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic('match_${matchId}_events');
      } catch (e) {
        debugPrint('Failed to unsubscribe from topic: $e');
      }
    } else {
      // Schedule reminder
      final scheduledTime = _computeNotificationTime(match.matchDate, match.matchTime);
      if (scheduledTime == null || scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('Cannot schedule match notification: time is null or in the past');
        return;
      }

      final reminderData = {
        'matchId': matchId,
        'matchDate': match.matchDate,
        'matchTime': match.matchTime,
        'homeName': match.homeTeam.title,
        'awayName': match.awayTeam.title,
        'competition': match.championship.title,
      };
      
      storedReminders.add(jsonEncode(reminderData));
      await prefs.setStringList(_storageKey, storedReminders);
      
      final homeName = match.homeTeam.title;
      final awayName = match.awayTeam.title;
      final compName = match.championship.title;
      
      final bodyText = '$homeName × $awayName - $compName';
      final arabicBody = DateFormatter.toArabicNumerals(bodyText);
      final payload = jsonEncode({'type': 'match_reminder', 'matchId': matchId.toString()});

      await _notificationService.scheduleNotification(
        matchId,
        '⏰ الماتش بعد ١٥ دقيقة',
        arabicBody,
        scheduledTime,
        payload: payload,
      );

      try {
        await FirebaseMessaging.instance.subscribeToTopic('match_${matchId}_events');
      } catch (e) {
        debugPrint('Failed to subscribe to topic: $e');
      }
    }

    _ref.invalidate(isReminderSetProvider(matchId));
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

  Future<Set<int>> getRemindedMatchIds() async {
    final prefs = await SharedPreferences.getInstance();
    final storedReminders = prefs.getStringList(_storageKey) ?? [];
    
    final ids = <int>{};
    for (var jsonStr in storedReminders) {
      try {
        final data = jsonDecode(jsonStr);
        if (data['matchId'] != null) {
          ids.add(data['matchId'] as int);
        }
      } catch (_) {}
    }
    return ids;
  }

  Future<void> rescheduleAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final storedReminders = prefs.getStringList(_storageKey) ?? [];
    final updatedReminders = <String>[];

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

        final scheduledTime = _computeNotificationTime(date, time);
        if (scheduledTime != null && scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) {
          // Future match, keep and reschedule
          updatedReminders.add(jsonStr);
          
          final bodyText = '$homeName × $awayName - $compName';
          final arabicBody = DateFormatter.toArabicNumerals(bodyText);
          final payload = jsonEncode({'type': 'match_reminder', 'matchId': matchId.toString()});

          await _notificationService.scheduleNotification(
            matchId,
            '⏰ الماتش بعد ١٥ دقيقة',
            arabicBody,
            scheduledTime,
            payload: payload,
          );
        }
      } catch (e) {
        debugPrint('Error rescheduling reminder: $e');
      }
    }
    
    await prefs.setStringList(_storageKey, updatedReminders);
  }

  tz.TZDateTime? _computeNotificationTime(String? matchDate, String? matchTime) {
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
      return tz.TZDateTime.from(localDateTime.subtract(const Duration(minutes: 15)), tz.local);
    } catch (e) {
      debugPrint('Error parsing match date/time: $e');
      return null;
    }
  }
}

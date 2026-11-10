import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../data/api/match_score_api.dart';
import '../../data/models/match_model.dart';
import '../../presentation/onboarding/providers/onboarding_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/match_filter_helper.dart';
import 'notification_service.dart';
import 'team_resolver_service.dart';

/// Manages the set of match IDs that have been manually set for reminders.
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

/// Manages the set of match IDs that have been explicitly MUTED by the user
/// (e.g. turning off reminders for a match involving a followed club).
class MutedMatchesNotifier extends Notifier<Set<int>> {
  static const String _storageKey = 'muted_match_reminders';

  @override
  Set<int> build() {
    _loadInitialState();
    return {};
  }

  Future<void> _loadInitialState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_storageKey) ?? [];
      state = stored
          .map((s) => int.tryParse(s) ?? 0)
          .where((id) => id > 0)
          .toSet();
      debugPrint(
        '[MatchReminder] Loaded ${state.length} muted match reminders into memory.',
      );
    } catch (e) {
      debugPrint('[MatchReminder] Error loading muted matches: $e');
    }
  }

  Future<void> mute(int matchId) async {
    state = {...state, matchId};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _storageKey,
        state.map((id) => id.toString()).toList(),
      );
    } catch (e) {
      debugPrint('[MatchReminder] Error persisting muted match #$matchId: $e');
    }
  }

  Future<void> unmute(int matchId) async {
    state = state.where((id) => id != matchId).toSet();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _storageKey,
        state.map((id) => id.toString()).toList(),
      );
    } catch (e) {
      debugPrint('[MatchReminder] Error persisting unmuted match #$matchId: $e');
    }
  }
}

final mutedMatchIdsProvider =
    NotifierProvider<MutedMatchesNotifier, Set<int>>(() {
      return MutedMatchesNotifier();
    });

/// Evaluates whether the notification bell should show as ON for a given [match].
///
/// Rules:
/// 1. If explicitly muted by the user, returns false.
/// 2. If explicitly enabled by the user, returns true.
/// 3. Visual state derived from followed teams: shows as ON by default for matches
///    involving a user's followed club.
final isMatchReminderActiveProvider = Provider.family<bool, MatchModel>((
  ref,
  match,
) {
  final matchId = match.matchId;
  final manuallyReminded = ref.watch(remindedMatchIdsProvider);
  final mutedMatches = ref.watch(mutedMatchIdsProvider);

  // 1. Explicitly muted takes highest precedence
  if (mutedMatches.contains(matchId)) {
    return false;
  }

  // 2. Explicitly manually toggled ON
  if (manuallyReminded.contains(matchId)) {
    return true;
  }

  // 3. Visual state derived from followed teams
  final onboardingState = ref.watch(onboardingProvider);
  final isClubFollowed = isFavoriteTeamMatch(
    match,
    onboardingState.selectedTeamIds,
    onboardingState.filteredTeams,
  );

  return isClubFollowed;
});

/// Legacy/backward-compatible provider by matchId integer.
final isReminderSetProvider = Provider.family<bool, int>((ref, matchId) {
  final remindedIds = ref.watch(remindedMatchIdsProvider);
  final mutedMatches = ref.watch(mutedMatchIdsProvider);
  return remindedIds.contains(matchId) && !mutedMatches.contains(matchId);
});

final matchReminderServiceProvider = Provider<MatchReminderService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return MatchReminderService(notificationService, ref);
});

class MatchReminderService {
  final NotificationService _notificationService;
  final Ref _ref;
  static const String _storageKey = 'match_reminders';
  static const String _teamTopicsKey = 'subscribed_team_topics';

  // Deterministic Notification IDs
  static int getConfirmationNotificationId(int matchId) => matchId * 10;
  static int getReminder1HrId(int matchId) => matchId * 10 + 1;
  static int getReminder15MinId(int matchId) => matchId * 10 + 2;
  static int getReminder30MinId(int matchId) => matchId * 10 + 3;

  MatchReminderService(this._notificationService, this._ref);

  /// Toggles notifications for a match:
  /// - If active (due to followed club or manual toggle), toggles OFF.
  /// - If inactive, schedules alarm at [customMinutesBefore] (default 15m) and toggles ON.
  Future<void> toggleReminder(
    MatchModel match, {
    int customMinutesBefore = 15,
    bool includeGoalAlerts = true,
  }) async {
    final matchId = match.matchId;
    if (matchId <= 0) {
      debugPrint('[MatchReminder] Invalid matchId ($matchId). Aborting.');
      return;
    }

    final homeName = match.homeTeam.title;
    final awayName = match.awayTeam.title;
    final compName = match.championship.title;

    final onboardingState = _ref.read(onboardingProvider);
    final isClubFollowed = isFavoriteTeamMatch(
      match,
      onboardingState.selectedTeamIds,
      onboardingState.filteredTeams,
    );

    final isCurrentlyActive = _ref.read(isMatchReminderActiveProvider(match));

    debugPrint('[MatchReminder] ========================================');
    debugPrint(
      '[MatchReminder] 🔔 Bell tapped for Match #$matchId: "$homeName × $awayName" ($compName)',
    );
    debugPrint(
      '[MatchReminder] Current active status: $isCurrentlyActive | Involves followed club: $isClubFollowed',
    );

    final prefs = await SharedPreferences.getInstance();
    final storedReminders = prefs.getStringList(_storageKey) ?? [];

    if (isCurrentlyActive) {
      // 1. UNTOGGLE / CANCEL / MUTE
      debugPrint(
        '[MatchReminder] -> State is currently ON. Turning OFF for Match #$matchId...',
      );

      if (isClubFollowed) {
        // Mute this specific match so the followed club's default ON state is suppressed
        await _ref.read(mutedMatchIdsProvider.notifier).mute(matchId);
      }

      // Also remove from manually reminded set if present
      _ref.read(remindedMatchIdsProvider.notifier).remove(matchId);

      storedReminders.removeWhere((jsonStr) {
        try {
          final data = jsonDecode(jsonStr);
          return data['matchId'] == matchId;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList(_storageKey, storedReminders);

      // Cancel local notifications
      final id1Hr = getReminder1HrId(matchId);
      final id15Min = getReminder15MinId(matchId);
      final id30Min = getReminder30MinId(matchId);
      final idConfirm = getConfirmationNotificationId(matchId);

      await _notificationService.cancelNotification(id1Hr);
      await _notificationService.cancelNotification(id15Min);
      await _notificationService.cancelNotification(id30Min);
      await _notificationService.cancelNotification(idConfirm);
      await _notificationService.cancelNotification(matchId);

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
      // 2. TOGGLE / SCHEDULE / UNMUTE
      debugPrint(
        '[MatchReminder] -> State is currently OFF. Turning ON for Match #$matchId with lead: ${customMinutesBefore}m...',
      );

      if (isClubFollowed) {
        // Unmute if it was previously muted
        await _ref.read(mutedMatchIdsProvider.notifier).unmute(matchId);
      }

      // Optimistically update memory state immediately for instant UI feedback
      _ref.read(remindedMatchIdsProvider.notifier).add(matchId);

      final reminderData = {
        'matchId': matchId,
        'matchDate': match.matchDate,
        'matchTime': match.matchTime,
        'homeName': homeName,
        'awayName': awayName,
        'competition': compName,
        'leadMinutes': customMinutesBefore,
      };

      storedReminders.removeWhere((jsonStr) {
        try {
          return jsonDecode(jsonStr)['matchId'] == matchId;
        } catch (_) {
          return false;
        }
      });
      storedReminders.add(jsonEncode(reminderData));
      await prefs.setStringList(_storageKey, storedReminders);

      final reminderPayload = jsonEncode({
        'type': 'match_reminder',
        'matchId': matchId.toString(),
      });

      // 2a. Schedule precise local alarms via AlarmManager (15m, 30m, 1hr or kickoff)
      final kickoff = _computeKickoffTime(match.matchDate, match.matchTime);
      if (kickoff != null) {
        final now = tz.TZDateTime.now(tz.local);

        if (customMinutesBefore > 0) {
          final leadTime = kickoff.subtract(Duration(minutes: customMinutesBefore));
          if (leadTime.isAfter(now)) {
            final reminderId = customMinutesBefore == 30
                ? getReminder30MinId(matchId)
                : (customMinutesBefore == 60
                    ? getReminder1HrId(matchId)
                    : getReminder15MinId(matchId));

            final leadTitle = customMinutesBefore == 15
                ? '⏰ اقتربت المباراة (بعد 15 دقيقة)'
                : (customMinutesBefore == 30
                    ? '⏱️ تذكير بالمباراة (بعد 30 دقيقة)'
                    : '🔔 تذكير بالمباراة (بعد ساعة)');

            final leadBody = DateFormatter.toArabicNumerals(
              'مباراة $homeName ضد $awayName تنطلق في ${match.formattedLocalTime}',
            );

            try {
              await _notificationService.scheduleNotification(
                reminderId,
                leadTitle,
                leadBody,
                leadTime,
                payload: reminderPayload,
                channelId: NotificationService.channelReminders,
              );
              debugPrint(
                '[MatchReminder] ⏰ Scheduled pre-match alarm #$reminderId at $leadTime',
              );
            } catch (e) {
              debugPrint('[MatchReminder] Error scheduling pre-match alarm: $e');
            }
          }
        }

        // At-kickoff alarm
        if (kickoff.isAfter(now)) {
          final startTitle = '⚽ انطلقت صافرة البداية!';
          final startBody = DateFormatter.toArabicNumerals(
            'انطلقت الآن مباراة $homeName ضد $awayName',
          );
          try {
            await _notificationService.scheduleNotification(
              matchId,
              startTitle,
              startBody,
              kickoff,
              payload: reminderPayload,
              channelId: NotificationService.channelReminders,
            );
            debugPrint('[MatchReminder] ⚽ Scheduled kickoff alarm at $kickoff');
          } catch (e) {
            debugPrint('[MatchReminder] Error scheduling kickoff alarm: $e');
          }
        }
      }

      // 2b. Immediate confirmation notification in tray
      final confirmId = getConfirmationNotificationId(matchId);
      final leadDesc = customMinutesBefore == 0
          ? 'عند صافرة البداية'
          : 'قبل المباراة بـ $customMinutesBefore دقيقة';
      final confirmTitle = '🔔 تم تفعيل التنبيه';
      final confirmBody = DateFormatter.toArabicNumerals(
        'سيتم تذكيرك بمباراة $homeName × $awayName ($leadDesc)',
      );

      try {
        await _notificationService.showNotification(
          confirmId,
          confirmTitle,
          confirmBody,
          payload: reminderPayload,
          channelId: NotificationService.channelMatches,
        );
        debugPrint(
          '[MatchReminder] Fired immediate confirmation notification #$confirmId: "$confirmTitle"',
        );
      } catch (e) {
        debugPrint(
          '[MatchReminder] Error showing immediate confirmation notification: $e',
        );
      }

      // 2c. Subscribe to live goals and match events topic if enabled
      if (includeGoalAlerts) {
        try {
          final topic = 'match_${matchId}_events';
          debugPrint(
            '[MatchReminder] 📡 Attempting FCM subscribe to topic: $topic...',
          );
          await FirebaseMessaging.instance.subscribeToTopic(topic);
          debugPrint(
            '[MatchReminder] ✅ FCM subscribe SUCCESS for topic: $topic',
          );
        } catch (e, st) {
          debugPrint('[MatchReminder] ❌ FCM subscribe FAILED for Match #$matchId: $e');
          debugPrint('[MatchReminder] StackTrace: $st');
        }
      }

      debugPrint(
        '[MatchReminder] Toggle ON complete. Active reminders: ${storedReminders.length}',
      );
    }
    debugPrint('[MatchReminder] ========================================');
  }

  static const String _migratedSlugTopicsKey =
      'migrated_old_team_slug_topics_v1';
  static const List<String> _knownLegacySlugTopics = [
    'team_ahly',
    'team_liverpool',
    'team_man_city',
    'team_real_madrid',
    'team_barcelona',
    'team_hilal',
    'team_nassr',
    'team_zamalek',
    'team_arsenal',
    'team_chelsea',
    'team_tottenham',
    'team_milan',
    'team_juventus',
    'team_inter',
    'team_bayern_munich',
    'team_dortmund',
    'team_psg',
    'team_aston_villa',
    'team_atletico_madrid',
    'team_villarreal',
    'team_real_betis',
    'team_athletic_bilbao',
    'team_napoli',
    'team_roma',
    'team_lazio',
    'team_fiorentina',
    'team_monaco',
    'team_marseille',
  ];

  static bool _isNumericTeamTopic(String topic) {
    if (!topic.startsWith('team_')) return false;
    final suffix = topic.substring(5);
    return int.tryParse(suffix) != null;
  }

  /// One-time migration that unsubscribes from old slug topics.
  Future<void> migrateOldSlugTopics() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedSlugTopicsKey) == true) {
      return;
    }

    debugPrint(
      '[MatchReminder] 🚀 Running one-time migration to unsubscribe from old slug topics...',
    );
    final currentTopics = prefs.getStringList(_teamTopicsKey) ?? [];
    final slugTopicsToUnsubscribe = <String>{};

    for (final topic in currentTopics) {
      if (!_isNumericTeamTopic(topic)) {
        slugTopicsToUnsubscribe.add(topic);
      }
    }
    slugTopicsToUnsubscribe.addAll(_knownLegacySlugTopics);

    for (final slug in slugTopicsToUnsubscribe) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(slug);
        if (kDebugMode) {
          debugPrint(
            '[MatchReminder] 🧹 [Migration] Unsubscribed from old slug topic: $slug',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[MatchReminder] ⚠️ [Migration] Error unsubscribing from $slug: $e',
          );
        }
      }
    }

    // Clean stored list to only numeric team topics
    final cleaned = currentTopics.where(_isNumericTeamTopic).toList();
    await prefs.setStringList(_teamTopicsKey, cleaned);
    await prefs.setBool(_migratedSlugTopicsKey, true);
    debugPrint('[MatchReminder] ✅ One-time slug topic migration complete.');
  }

  /// Synchronizes FCM topic subscriptions for the user's chosen clubs.
  /// Subscribes strictly to `team_{apiRowId}` (never slug topics).
  /// Awaits TeamResolver to guarantee mappings are loaded.
  /// Persists the active topic list to SharedPreferences and prints it in debug.
  Future<void> syncTeamTopicSubscriptions(List<String> selectedTeamIds) async {
    final prefs = await SharedPreferences.getInstance();
    final currentTopics = prefs.getStringList(_teamTopicsKey) ?? [];

    // Ensure TeamResolver mappings are ready
    await TeamResolverService.getMappings();

    final desiredTopics = <String>{};
    for (final id in selectedTeamIds) {
      final apiRowId = await TeamResolverService.resolveToApiRowId(id);
      if (apiRowId != null) {
        desiredTopics.add('team_$apiRowId');
      }
    }

    final toSubscribe = desiredTopics.difference(currentTopics.toSet());
    final toUnsubscribe = currentTopics.toSet().difference(desiredTopics);

    debugPrint(
      '[MatchReminder] 🔄 Syncing team topics: ${toSubscribe.length} to subscribe, ${toUnsubscribe.length} to unsubscribe',
    );

    for (final topic in toSubscribe) {
      try {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
        debugPrint('[MatchReminder] ✅ Auto-subscribed to team FCM topic: $topic');
      } catch (e) {
        debugPrint('[MatchReminder] ⚠️ Error subscribing to team topic $topic: $e');
      }
    }

    for (final topic in toUnsubscribe) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        debugPrint('[MatchReminder] 🛑 Unsubscribed from team FCM topic: $topic');
      } catch (e) {
        debugPrint('[MatchReminder] ⚠️ Error unsubscribing from team topic $topic: $e');
      }
    }

    final updatedList = desiredTopics.toList()..sort();
    await prefs.setStringList(_teamTopicsKey, updatedList);
    debugPrint(
      '[MatchReminder] Persisted ${updatedList.length} subscribed team topics.',
    );

    // Print final subscribed topic list in debug
    if (kDebugMode) {
      debugPrint(
        '[MatchReminder] 📋 Final active subscribed FCM team topics: $updatedList',
      );
    }
  }

  /// Re-applies all team topic subscriptions on startup and after token refresh.
  /// Awaits TeamResolver and subscribes to team_{apiRowId} only.
  Future<void> reapplyTeamTopicSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. One-time migration to unsubscribe from legacy slug topics
    await migrateOldSlugTopics();

    // 2. Await TeamResolver mappings
    await TeamResolverService.getMappings();

    // 3. Resolve user's followed clubs to team_{apiRowId} only
    final selectedTeamIds = prefs.getStringList('selected_teams') ?? [];
    if (selectedTeamIds.isNotEmpty) {
      await syncTeamTopicSubscriptions(selectedTeamIds);
    } else {
      final storedTopics = prefs.getStringList(_teamTopicsKey) ?? [];
      for (final topic in storedTopics) {
        if (_isNumericTeamTopic(topic)) {
          try {
            await FirebaseMessaging.instance.subscribeToTopic(topic);
            debugPrint('[MatchReminder] ✅ Restored team FCM topic: $topic');
          } catch (e) {
            debugPrint(
              '[MatchReminder] ❌ Error restoring team topic $topic: $e',
            );
          }
        }
      }
      if (kDebugMode) {
        debugPrint(
          '[MatchReminder] 📋 Final active subscribed FCM team topics: $storedTopics',
        );
      }
    }
  }

  /// Re-applies all match and team topic subscriptions after token refresh.
  Future<void> reapplyAllTopicSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final storedReminders = prefs.getStringList(_storageKey) ?? [];
    debugPrint(
      '[MatchReminder] 🔄 Re-applying FCM topic subscriptions for ${storedReminders.length} stored match reminders...',
    );

    // 1. Restore match topics
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

    // 2. Restore team topics
    await reapplyTeamTopicSubscriptions();

    // 3. Restore test topic if explicitly enabled
    try {
      final isTestEnabled = prefs.getBool('is_test_notification_topic_enabled') ?? false;
      if (isTestEnabled) {
        await FirebaseMessaging.instance.subscribeToTopic('match_score_test_notifications');
        debugPrint('[MatchReminder] ✅ Restored FCM test topic: match_score_test_notifications');
      }
    } catch (e) {
      debugPrint('[MatchReminder] ⚠️ Error restoring test topic subscription: $e');
    }
  }

  /// Reschedules all active reminders on startup.
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
    _ref.read(mutedMatchIdsProvider.notifier)._loadInitialState();

    // 3. Re-apply team topics on app start
    await reapplyTeamTopicSubscriptions();
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

      final sourceLocation = tz.getLocation(ApiConfig.sourceTimezone);
      final sourceTZDateTime = tz.TZDateTime(
        sourceLocation,
        year,
        month,
        day,
        hour,
        minute,
        second,
      );

      final localDateTime = sourceTZDateTime.toLocal();
      return tz.TZDateTime.from(localDateTime, tz.local);
    } catch (e) {
      debugPrint('[MatchReminder] Error parsing match date/time: $e');
      return null;
    }
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
}

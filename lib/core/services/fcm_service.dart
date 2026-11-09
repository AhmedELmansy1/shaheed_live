import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_ready_provider.dart';
import 'match_reminder_service.dart';
import 'notification_service.dart';
import '../utils/date_formatter.dart';

class ReceivedFcmLog {
  final String id;
  final DateTime timestamp;
  final String? from;
  final String title;
  final String body;
  final Map<String, dynamic> data;

  const ReceivedFcmLog({
    required this.id,
    required this.timestamp,
    this.from,
    required this.title,
    required this.body,
    required this.data,
  });
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return FcmService(notificationService, ref);
});

class FcmService {
  final NotificationService _notificationService;
  final Ref _ref;

  /// Global broadcast topic that all app instances subscribe to.
  static const String globalBroadcastTopic = 'all';

  /// Dedicated test topic for Phase 2.5 production verification.
  /// Devices only subscribe to this topic when explicitly initiated by a developer/tester.
  static const String testNotificationTopic = 'match_score_test_notifications';
  static const String testTopicEnabledKey = 'is_test_notification_topic_enabled';

  /// Ring buffer storing the last 10 received messages for diagnostics.
  static final List<ReceivedFcmLog> recentMessages = <ReceivedFcmLog>[];

  static void recordMessageLog(ReceivedFcmLog log) {
    recentMessages.insert(0, log);
    if (recentMessages.length > 10) {
      recentMessages.removeLast();
    }
  }

  FcmService(this._notificationService, this._ref);

  Future<void> init() async {
    // 0. Wait for Firebase readiness so background/deferred init does not crash
    final isReady = await _ref
        .read(firebaseReadyProvider.notifier)
        .awaitReady(timeout: const Duration(seconds: 5));
    if (!isReady || Firebase.apps.isEmpty) {
      debugPrint('[FCM] Firebase not ready or available; skipping FCM init.');
      return;
    }

    // 1. Request OS notification permissions on Android 13+ and iOS
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('[FCM] Notification permission status: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('[FCM] Notification permission request notice: $e');
    }

    // 2. Auto-subscribe to the global 'all' broadcast topic
    await subscribeToGlobalBroadcast();

    // 3. Foreground message receiver
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM Foreground] 📩 Message received: ${message.messageId}, from: ${message.from}');
      handleForegroundMessage(message);
    });

    // 4. Token refresh listener - re-subscribe to all active match topics if token rotates
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] 🔄 Registration token refreshed: $newToken');
      try {
        await subscribeToGlobalBroadcast();
        final reminderService = _ref.read(matchReminderServiceProvider);
        await reminderService.reapplyAllTopicSubscriptions();
      } catch (e) {
        debugPrint('[FCM] ❌ Error re-applying topic subscriptions after token refresh: $e');
      }
    });

    // 3. Log initial registration token for debugging / manual testing (kDebugMode only, deferred)
    if (kDebugMode) {
      Future.delayed(const Duration(milliseconds: 500), () {
        FirebaseMessaging.instance.getToken().then((token) {
          debugPrint('====================================================');
          debugPrint('[FCM] 📱 Current Device FCM Registration Token:');
          debugPrint('$token');
          debugPrint('====================================================');
        }).catchError((e) {
          debugPrint('[FCM] ⚠️ Error retrieving FCM registration token: $e');
        });
      });
    }

    setupInteractiveHandlers();
  }

  /// Subscribes the device to the global broadcast topic ('all') matching dashboard sends.
  Future<void> subscribeToGlobalBroadcast() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(globalBroadcastTopic);
      debugPrint('[FCM] 📡 Subscribed to global broadcast topic: $globalBroadcastTopic');
    } catch (e) {
      debugPrint('[FCM] ⚠️ Error subscribing to global broadcast topic $globalBroadcastTopic: $e');
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          await FirebaseMessaging.instance.subscribeToTopic(globalBroadcastTopic);
          debugPrint('[FCM] 📡 Subscribed to global broadcast topic on retry: $globalBroadcastTopic');
        } catch (_) {}
      });
    }
  }

  /// Explicitly subscribes this device to the isolated test topic [testNotificationTopic].
  /// Logs diagnostic token safely in kDebugMode without exposing credentials.
  Future<String?> enableTestNotificationTopic() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(testTopicEnabledKey, true);
    try {
      await FirebaseMessaging.instance.subscribeToTopic(testNotificationTopic);
      final token = await FirebaseMessaging.instance.getToken();

      if (kDebugMode) {
        debugPrint('====================================================');
        debugPrint('[FCM TEST MODE] ✅ Subscribed to isolated test topic: $testNotificationTopic');
        debugPrint('[FCM TEST MODE] 📱 Diagnostic FCM Token: $token');
        debugPrint('====================================================');
      }
      return token;
    } catch (e) {
      debugPrint('[FCM TEST MODE] ⚠️ Subscribe notice: $e');
      return null;
    }
  }

  /// Explicitly unsubscribes this device from the test topic [testNotificationTopic].
  Future<bool> disableTestNotificationTopic() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(testTopicEnabledKey, false);
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(testNotificationTopic);

      if (kDebugMode) {
        debugPrint('[FCM TEST MODE] 🛑 Unsubscribed from test topic: $testNotificationTopic');
      }
      return true;
    } catch (e) {
      debugPrint('[FCM TEST MODE] ⚠️ Unsubscribe notice: $e');
      return true;
    }
  }

  /// Checks if this device currently has test topic subscription enabled.
  Future<bool> isTestNotificationTopicEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(testTopicEnabledKey) ?? false;
  }

  void setupInteractiveHandlers() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // Check cold start FCM launch message
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
          if (message != null) {
            _handleNotificationTap(message);
          }
        })
        .catchError((e) {
          debugPrint('Error getting initial FCM message: $e');
        });
  }

  Future<void> handleForegroundMessage(RemoteMessage message) async {
    final data = message.data;

    // 1. Fallback gracefully: Check message.notification title/body first, then data['title']/data['body']
    String title = message.notification?.title ?? data['title']?.toString() ?? 'إشعار جديد';
    String body = message.notification?.body ?? data['body']?.toString() ?? '';

    final eventType = data['event_type'];
    final isTestNotification =
        data['type'] == 'test_notification' || eventType == 'production_verification';

    // 2. Notification preference gating
    final prefs = await SharedPreferences.getInstance();
    final matchStartEnabled = prefs.getBool('pref_notify_match_start') ?? true;
    final goalAlertsEnabled = prefs.getBool('pref_notify_goal_alerts') ?? true;

    final isMatchStartEvent =
        eventType == 'kickoff' || eventType == 'reminder_1hr' || eventType == 'reminder_15min';
    final isGoalEvent =
        eventType == 'goal' || eventType == 'penalty' || eventType == 'penalty_scored' || eventType == 'penalty_missed';

    if (isMatchStartEvent && !matchStartEnabled) {
      debugPrint('[FCM] 🔇 Match start notification suppressed by user setting (pref_notify_match_start=false)');
      return;
    }
    if (isGoalEvent && !goalAlertsEnabled) {
      debugPrint('[FCM] 🔇 Goal alert notification suppressed by user setting (pref_notify_goal_alerts=false)');
      return;
    }

    if (data.containsKey('event_type')) {
      final home = data['home'] ?? '';
      final away = data['away'] ?? '';
      final homeScore = data['home_score'] ?? '';
      final awayScore = data['away_score'] ?? '';
      final scorer = data['scorer'] ?? '';
      final player = data['player'] ?? '';

      switch (eventType) {
        case 'goal':
          title = '⚽ هدف!';
          body = '$scorer — $home $homeScore-$awayScore $away';
          break;
        case 'penalty':
        case 'penalty_scored':
          title = '⚽ هدف (ركلة جزاء)';
          body = scorer.isNotEmpty
              ? '$scorer — $home $homeScore-$awayScore $away'
              : '$home $homeScore-$awayScore $away';
          break;
        case 'penalty_missed':
          title = '❌ ركلة جزاء ضائعة';
          body = player.isNotEmpty
              ? '$player — $home × $away'
              : '$home × $away';
          break;
        case 'red_card':
          title = '🟥 بطاقة حمراء';
          body = '$player — $home × $away';
          break;
        case 'kickoff':
          title = '🏟️ بداية المباراة';
          body = '$home × $away';
          break;
        case 'fulltime':
          title = '🏁 نهاية المباراة';
          body = '$home $homeScore-$awayScore $away';
          break;
        case 'reminder_1hr':
          title = '⏳ باقي ساعة على الماتش';
          body = '$home × $away تبدأ بعد ساعة';
          break;
        case 'reminder_15min':
          title = '⏰ المباراة بعد ١٥ دقيقة';
          body = '$home × $away';
          break;
        case 'production_verification':
          title = message.notification?.title ?? '🧪 MATCH SCORE Test';
          body = message.notification?.body ?? 'FCM notifications are working correctly.';
          break;
      }
    }

    if (isTestNotification) {
      title = message.notification?.title ?? '🧪 MATCH SCORE Test';
      body = message.notification?.body ?? (body.isNotEmpty ? body : 'FCM notifications are working correctly.');
    }

    body = DateFormatter.toArabicNumerals(body);

    final matchId = data['match_id']?.toString();
    final isPreMatchReminder =
        eventType == 'reminder_1hr' || eventType == 'reminder_15min';

    String? payload;
    if (matchId != null) {
      final payloadType = isPreMatchReminder
          ? 'match_reminder'
          : (isTestNotification ? 'test_notification' : 'live_event');
      payload = jsonEncode({
        'type': payloadType,
        'matchId': matchId,
      });
    }

    final channelId = isPreMatchReminder
        ? NotificationService.channelReminders
        : (isTestNotification
            ? NotificationService.channelMatches
            : NotificationService.channelLiveEvents);

    recordMessageLog(ReceivedFcmLog(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      from: message.from,
      title: title,
      body: body,
      data: Map<String, dynamic>.from(data),
    ));

    await _notificationService.showNotification(
      message.messageId.hashCode,
      title,
      body,
      payload: payload,
      channelId: channelId,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final matchId = data['match_id']?.toString();
    if (matchId != null) {
      if (NotificationService.onMatchNotificationTap != null) {
        NotificationService.onMatchNotificationTap!(matchId);
      } else {
        NotificationService.pendingColdStartMatchId = matchId;
      }
    }
  }
}

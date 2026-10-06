import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'match_reminder_service.dart';
import 'notification_service.dart';
import '../utils/date_formatter.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return FcmService(notificationService, ref);
});

class FcmService {
  final NotificationService _notificationService;
  final Ref _ref;

  FcmService(this._notificationService, this._ref);

  void init() {
    // 1. Foreground message receiver
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM Foreground] 📩 Message received: ${message.messageId}, from: ${message.from}');
      handleForegroundMessage(message);
    });

    // 2. Token refresh listener - re-subscribe to all active match topics if token rotates
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] 🔄 Registration token refreshed: $newToken');
      try {
        final reminderService = _ref.read(matchReminderServiceProvider);
        await reminderService.reapplyAllTopicSubscriptions();
      } catch (e) {
        debugPrint('[FCM] ❌ Error re-applying topic subscriptions after token refresh: $e');
      }
    });

    // 3. Log initial registration token for debugging / manual testing
    FirebaseMessaging.instance.getToken().then((token) {
      debugPrint('====================================================');
      debugPrint('[FCM] 📱 Current Device FCM Registration Token:');
      debugPrint('$token');
      debugPrint('====================================================');
    }).catchError((e) {
      debugPrint('[FCM] ⚠️ Error retrieving FCM registration token: $e');
    });

    setupInteractiveHandlers();
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

    String title = message.notification?.title ?? 'إشعار جديد';
    String body = message.notification?.body ?? '';

    if (data.containsKey('event_type')) {
      final eventType = data['event_type'];
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
          title = '⏰ الماتش بعد ١٥ دقيقة';
          body = '$home × $away';
          break;
      }
    }

    body = DateFormatter.toArabicNumerals(body);

    final matchId = data['match_id']?.toString();
    final eventType = data['event_type'];
    final isPreMatchReminder =
        eventType == 'reminder_1hr' || eventType == 'reminder_15min';

    String? payload;
    if (matchId != null) {
      payload = jsonEncode({
        'type': isPreMatchReminder ? 'match_reminder' : 'live_event',
        'matchId': matchId,
      });
    }

    final channelId = isPreMatchReminder
        ? NotificationService.channelReminders
        : NotificationService.channelLiveEvents;

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

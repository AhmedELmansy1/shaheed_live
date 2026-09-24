import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';
import '../utils/date_formatter.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return FcmService(notificationService);
});

class FcmService {
  final NotificationService _notificationService;

  FcmService(this._notificationService);

  void init() {
    FirebaseMessaging.onMessage.listen(handleForegroundMessage);
    setupInteractiveHandlers();
  }

  void setupInteractiveHandlers() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // Check cold start FCM launch message
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    }).catchError((e) {
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
      }
    }
    
    body = DateFormatter.toArabicNumerals(body);

    final matchId = data['match_id']?.toString();
    String? payload;
    if (matchId != null) {
      payload = jsonEncode({'type': 'live_event', 'matchId': matchId});
    }

    await _notificationService.showNotification(
      message.messageId.hashCode,
      title,
      body,
      payload: payload,
      channelId: 'live_events',
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

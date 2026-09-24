import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  static void Function(String matchId)? onMatchNotificationTap;
  static String? pendingColdStartMatchId;

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Create Channels on Android
    final androidPlatformChannelSpecifics = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlatformChannelSpecifics != null) {
      await androidPlatformChannelSpecifics.createNotificationChannel(
        const AndroidNotificationChannel(
          'matches_channel',
          'تنبيهات المباريات',
          description: 'تنبيهات عامة للمباريات',
          importance: Importance.max,
        ),
      );
      await androidPlatformChannelSpecifics.createNotificationChannel(
        const AndroidNotificationChannel(
          'match_reminders',
          'تذكيرات المباريات',
          description: 'تذكيرات قبل بداية المباريات',
          importance: Importance.high,
        ),
      );
      await androidPlatformChannelSpecifics.createNotificationChannel(
        const AndroidNotificationChannel(
          'live_events',
          'أحداث المباريات المباشرة',
          description: 'أحداث المباريات أثناء اللعب',
          importance: Importance.max,
        ),
      );
    }

    // Check if app was launched via local notification (Cold Start)
    try {
      final details = await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp && details.notificationResponse?.payload != null) {
        final payload = jsonDecode(details.notificationResponse!.payload!);
        if (payload['matchId'] != null) {
          final matchId = payload['matchId'].toString();
          if (onMatchNotificationTap != null) {
            onMatchNotificationTap!(matchId);
          } else {
            pendingColdStartMatchId = matchId;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking launch notification details: $e');
    }
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final payload = jsonDecode(response.payload!);
        if ((payload['type'] == 'match_reminder' || payload['type'] == 'live_event') && payload['matchId'] != null) {
          final matchId = payload['matchId'].toString();
          if (onMatchNotificationTap != null) {
            onMatchNotificationTap!(matchId);
          } else {
            pendingColdStartMatchId = matchId;
          }
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  Future<void> showNotification(
    int id,
    String title,
    String body, {
    String? payload,
    String channelId = 'matches_channel',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledTime, {
    String? payload,
    String channelId = 'match_reminders',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'matches_channel':
        return 'تنبيهات المباريات';
      case 'match_reminders':
        return 'تذكيرات المباريات';
      case 'live_events':
        return 'أحداث المباريات المباشرة';
      default:
        return 'تنبيهات عامة';
    }
  }
}

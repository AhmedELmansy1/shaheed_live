import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

/// Top-level background entry point required by flutter_local_notifications for Android/iOS background actions.
/// When an alarm or background notification fires or is tapped in background/killed state, this is called.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint(
    '[NotificationService] [BACKGROUND WAKEUP] Notification received/tapped in background.',
  );
  debugPrint('[NotificationService]   - ID: #${notificationResponse.id}');
  debugPrint(
    '[NotificationService]   - ActionId: ${notificationResponse.actionId}',
  );
  debugPrint(
    '[NotificationService]   - Payload: ${notificationResponse.payload}',
  );
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Central Notification Service for Live Pulse.
///
/// NOTE FOR XIAOMI / MIUI / HYPEROS DEVICES:
/// On MIUI and other aggressive OEM skins:
/// 1. AutoStart: The app requires "Autostart" (التشغيل التلقائي) permission in MIUI Security settings to fire alarms when backgrounded.
/// 2. Battery Saver: Set battery saver to "No restrictions" (بدون قيود) for uninterrupted AlarmManager delivery.
/// 3. Lock Screen / Floating Notifications: MIUI separates "Lock screen notifications" and "Floating notifications" permissions per channel.
///    Channel migration (e.g. to _v2) forces MIUI to re-evaluate notification settings with Importance.max.
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void Function(String matchId)? onMatchNotificationTap;
  static String? pendingColdStartMatchId;

  // New Channel IDs (v2) to reset any muted OS channels on user devices
  static const String channelMatches = 'matches_channel_v2';
  static const String channelReminders = 'match_reminders_v2';
  static const String channelLiveEvents = 'live_events_v2';

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Platform-specific setup on Android
    final androidPlatformChannelSpecifics = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlatformChannelSpecifics != null) {
      // 1. Log existing notification channels on device
      try {
        final existingChannels = await androidPlatformChannelSpecifics
            .getNotificationChannels();
        debugPrint(
          '[NotificationService] ========================================',
        );
        debugPrint('[NotificationService] [INSPECT OS NOTIFICATION CHANNELS]');
        if (existingChannels == null || existingChannels.isEmpty) {
          debugPrint(
            '[NotificationService]   No channels currently registered on device.',
          );
        } else {
          for (var ch in existingChannels) {
            debugPrint(
              '[NotificationService]   - Channel: id="${ch.id}", name="${ch.name}", importance=${ch.importance}, sound=${ch.playSound}, enableVibration=${ch.enableVibration}',
            );
          }
        }
      } catch (e) {
        debugPrint(
          '[NotificationService] Error querying existing channels: $e',
        );
      }

      // 2. Delete legacy v1 channels that might have been muted or cached with lower importance by MIUI
      try {
        await androidPlatformChannelSpecifics.deleteNotificationChannel(
          channelId: 'matches_channel',
        );
        await androidPlatformChannelSpecifics.deleteNotificationChannel(
          channelId: 'match_reminders',
        );
        await androidPlatformChannelSpecifics.deleteNotificationChannel(
          channelId: 'live_events',
        );
        debugPrint(
          '[NotificationService] [CHANNEL CLEANUP] Deleted legacy v1 notification channels.',
        );
      } catch (e) {
        debugPrint('[NotificationService] Notice deleting legacy channels: $e');
      }

      // 3. Create fresh v2 channels with Importance.max for heads-up / banner display
      await androidPlatformChannelSpecifics.createNotificationChannel(
        const AndroidNotificationChannel(
          channelMatches,
          'تنبيهات المباريات',
          description: 'تنبيهات عامة للمباريات وتأكيدات التفعيل',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidPlatformChannelSpecifics.createNotificationChannel(
        const AndroidNotificationChannel(
          channelReminders,
          'تذكيرات المباريات',
          description: 'تذكيرات قبل بداية المباريات (ساعة و١٥ دقيقة)',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidPlatformChannelSpecifics.createNotificationChannel(
        const AndroidNotificationChannel(
          channelLiveEvents,
          'أحداث المباريات المباشرة',
          description: 'أحداث المباريات أثناء اللعب (أهداف، كروت)',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      // 4. Log channels after migration
      try {
        final updatedChannels = await androidPlatformChannelSpecifics
            .getNotificationChannels();
        debugPrint(
          '[NotificationService] [REGISTERED CHANNELS AFTER MIGRATION: ${updatedChannels?.length ?? 0}]',
        );
        if (updatedChannels != null) {
          for (var ch in updatedChannels) {
            debugPrint(
              '[NotificationService]   ✓ Channel: id="${ch.id}", name="${ch.name}", importance=${ch.importance}',
            );
          }
        }
        debugPrint(
          '[NotificationService] ========================================',
        );
      } catch (e) {
        debugPrint(
          '[NotificationService] Error inspecting post-migration channels: $e',
        );
      }

      // Request notification posting permission on Android 13+ (API 33+)
      try {
        await androidPlatformChannelSpecifics.requestNotificationsPermission();
      } catch (e) {
        debugPrint(
          '[NotificationService] Notification permission request notice: $e',
        );
      }
    }

    // Check if app was launched via local notification (Cold Start)
    try {
      final details = await _notificationsPlugin
          .getNotificationAppLaunchDetails();
      if (details != null &&
          details.didNotificationLaunchApp &&
          details.notificationResponse?.payload != null) {
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
        if ((payload['type'] == 'match_reminder' ||
                payload['type'] == 'live_event' ||
                payload['type'] == 'test_notification') &&
            payload['matchId'] != null) {
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
    String channelId = channelMatches,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      icon: '@drawable/ic_notification',
      color: const Color(0xFFE5482D),
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

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
    String channelId = channelReminders,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      icon: '@drawable/ic_notification',
      color: const Color(0xFFE5482D),
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = tz.TZDateTime.now(tz.local);
    debugPrint(
      '[NotificationService] ========================================',
    );
    debugPrint('[NotificationService] [SCHEDULE ATTEMPT] -> ID: #$id');
    debugPrint('[NotificationService]   Title: "$title"');
    debugPrint('[NotificationService]   Channel: "$channelId"');
    debugPrint(
      '[NotificationService]   Target Time (tz.local): $scheduledTime (UTC: ${scheduledTime.toUtc()})',
    );
    debugPrint('[NotificationService]   Local Now: $now (UTC: ${now.toUtc()})');
    debugPrint(
      '[NotificationService]   Time Difference: ${scheduledTime.difference(now)}',
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint(
        '[NotificationService] [SCHEDULE SUCCESS] Registered with AndroidScheduleMode.exactAllowWhileIdle',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] [SCHEDULE WARNING] exactAllowWhileIdle failed: $e. Falling back to inexact mode...',
      );
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledTime,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexact,
          payload: payload,
        );
        debugPrint(
          '[NotificationService] [SCHEDULE SUCCESS] Registered with AndroidScheduleMode.inexact',
        );
      } catch (e2) {
        debugPrint(
          '[NotificationService] [SCHEDULE ERROR] Inexact fallback also failed: $e2',
        );
      }
    }

    final pending = await getPendingNotificationRequests();
    debugPrint(
      '[NotificationService] [OS REGISTERED PENDING NOTIFICATIONS COUNT: ${pending.length}]',
    );
    for (var p in pending) {
      debugPrint(
        '[NotificationService]   - Pending ID: #${p.id} | Title: "${p.title}" | Body: "${p.body}"',
      );
    }
    debugPrint(
      '[NotificationService] ========================================',
    );
  }

  /// Fast test helper to schedule a notification 1 minute (or custom seconds) from now
  Future<void> scheduleTestNotification({int seconds = 60}) async {
    final now = tz.TZDateTime.now(tz.local);
    final targetTime = now.add(Duration(seconds: seconds));
    debugPrint(
      '[NotificationService] [FAST TEST] Triggering test reminder in $seconds seconds ($targetTime)...',
    );
    await scheduleNotification(
      99999,
      '⏰ إشعار اختبار مجدول ($seconds ثوانٍ)',
      'تم إطلاق هذا الإشعار بنجاح في الوقت المحدد للتأكد من عمل Alarms!',
      targetTime,
      payload: jsonEncode({'type': 'match_reminder', 'matchId': '99999'}),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
    debugPrint('[NotificationService] Cancelled notification ID: #$id');
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint('[NotificationService] Cancelled all notifications.');
  }

  Future<List<PendingNotificationRequest>>
  getPendingNotificationRequests() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Returns active notification channels registered in Android OS.
  Future<List<AndroidNotificationChannel>?> getRegisteredChannels() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return android?.getNotificationChannels();
  }

  /// Checks if the app currently has permission to schedule exact alarms (Android 12+).
  Future<bool?> canScheduleExactAlarms() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return android?.canScheduleExactNotifications();
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case channelMatches:
      case 'matches_channel':
        return 'تنبيهات المباريات';
      case channelReminders:
      case 'match_reminders':
        return 'تذكيرات المباريات';
      case channelLiveEvents:
      case 'live_events':
        return 'أحداث المباريات المباشرة';
      default:
        return 'تنبيهات عامة';
    }
  }
}

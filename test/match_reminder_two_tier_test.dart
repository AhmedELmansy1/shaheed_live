import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:shoot_live/core/services/match_reminder_service.dart';
import 'package:shoot_live/core/services/notification_service.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Mock NotificationService to inspect all calls
class MockNotificationService implements NotificationService {
  final List<Map<String, dynamic>> shownNotifications = [];
  final List<Map<String, dynamic>> scheduledNotifications = [];
  final List<int> cancelledNotificationIds = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> showNotification(
    int id,
    String title,
    String body, {
    String? payload,
    String channelId = NotificationService.channelMatches,
  }) async {
    shownNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
      'channelId': channelId,
    });
  }

  @override
  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledTime, {
    String? payload,
    String channelId = NotificationService.channelReminders,
  }) async {
    scheduledNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime,
      'payload': payload,
      'channelId': channelId,
    });
  }

  @override
  Future<void> cancelNotification(int id) async {
    cancelledNotificationIds.add(id);
    scheduledNotifications.removeWhere((item) => item['id'] == id);
    shownNotifications.removeWhere((item) => item['id'] == id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    scheduledNotifications.clear();
    shownNotifications.clear();
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() async {
    return scheduledNotifications.map((s) {
      return PendingNotificationRequest(
        s['id'] as int,
        s['title'] as String?,
        s['body'] as String?,
        s['payload'] as String?,
      );
    }).toList();
  }

  @override
  Future<void> scheduleTestNotification({int seconds = 60}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();

  late MockNotificationService mockNotificationService;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockNotificationService = MockNotificationService();

    container = ProviderContainer(
      overrides: [
        notificationServiceProvider.overrideWithValue(mockNotificationService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  MatchModel createMatch({
    required int matchId,
    required String matchDate,
    required String matchTime,
  }) {
    return MatchModel(
      matchId: matchId,
      matchDate: matchDate,
      matchTime: matchTime,
      isLive: false,
      status: MatchStatus.notStarted,
      homeTeam: const TeamInfo(rowId: 1, title: 'الأهلي', image: ''),
      awayTeam: const TeamInfo(rowId: 2, title: 'الزمالك', image: ''),
      championship: const ChampionshipInfo(id: 10, title: 'الدوري المصري الممتاز', image: ''),
    );
  }

  group('Match Reminder Two-Tier & Confirmation Tests', () {
    test('FEATURE 1: Enabling a reminder fires an immediate confirmation notification in system tray', () async {
      final service = container.read(matchReminderServiceProvider);

      // Match 3 hours from now
      final cairoLocation = tz.getLocation('Africa/Cairo');
      final futureCairoTime = tz.TZDateTime.now(cairoLocation).add(const Duration(hours: 3));
      final dateStr = '${futureCairoTime.year}-${futureCairoTime.month.toString().padLeft(2, '0')}-${futureCairoTime.day.toString().padLeft(2, '0')}';
      final timeStr = '${futureCairoTime.hour.toString().padLeft(2, '0')}:${futureCairoTime.minute.toString().padLeft(2, '0')}:00';

      final match = createMatch(matchId: 1001, matchDate: dateStr, matchTime: timeStr);

      await service.toggleReminder(match);

      // Verify immediate confirmation notification
      expect(mockNotificationService.shownNotifications.length, 1);
      final confirm = mockNotificationService.shownNotifications.first;
      expect(confirm['id'], 10010); // MatchReminderService.getConfirmationNotificationId(1001)
      expect(confirm['title'], '🔔 تم تفعيل التنبيه');
      expect(confirm['body'], contains('الأهلي × الزمالك'));
      expect(confirm['channelId'], NotificationService.channelMatches);

      // Verify provider state updated
      expect(container.read(isReminderSetProvider(1001)), isTrue);
    });

    test('FEATURE 2: Match far in the future schedules BOTH 1-hour and 15-min tiers with distinct IDs', () async {
      final service = container.read(matchReminderServiceProvider);

      // Match 5 hours from now
      final cairoLocation = tz.getLocation('Africa/Cairo');
      final futureCairoTime = tz.TZDateTime.now(cairoLocation).add(const Duration(hours: 5));
      final dateStr = '${futureCairoTime.year}-${futureCairoTime.month.toString().padLeft(2, '0')}-${futureCairoTime.day.toString().padLeft(2, '0')}';
      final timeStr = '${futureCairoTime.hour.toString().padLeft(2, '0')}:${futureCairoTime.minute.toString().padLeft(2, '0')}:00';

      final match = createMatch(matchId: 2002, matchDate: dateStr, matchTime: timeStr);

      await service.toggleReminder(match);

      // Verify 2 scheduled notifications
      expect(mockNotificationService.scheduledNotifications.length, 2);

      final tier1 = mockNotificationService.scheduledNotifications.firstWhere(
        (n) => n['id'] == MatchReminderService.getReminder1HrId(2002),
      );
      expect(tier1['id'], 20021);
      expect(tier1['title'], '⏳ باقي ساعة على الماتش');
      expect(tier1['body'], contains('الأهلي × الزمالك تبدأ بعد ساعة'));

      final tier2 = mockNotificationService.scheduledNotifications.firstWhere(
        (n) => n['id'] == MatchReminderService.getReminder15MinId(2002),
      );
      expect(tier2['id'], 20022);
      expect(tier2['title'], '⏰ الماتش بعد ١٥ دقيقة');
      expect(tier2['body'], contains('الدوري المصري الممتاز'));
    });

    test('FEATURE 2: Match starting in 30 minutes skips 1-hour tier but schedules 15-min tier', () async {
      final service = container.read(matchReminderServiceProvider);

      // Match 30 minutes from now (Cairo time)
      final cairoLocation = tz.getLocation('Africa/Cairo');
      final futureCairoTime = tz.TZDateTime.now(cairoLocation).add(const Duration(minutes: 30));
      final dateStr = '${futureCairoTime.year}-${futureCairoTime.month.toString().padLeft(2, '0')}-${futureCairoTime.day.toString().padLeft(2, '0')}';
      final timeStr = '${futureCairoTime.hour.toString().padLeft(2, '0')}:${futureCairoTime.minute.toString().padLeft(2, '0')}:00';

      final match = createMatch(matchId: 3003, matchDate: dateStr, matchTime: timeStr);

      await service.toggleReminder(match);

      // 1-hour is in the past, so only 15-min should be scheduled
      expect(mockNotificationService.scheduledNotifications.length, 1);
      final scheduled = mockNotificationService.scheduledNotifications.first;
      expect(scheduled['id'], MatchReminderService.getReminder15MinId(3003));
      expect(scheduled['title'], '⏰ الماتش بعد ١٥ دقيقة');
    });

    test('FEATURE 2: Disabling a reminder cancels all tiers and IDs for that match', () async {
      final service = container.read(matchReminderServiceProvider);

      final cairoLocation = tz.getLocation('Africa/Cairo');
      final futureCairoTime = tz.TZDateTime.now(cairoLocation).add(const Duration(hours: 4));
      final dateStr = '${futureCairoTime.year}-${futureCairoTime.month.toString().padLeft(2, '0')}-${futureCairoTime.day.toString().padLeft(2, '0')}';
      final timeStr = '${futureCairoTime.hour.toString().padLeft(2, '0')}:${futureCairoTime.minute.toString().padLeft(2, '0')}:00';

      final match = createMatch(matchId: 4004, matchDate: dateStr, matchTime: timeStr);

      // Toggle ON
      await service.toggleReminder(match);
      expect(container.read(isReminderSetProvider(4004)), isTrue);
      expect(mockNotificationService.scheduledNotifications.length, 2);

      // Toggle OFF
      await service.toggleReminder(match);
      expect(container.read(isReminderSetProvider(4004)), isFalse);

      // Verify cancellation of both IDs
      expect(mockNotificationService.cancelledNotificationIds, contains(MatchReminderService.getReminder1HrId(4004)));
      expect(mockNotificationService.cancelledNotificationIds, contains(MatchReminderService.getReminder15MinId(4004)));
      expect(mockNotificationService.cancelledNotificationIds, contains(MatchReminderService.getConfirmationNotificationId(4004)));
      expect(mockNotificationService.scheduledNotifications.isEmpty, isTrue);
    });

    test('Startup Rescheduling: Evaluates both 1-hour and 15-min tiers for active reminders', () async {
      final cairoLocation = tz.getLocation('Africa/Cairo');
      final futureCairoTime = tz.TZDateTime.now(cairoLocation).add(const Duration(hours: 2));
      final dateStr = '${futureCairoTime.year}-${futureCairoTime.month.toString().padLeft(2, '0')}-${futureCairoTime.day.toString().padLeft(2, '0')}';
      final timeStr = '${futureCairoTime.hour.toString().padLeft(2, '0')}:${futureCairoTime.minute.toString().padLeft(2, '0')}:00';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('match_reminders', [
        jsonEncode({
          'matchId': 5005,
          'matchDate': dateStr,
          'matchTime': timeStr,
          'homeName': 'الأهلي',
          'awayName': 'الزمالك',
          'competition': 'الدوري المصري',
        }),
      ]);

      final service = container.read(matchReminderServiceProvider);
      await service.rescheduleAllReminders();

      // Should have rescheduled both tiers
      expect(mockNotificationService.scheduledNotifications.length, 2);
      final ids = mockNotificationService.scheduledNotifications.map((n) => n['id']).toList();
      expect(ids, contains(50051));
      expect(ids, contains(50052));
    });
  });
}

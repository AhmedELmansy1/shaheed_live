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

  group('Match Reminder Service Tests (Server-Driven FCM & Confirmation)', () {
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

    test('FEATURE 2: Disabling a reminder cancels confirmation and removes from storage', () async {
      final service = container.read(matchReminderServiceProvider);

      final cairoLocation = tz.getLocation('Africa/Cairo');
      final futureCairoTime = tz.TZDateTime.now(cairoLocation).add(const Duration(hours: 4));
      final dateStr = '${futureCairoTime.year}-${futureCairoTime.month.toString().padLeft(2, '0')}-${futureCairoTime.day.toString().padLeft(2, '0')}';
      final timeStr = '${futureCairoTime.hour.toString().padLeft(2, '0')}:${futureCairoTime.minute.toString().padLeft(2, '0')}:00';

      final match = createMatch(matchId: 4004, matchDate: dateStr, matchTime: timeStr);

      // Toggle ON
      await service.toggleReminder(match);
      expect(container.read(isReminderSetProvider(4004)), isTrue);

      // Toggle OFF
      await service.toggleReminder(match);
      expect(container.read(isReminderSetProvider(4004)), isFalse);

      // Verify cancellation of IDs
      expect(mockNotificationService.cancelledNotificationIds, contains(MatchReminderService.getConfirmationNotificationId(4004)));
      expect(mockNotificationService.cancelledNotificationIds, contains(MatchReminderService.getReminder1HrId(4004)));
      expect(mockNotificationService.cancelledNotificationIds, contains(MatchReminderService.getReminder15MinId(4004)));
    });

    test('Startup Rescheduling: Cleans up concluded matches and retains upcoming matches', () async {
      final cairoLocation = tz.getLocation('Africa/Cairo');
      final futureCairoTime = tz.TZDateTime.now(cairoLocation).add(const Duration(hours: 2));
      final pastCairoTime = tz.TZDateTime.now(cairoLocation).subtract(const Duration(hours: 5));

      final futureDate = '${futureCairoTime.year}-${futureCairoTime.month.toString().padLeft(2, '0')}-${futureCairoTime.day.toString().padLeft(2, '0')}';
      final futureTime = '${futureCairoTime.hour.toString().padLeft(2, '0')}:${futureCairoTime.minute.toString().padLeft(2, '0')}:00';

      final pastDate = '${pastCairoTime.year}-${pastCairoTime.month.toString().padLeft(2, '0')}-${pastCairoTime.day.toString().padLeft(2, '0')}';
      final pastTime = '${pastCairoTime.hour.toString().padLeft(2, '0')}:${pastCairoTime.minute.toString().padLeft(2, '0')}:00';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('match_reminders', [
        jsonEncode({
          'matchId': 5005,
          'matchDate': futureDate,
          'matchTime': futureTime,
          'homeName': 'الأهلي',
          'awayName': 'الزمالك',
          'competition': 'الدوري المصري',
        }),
        jsonEncode({
          'matchId': 6006,
          'matchDate': pastDate,
          'matchTime': pastTime,
          'homeName': 'ليفربول',
          'awayName': 'مانشستر سيتي',
          'competition': 'الدوري الإنجليزي',
        }),
      ]);

      final service = container.read(matchReminderServiceProvider);
      await service.rescheduleAllReminders();

      // Only the upcoming match (5005) should be retained
      final updated = prefs.getStringList('match_reminders') ?? [];
      expect(updated.length, 1);
      final retainedData = jsonDecode(updated.first);
      expect(retainedData['matchId'], 5005);
    });
  });
}

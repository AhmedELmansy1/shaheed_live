import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/services/fcm_service.dart';
import 'package:shoot_live/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FCM Test Mode & Verification Tests (Phase 2.5)', () {
    test('Test notification topic constant is isolated and correct', () {
      expect(FcmService.testNotificationTopic, 'match_score_test_notifications');
      expect(FcmService.testTopicEnabledKey, 'is_test_notification_topic_enabled');
    });

    test('isTestNotificationTopicEnabled defaults to false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final fcmService = container.read(fcmServiceProvider);
      final isEnabled = await fcmService.isTestNotificationTopicEnabled();
      expect(isEnabled, isFalse);
    });

    test('enableTestNotificationTopic updates SharedPreferences flag', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(FcmService.testTopicEnabledKey, true);

      final fcmService = container.read(fcmServiceProvider);
      final isEnabled = await fcmService.isTestNotificationTopicEnabled();
      expect(isEnabled, isTrue);
    });

    test('disableTestNotificationTopic clears SharedPreferences flag', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(FcmService.testTopicEnabledKey, true);

      final fcmService = container.read(fcmServiceProvider);
      await fcmService.disableTestNotificationTopic();

      final isEnabled = await fcmService.isTestNotificationTopicEnabled();
      expect(isEnabled, isFalse);
    });

    test('Notification channels are defined with correct v2 identifiers', () {
      expect(NotificationService.channelMatches, 'matches_channel_v2');
      expect(NotificationService.channelReminders, 'match_reminders_v2');
      expect(NotificationService.channelLiveEvents, 'live_events_v2');
    });
  });
}


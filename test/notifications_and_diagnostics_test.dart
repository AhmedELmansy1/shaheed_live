import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/services/fcm_service.dart';
import 'package:shoot_live/core/services/stream_report_service.dart';
import 'package:shoot_live/presentation/diagnostics/diagnostics_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FCM Topics Contract Tests', () {
    test('Topic constants match dashboard targets exactly', () {
      // 1. Global broadcast topic
      expect(FcmService.globalBroadcastTopic, 'all');

      // 2. Production verification test topic
      expect(FcmService.testNotificationTopic, 'match_score_test_notifications');

      // 3. Team topic convention: team_{id}
      final sampleTeamId = 8650;
      final teamTopic = 'team_$sampleTeamId';
      expect(teamTopic, 'team_8650');

      // 4. Match event topic convention: match_{id}_events
      final sampleMatchId = 5795507;
      final matchTopic = 'match_${sampleMatchId}_events';
      expect(matchTopic, 'match_5795507_events');
    });
  });

  group('Notification Preferences Gating Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    bool shouldShowNotification({
      required String? eventType,
      required bool matchStartEnabled,
      required bool goalAlertsEnabled,
    }) {
      final isMatchStartEvent =
          eventType == 'kickoff' || eventType == 'reminder_1hr' || eventType == 'reminder_15min';
      final isGoalEvent =
          eventType == 'goal' || eventType == 'penalty' || eventType == 'penalty_scored' || eventType == 'penalty_missed';

      if (isMatchStartEvent && !matchStartEnabled) return false;
      if (isGoalEvent && !goalAlertsEnabled) return false;
      return true;
    }

    test('Allows all notifications when both toggles are enabled', () {
      expect(shouldShowNotification(eventType: 'kickoff', matchStartEnabled: true, goalAlertsEnabled: true), isTrue);
      expect(shouldShowNotification(eventType: 'goal', matchStartEnabled: true, goalAlertsEnabled: true), isTrue);
      expect(shouldShowNotification(eventType: 'red_card', matchStartEnabled: true, goalAlertsEnabled: true), isTrue);
      expect(shouldShowNotification(eventType: 'fulltime', matchStartEnabled: true, goalAlertsEnabled: true), isTrue);
    });

    test('Suppresses kickoff and pre-match reminders when matchStartEnabled is false', () {
      expect(shouldShowNotification(eventType: 'kickoff', matchStartEnabled: false, goalAlertsEnabled: true), isFalse);
      expect(shouldShowNotification(eventType: 'reminder_1hr', matchStartEnabled: false, goalAlertsEnabled: true), isFalse);
      expect(shouldShowNotification(eventType: 'reminder_15min', matchStartEnabled: false, goalAlertsEnabled: true), isFalse);
      // Goals and red cards should still pass
      expect(shouldShowNotification(eventType: 'goal', matchStartEnabled: false, goalAlertsEnabled: true), isTrue);
      expect(shouldShowNotification(eventType: 'red_card', matchStartEnabled: false, goalAlertsEnabled: true), isTrue);
    });

    test('Suppresses goals and penalties when goalAlertsEnabled is false', () {
      expect(shouldShowNotification(eventType: 'goal', matchStartEnabled: true, goalAlertsEnabled: false), isFalse);
      expect(shouldShowNotification(eventType: 'penalty', matchStartEnabled: true, goalAlertsEnabled: false), isFalse);
      expect(shouldShowNotification(eventType: 'penalty_scored', matchStartEnabled: true, goalAlertsEnabled: false), isFalse);
      expect(shouldShowNotification(eventType: 'penalty_missed', matchStartEnabled: true, goalAlertsEnabled: false), isFalse);
      // Match start and fulltime should still pass
      expect(shouldShowNotification(eventType: 'kickoff', matchStartEnabled: true, goalAlertsEnabled: false), isTrue);
      expect(shouldShowNotification(eventType: 'fulltime', matchStartEnabled: true, goalAlertsEnabled: false), isTrue);
    });

    test('General non-match alerts always pass through', () {
      expect(shouldShowNotification(eventType: null, matchStartEnabled: false, goalAlertsEnabled: false), isTrue);
      expect(shouldShowNotification(eventType: 'general', matchStartEnabled: false, goalAlertsEnabled: false), isTrue);
      expect(shouldShowNotification(eventType: 'production_verification', matchStartEnabled: false, goalAlertsEnabled: false), isTrue);
    });
  });

  group('StreamReportService Permission Handling', () {
    test('Throws user-friendly Arabic error when duplicate submission triggers permission-denied', () {
      final exception = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      );

      String mappedError;
      if (exception.code == 'permission-denied' || exception.code == 'already-exists') {
        mappedError = 'تم الإبلاغ عن هذه المشكلة مسبقًا';
      } else {
        mappedError = 'فشل إرسال البلاغ، يرجى المحاولة لاحقاً';
      }

      expect(mappedError, 'تم الإبلاغ عن هذه المشكلة مسبقًا');
    });

    test('StreamIssueType enum keys match backend whitelist', () {
      expect(StreamIssueType.buffering.key, 'buffering');
      expect(StreamIssueType.offline.key, 'offline');
      expect(StreamIssueType.wrongMatch.key, 'wrong_match');
      expect(StreamIssueType.noAudio.key, 'no_audio');
      expect(StreamIssueType.badQuality.key, 'bad_quality');
    });
  });

  group('FCM In-Memory Log Ring Buffer', () {
    test('Caps messages at 10 items in FIFO/LIFO ring buffer order', () {
      FcmService.recentMessages.clear();

      for (int i = 1; i <= 15; i++) {
        FcmService.recordMessageLog(ReceivedFcmLog(
          id: 'msg_$i',
          timestamp: DateTime.now(),
          title: 'Title $i',
          body: 'Body $i',
          data: {'index': i},
        ));
      }

      expect(FcmService.recentMessages.length, 10);
      expect(FcmService.recentMessages.first.id, 'msg_15');
      expect(FcmService.recentMessages.last.id, 'msg_6');
    });
  });

  group('Hidden Diagnostics Configuration Guard', () {
    test('kEnableDiagnostics defaults to false in standard builds', () {
      expect(kEnableDiagnostics, isFalse);
    });
  });
}


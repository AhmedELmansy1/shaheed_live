import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/presentation/match_details/controllers/live_match_polling_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LiveMatchPollingManager Lifecycle & Guard Tests', () {
    test('Does NOT start polling when match is NOT live', () async {
      int pollCount = 0;
      final manager = LiveMatchPollingManager(
        isLive: false,
        onPoll: () async => pollCount++,
        baseInterval: const Duration(seconds: 1),
      );

      manager.start();
      expect(manager.isActive, isFalse);
      expect(pollCount, 0);

      manager.dispose();
    });

    test('Starts timer and executes poll when match is live', () async {
      int pollCount = 0;
      final manager = LiveMatchPollingManager(
        isLive: true,
        onPoll: () async => pollCount++,
        baseInterval: const Duration(milliseconds: 50),
      );

      manager.start();
      expect(manager.isActive, isTrue);

      await Future.delayed(const Duration(milliseconds: 120));
      expect(pollCount, greaterThanOrEqualTo(1));

      manager.dispose();
      expect(manager.isActive, isFalse);
    });

    test('Prevents overlapping async requests while a poll is in flight', () async {
      int concurrentCalls = 0;
      int maxConcurrent = 0;
      int completedCalls = 0;

      final manager = LiveMatchPollingManager(
        isLive: true,
        onPoll: () async {
          concurrentCalls++;
          if (concurrentCalls > maxConcurrent) {
            maxConcurrent = concurrentCalls;
          }
          await Future.delayed(const Duration(milliseconds: 60));
          concurrentCalls--;
          completedCalls++;
        },
        baseInterval: const Duration(milliseconds: 20),
      );

      // Trigger multiple polls concurrently
      manager.executePoll();
      manager.executePoll();
      manager.executePoll();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(maxConcurrent, 1, reason: 'Must never execute concurrent polls');
      expect(completedCalls, greaterThanOrEqualTo(1));

      manager.dispose();
    });

    test('Pauses on app background and resumes on foreground', () async {
      int pollCount = 0;
      final manager = LiveMatchPollingManager(
        isLive: true,
        onPoll: () async => pollCount++,
        baseInterval: const Duration(milliseconds: 50),
      );

      manager.start();
      expect(manager.isActive, isTrue);

      // Simulate app sent to background
      manager.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(manager.isPaused, isTrue);
      expect(manager.isActive, isFalse);

      final countAtPause = pollCount;
      await Future.delayed(const Duration(milliseconds: 100));
      // No polling should occur while paused
      expect(pollCount, countAtPause);

      // Simulate app resumed
      manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(manager.isPaused, isFalse);

      await Future.delayed(const Duration(milliseconds: 80));
      expect(pollCount, greaterThan(countAtPause));

      manager.dispose();
    });

    test('Applies backoff interval on errors and resets on success', () async {
      bool shouldThrow = true;
      int pollAttempts = 0;

      final manager = LiveMatchPollingManager(
        isLive: true,
        onPoll: () async {
          pollAttempts++;
          if (shouldThrow) {
            throw Exception('Simulated network failure');
          }
        },
        baseInterval: const Duration(milliseconds: 40),
        errorBackoffInterval: const Duration(milliseconds: 80),
      );

      // First run fails -> increments consecutiveErrors and sets backoff
      await manager.executePoll();
      expect(manager.consecutiveErrors, 1);

      // Successful recovery resets consecutiveErrors
      shouldThrow = false;
      await manager.executePoll();
      expect(manager.consecutiveErrors, 0);
      expect(pollAttempts, 2);

      manager.dispose();
    });

    test('Cancels all timers cleanly on dispose', () async {
      int pollCount = 0;
      final manager = LiveMatchPollingManager(
        isLive: true,
        onPoll: () async => pollCount++,
        baseInterval: const Duration(milliseconds: 50),
      );

      manager.start();
      expect(manager.isActive, isTrue);

      manager.dispose();
      expect(manager.isActive, isFalse);
      expect(manager.isDisposed, isTrue);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(pollCount, 0);
    });
  });
}

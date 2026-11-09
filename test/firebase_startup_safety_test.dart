import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoot_live/core/services/firebase_ready_provider.dart';

void main() {
  group('Firebase Startup Safety Tests', () {
    test('Initial state is uninitialized and not ready', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(firebaseReadyProvider);
      expect(state.status, FirebaseInitStatus.uninitialized);
      expect(state.isReady, isFalse);
      expect(state.initDurationMs, 0);
      expect(state.error, isNull);
    });

    test('markReadyManually updates state to ready with duration and completes awaitReady', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(firebaseReadyProvider.notifier);

      // Start waiting asynchronously
      final readyFuture = notifier.awaitReady(timeout: const Duration(seconds: 2));

      // Simulate Firebase completion
      notifier.markReadyManually(durationMs: 142);

      final ready = await readyFuture;
      expect(ready, isTrue);

      final state = container.read(firebaseReadyProvider);
      expect(state.status, FirebaseInitStatus.ready);
      expect(state.isReady, isTrue);
      expect(state.initDurationMs, 142);
      expect(state.error, isNull);
    });

    test('markFailedManually updates state to failed and awaitReady resolves to false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(firebaseReadyProvider.notifier);

      final readyFuture = notifier.awaitReady(timeout: const Duration(seconds: 2));

      notifier.markFailedManually('PlatformException(core, no-app)', durationMs: 45);

      final ready = await readyFuture;
      expect(ready, isFalse);

      final state = container.read(firebaseReadyProvider);
      expect(state.status, FirebaseInitStatus.failed);
      expect(state.isReady, isFalse);
      expect(state.initDurationMs, 45);
      expect(state.error, contains('no-app'));
    });

    test('awaitReady returns false gracefully on timeout when uninitialized', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(firebaseReadyProvider.notifier);

      final ready = await notifier.awaitReady(timeout: const Duration(milliseconds: 50));
      expect(ready, isFalse);
    });
  });
}

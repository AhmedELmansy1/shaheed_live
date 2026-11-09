import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/services/firebase_ready_provider.dart';
import 'package:shoot_live/core/services/sync_queue_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Deferred Sync Reconciliation Tests (Offline-then-Online)', () {
    test('enqueueOnboardingSync persists pending flag and team list', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final syncQueue = container.read(syncQueueServiceProvider);
      await syncQueue.enqueueOnboardingSync(['8650', '9826']);

      final hasPending = await syncQueue.hasPendingSync();
      expect(hasPending, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SyncQueueService.keyPendingOnboardingSync), isTrue);
      expect(prefs.getStringList(SyncQueueService.keyPendingSyncTeams), ['8650', '9826']);

      final statusDesc = await syncQueue.getSyncStatusDescription();
      expect(statusDesc, contains('2 فرق'));
    });

    test('processPendingSync defers if Firebase is not ready yet', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final syncQueue = container.read(syncQueueServiceProvider);
      await syncQueue.enqueueOnboardingSync(['8650']);

      // Firebase is still uninitialized
      final success = await syncQueue.processPendingSync();
      expect(success, isFalse);

      // Pending flag must remain true for retry
      final hasPending = await syncQueue.hasPendingSync();
      expect(hasPending, isTrue);
    });

    test('reconciles and clears pending flag once Firebase is ready and sync succeeds', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final syncQueue = container.read(syncQueueServiceProvider);
      await syncQueue.enqueueOnboardingSync(['8650']);

      // Mark Firebase ready manually
      container.read(firebaseReadyProvider.notifier).markReadyManually(durationMs: 80);

      // Process pending sync
      final success = await syncQueue.processPendingSync();
      expect(success, isTrue);

      // Pending flag must now be false
      final hasPending = await syncQueue.hasPendingSync();
      expect(hasPending, isFalse);

      final statusDesc = await syncQueue.getSyncStatusDescription();
      expect(statusDesc, contains('متزامن بالكامل'));
    });
  });
}

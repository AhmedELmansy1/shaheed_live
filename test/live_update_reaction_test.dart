// ignore_for_file: subtype_of_sealed_class
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/network/dio_client.dart';
import 'package:shoot_live/core/routing/app_router.dart';
import 'package:shoot_live/core/services/remote_config_service.dart';
import 'package:shoot_live/core/services/update_service.dart';
import 'package:shoot_live/data/models/ad_config_model.dart';
import 'package:shoot_live/main.dart';
import 'package:shoot_live/presentation/home/home_screen.dart';
import 'package:shoot_live/presentation/update/force_update_screen.dart';

import 'package:shoot_live/presentation/home/providers/matches_provider.dart';
import 'package:shoot_live/data/repositories/matches_repository.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/match_info_model.dart';
import 'package:shoot_live/data/models/match_statistics_model.dart';
import 'package:shoot_live/data/models/match_event_model.dart';
import 'package:shoot_live/data/models/match_lineup_model.dart';

class FakeMatchesRepository implements MatchesRepository {
  @override
  Future<List<MatchModel>> getMatchesToday() async => [];
  @override
  Future<List<MatchModel>> getMatchesTomorrow() async => [];
  @override
  Future<List<MatchModel>> getMatchesYesterday() async => [];
  @override
  Future<List<MatchModel>> getMatchesByDate(String date) async => [];
  @override
  Future<MatchInfoModel?> getMatchInfo(String matchId) async => null;
  @override
  Future<MatchStatisticsModel?> getMatchStatistics(String matchId, {required dynamic homeTeamId, required dynamic awayTeamId}) async => null;
  @override
  Future<List<MatchEventModel>> getMatchEvents(String matchId) async => [];
  @override
  Future<MatchLineupModel?> getMatchLineup(String matchId, {required dynamic homeTeamId, required dynamic awayTeamId}) async => null;
}

/// Fake DocumentSnapshot for live stream testing
class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  final bool _exists;

  FakeDocumentSnapshot(this._data, [this._exists = true]);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => _exists;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'hasCompletedNotificationSetup': true,
      'hasCompletedOnboarding': true,
    });
  });

  group('Live Real-Time Remote Config Verification', () {
    testWidgets('Live Test 1: Real-time force_update=true while idle on Home triggers instant redirect to ForceUpdateScreen without restart', (WidgetTester tester) async {
      final streamController = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

      // Initial state: App is at v1.0.0, latest is v1.0.0, force_update is false
      final initialData = {
        'latest_app_version': '1.0.0',
        'min_supported_version': '1.0.0',
        'force_update': false,
        'update_download_url': 'https://shootlive.app/download',
        'ad_config': {},
      };

      final testRemoteConfigService = TestRemoteConfigService(
        stream: streamController.stream,
        dioClient: DioClient(),
      );

      final container = ProviderContainer(
        overrides: [
          remoteConfigServiceProvider.overrideWithValue(testRemoteConfigService),
          currentAppVersionProvider.overrideWith((ref) => Future.value('1.0.0')),
          matchesRepositoryProvider.overrideWithValue(FakeMatchesRepository()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ShootLiveApp(),
        ),
      );

      // Seed initial state
      streamController.add(FakeDocumentSnapshot(initialData));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Navigate to /home directly
      container.read(appRouterProvider).go('/home');
      await tester.pump(const Duration(milliseconds: 300));

      // Confirm we are sitting on HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(ForceUpdateScreen), findsNothing);
      // ignore: avoid_print
      print('[LIVE TEST 1] User is currently sitting on HomeScreen. App version: 1.0.0');

      // LIVE ACTION: Firestore Console update pushed: force_update = true, latest_app_version = 1.1.0
      final stopwatch = Stopwatch()..start();
      // ignore: avoid_print
      print('[LIVE TEST 1] Simulating Firebase Console edit: Setting force_update=true, latest_app_version=1.1.0 in config/app_settings');

      streamController.add(FakeDocumentSnapshot({
        'latest_app_version': '1.1.0',
        'min_supported_version': '1.0.0',
        'force_update': true,
        'update_download_url': 'https://shootlive.app/download',
        'ad_config': {},
      }));

      await tester.pump(); // Deliver stream event to listeners
      await tester.pump(const Duration(milliseconds: 300)); // Allow GoRouter to complete route redirect transition
      stopwatch.stop();

      // ignore: avoid_print
      print('[LIVE TEST 1] Reactive redirect completed in ${stopwatch.elapsedMilliseconds} ms without app restart!');

      // VERIFICATION: GoRouter automatically redirected to ForceUpdateScreen
      expect(find.byType(ForceUpdateScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      // ignore: avoid_print
      print('[LIVE TEST 1] Verified: ForceUpdateScreen is now active on screen.');

      container.dispose();
      await streamController.close();
    });

    testWidgets('Live Test 2: Real-time latest_app_version bump with force_update=false shows SoftUpdateBanner, dismisses for session, reappears on fresh session', (WidgetTester tester) async {
      final streamController = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

      final initialData = {
        'latest_app_version': '1.0.0',
        'min_supported_version': '1.0.0',
        'force_update': false,
        'ad_config': {},
      };

      final testRemoteConfigService = TestRemoteConfigService(
        stream: streamController.stream,
        dioClient: DioClient(),
      );

      final container = ProviderContainer(
        overrides: [
          remoteConfigServiceProvider.overrideWithValue(testRemoteConfigService),
          currentAppVersionProvider.overrideWith((ref) => Future.value('1.0.0')),
          matchesRepositoryProvider.overrideWithValue(FakeMatchesRepository()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ShootLiveApp(),
        ),
      );

      streamController.add(FakeDocumentSnapshot(initialData));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      container.read(appRouterProvider).go('/home');
      await tester.pump(const Duration(milliseconds: 300));

      // Confirm SoftUpdateBanner is hidden when app is up to date
      expect(find.text('يتوفر تحديث جديد للتطبيق'), findsNothing);
      // ignore: avoid_print
      print('[LIVE TEST 2] SoftUpdateBanner is initially HIDDEN (app up to date).');

      // LIVE ACTION: Firebase Console update pushed: latest_app_version = 1.2.0 (force_update remains false)
      // ignore: avoid_print
      print('[LIVE TEST 2] Simulating Firebase Console edit: Bumping latest_app_version to 1.2.0 (force_update=false)');
      final updatedData = {
        'latest_app_version': '1.2.0',
        'min_supported_version': '1.0.0',
        'force_update': false,
        'update_download_url': 'https://shootlive.app/download',
        'ad_config': {},
      };
      streamController.add(FakeDocumentSnapshot(updatedData));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // VERIFICATION: Banner appears live on HomeScreen
      expect(find.text('يتوفر تحديث جديد للتطبيق'), findsOneWidget);
      // ignore: avoid_print
      print('[LIVE TEST 2] Verified: SoftUpdateBanner appeared live on HomeScreen without restart!');

      // DISMISS ACTION: Tap close button (✕)
      // ignore: avoid_print
      print('[LIVE TEST 2] User taps dismiss (✕) button on the banner.');
      container.read(softPromptDismissedProvider.notifier).dismiss();
      await tester.pump(const Duration(milliseconds: 300));

      // VERIFICATION: Banner is now dismissed for the rest of this session
      expect(find.text('يتوفر تحديث جديد للتطبيق'), findsNothing);
      // ignore: avoid_print
      print('[LIVE TEST 2] Verified: SoftUpdateBanner dismissed for current session.');

      // Clean up first session container
      container.dispose();

      // FRESH SESSION SIMULATION: New ProviderContainer (representing app restart)
      // ignore: avoid_print
      print('[LIVE TEST 2] Simulating fresh app launch/restart with new session container...');
      final freshContainer = ProviderContainer(
        overrides: [
          remoteConfigServiceProvider.overrideWithValue(testRemoteConfigService),
          currentAppVersionProvider.overrideWith((ref) => Future.value('1.0.0')),
          matchesRepositoryProvider.overrideWithValue(FakeMatchesRepository()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: freshContainer,
          child: const ShootLiveApp(),
        ),
      );
      streamController.add(FakeDocumentSnapshot(updatedData));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      freshContainer.read(appRouterProvider).go('/home');
      await tester.pump(const Duration(milliseconds: 300));

      // VERIFICATION: On fresh session, banner reappears because app is still outdated
      expect(find.text('يتوفر تحديث جديد للتطبيق'), findsOneWidget);
      // ignore: avoid_print
      print('[LIVE TEST 2] Verified: SoftUpdateBanner reappeared on fresh cold start as expected.');

      freshContainer.dispose();
      await streamController.close();
    });
  });
}

class TestRemoteConfigService extends RemoteConfigService {
  final Stream<DocumentSnapshot<Map<String, dynamic>>> _testStream;

  TestRemoteConfigService({
    required Stream<DocumentSnapshot<Map<String, dynamic>>> stream,
    required super.dioClient,
  })  : _testStream = stream,
        super();

  @override
  Stream<RemoteConfigModel> listenToRemoteConfig() {
    return _testStream.map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return RemoteConfigModel.fromMap(snapshot.data()!);
      }
      return const RemoteConfigModel();
    });
  }

  @override
  Stream<AdConfig> listenToAdConfig() {
    return _testStream.map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final adConfigMap = data['ad_config'] as Map<String, dynamic>?;
        if (adConfigMap != null && adConfigMap.isNotEmpty) {
          return AdConfig.fromMap(adConfigMap);
        }
      }
      return const AdConfig();
    });
  }
}

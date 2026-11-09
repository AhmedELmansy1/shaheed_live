// ignore_for_file: subtype_of_sealed_class, unused_import
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/config/app_constants.dart';
import 'package:shoot_live/core/network/dio_client.dart';
import 'package:shoot_live/core/routing/app_router.dart';
import 'package:shoot_live/core/services/notification_service.dart';
import 'package:shoot_live/core/services/remote_config_service.dart';
import 'package:shoot_live/core/services/update_service.dart';
import 'package:shoot_live/data/models/ad_config_model.dart';
import 'package:shoot_live/data/models/match_event_model.dart';
import 'package:shoot_live/data/models/match_info_model.dart';
import 'package:shoot_live/data/models/match_lineup_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/match_statistics_model.dart';
import 'package:shoot_live/data/repositories/matches_repository.dart';
import 'package:shoot_live/presentation/home/providers/matches_provider.dart';
import 'package:shoot_live/presentation/shell/main_shell.dart';
import 'package:shoot_live/main.dart';

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  FakeDocumentSnapshot(this._data);

  @override
  Map<String, dynamic>? data() => _data;
  @override
  bool get exists => _data != null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

class FakeMatchesRepository implements MatchesRepository {
  @override
  Future<List<MatchModel>> getMatchesByDate(String date, {bool forceRefresh = false}) async => [];
  @override
  Future<List<MatchModel>> getMatchesToday({bool forceRefresh = false}) async => [];
  @override
  Future<List<MatchModel>> getMatchesTomorrow({bool forceRefresh = false}) async => [];
  @override
  Future<List<MatchModel>> getMatchesYesterday({bool forceRefresh = false}) async => [];
  @override
  Future<MatchInfoModel?> getMatchInfo(String matchId, {bool forceRefresh = false}) async => null;
  @override
  Future<MatchStatisticsModel?> getMatchStatistics(String matchId, {required dynamic homeTeamId, required dynamic awayTeamId, bool forceRefresh = false}) async => null;
  @override
  Future<List<MatchEventModel>> getMatchEvents(String matchId, {bool forceRefresh = false}) async => [];
  @override
  Future<MatchLineupModel?> getMatchLineup(String matchId, {required dynamic homeTeamId, required dynamic awayTeamId, bool forceRefresh = false}) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation & StatefulShellRoute Guards Verification', () {
    late StreamController<DocumentSnapshot<Map<String, dynamic>>> streamController;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'hasCompletedNotificationSetup': true,
        'hasCompletedOnboarding': true,
      });
      streamController = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();
    });

    tearDown(() async {
      await streamController.close();
    });

    testWidgets('Verification 1: Bottom Navigation Bar displays and switches between all 3 tabs', (tester) async {
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

      // 1. Verify Home tab is active and visible
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('الدوريات'), findsOneWidget);
      expect(find.text('الإعدادات'), findsOneWidget);

      // 2. Tap Leagues tab (Index 1)
      await tester.tap(find.text('الدوريات'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('الدوريات والبطولات'), findsOneWidget);

      // 3. Tap Settings tab (Index 2)
      await tester.tap(find.text('الإعدادات'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('إعدادات التطبيق'), findsOneWidget);
      expect(find.text('المظهر العام'), findsOneWidget);
      expect(find.text('إدارة الأندية المفضلة'), findsOneWidget);

      // 4. Tap Home tab (Index 0)
      await tester.tap(find.text('الرئيسية'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(AppConstants.appName), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      container.dispose();
    });

    testWidgets('Verification 2: Onboarding guards redirect unauthorized access to /onboarding/leagues', (tester) async {
      SharedPreferences.setMockInitialValues({
        'hasCompletedNotificationSetup': true,
        'hasCompletedOnboarding': false, // Incomplete onboarding
      });

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

      // Attempt to go to /home without completed onboarding
      container.read(appRouterProvider).go('/home');
      await tester.pump(const Duration(milliseconds: 300));

      // Guard intercepts and redirects to /onboarding/leagues
      expect(find.text('اختيار الدوريات'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      container.dispose();
    });

    testWidgets('Verification 3: Notification tap callback routes to MatchDetailsScreen', (tester) async {
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

      // Simulate notification tap
      NotificationService.onMatchNotificationTap!('9999');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Confirmed arrived at MatchDetailsScreen for match 9999
      expect(find.text('تفاصيل المباراة'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      container.dispose();
    });
  });
}

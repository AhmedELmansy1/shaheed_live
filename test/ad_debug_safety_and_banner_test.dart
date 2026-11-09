import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/core/services/ad_service.dart';
import 'package:shoot_live/core/services/remote_config_service.dart';
import 'package:shoot_live/data/models/ad_config_model.dart';
import 'package:shoot_live/presentation/widgets/banner_ad_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ad Debug Safety & Test Unit ID Isolation', () {
    test('AdConfig.withTestUnitIds() forces Google official test IDs on all placements', () {
      final realFirestoreConfig = AdConfig(
        bannerHome: const BannerAdPlacementConfig(
          enabled: true,
          adUnitId: 'ca-app-pub-1570465222301773/6142397125', // Real banner ID
        ),
        bannerMatchDetails: const BannerAdPlacementConfig(
          enabled: true,
          adUnitId: 'ca-app-pub-1570465222301773/9999999999',
        ),
        interstitialMatchOpen: const InterstitialAdPlacementConfig(
          enabled: true,
          adUnitId: 'ca-app-pub-1570465222301773/8888888888',
          frequencyCap: 4,
        ),
        nativeMatchList: const NativeAdPlacementConfig(
          enabled: true,
          adUnitId: 'ca-app-pub-1570465222301773/7777777777',
          insertEveryNItems: 6,
        ),
        appOpenAd: const AppOpenAdPlacementConfig(
          enabled: true,
          adUnitId: 'ca-app-pub-1570465222301773/6666666666',
        ),
        rewardedAd: const RewardedAdPlacementConfig(
          enabled: true,
          adUnitId: 'ca-app-pub-1570465222301773/5555555555',
        ),
      );

      final debugSafeConfig = realFirestoreConfig.withTestUnitIds();

      // All real unit IDs must be replaced with official test IDs
      expect(debugSafeConfig.bannerHome.adUnitId, equals(AdConfig.testBannerId));
      expect(debugSafeConfig.bannerMatchDetails.adUnitId, equals(AdConfig.testBannerId));
      expect(debugSafeConfig.interstitialMatchOpen.adUnitId, equals(AdConfig.testInterstitialId));
      expect(debugSafeConfig.nativeMatchList.adUnitId, equals(AdConfig.testNativeId));
      expect(debugSafeConfig.appOpenAd.adUnitId, equals(AdConfig.testAppOpenId));
      expect(debugSafeConfig.rewardedAd.adUnitId, equals(AdConfig.testRewardedId));

      // Enablement and frequency settings from Firestore must be preserved
      expect(debugSafeConfig.bannerHome.enabled, isTrue);
      expect(debugSafeConfig.interstitialMatchOpen.frequencyCap, equals(4));
      expect(debugSafeConfig.nativeMatchList.insertEveryNItems, equals(6));
    });

    test('AdConfig.fromMap preserves real ad unit IDs without test fallbacks in release data', () {
      final rawMap = {
        'banner_home': {
          'enabled': true,
          'ad_unit_id': 'ca-app-pub-1570465222301773/6142397125',
        },
        'banner_match_details': {
          'enabled': false,
          'ad_unit_id': '',
        },
      };

      final config = AdConfig.fromMap(rawMap);
      expect(config.bannerHome.adUnitId, equals('ca-app-pub-1570465222301773/6142397125'));
      expect(config.bannerHome.enabled, isTrue);
      expect(config.bannerMatchDetails.adUnitId, isEmpty);
      expect(config.bannerMatchDetails.enabled, isFalse);
    });

    test('currentAdConfigProvider in test/debug environment returns test unit IDs', () async {
      final realFirestoreConfig = AdConfig(
        bannerHome: const BannerAdPlacementConfig(
          enabled: true,
          adUnitId: 'ca-app-pub-1570465222301773/6142397125',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          adConfigStreamProvider.overrideWith((ref) => Stream.value(realFirestoreConfig)),
        ],
      );
      addTearDown(container.dispose);

      // Listen to prime the provider stream
      final sub = container.listen(currentAdConfigProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final resolved = sub.read();
      // In test/debug mode (!kReleaseMode), test banner ID must be returned instead of real ID
      expect(!kReleaseMode, isTrue);
      expect(resolved.bannerHome.adUnitId, equals(AdConfig.testBannerId));
      expect(resolved.bannerHome.enabled, isTrue);
    });

    test('AdService includes EMULATOR in testDeviceIds', () {
      expect(AdService.testDeviceIds, contains('EMULATOR'));
    });
  });

  group('BannerAdWidget Structure & Invariants', () {
    testWidgets('collapses to SizedBox.shrink() when banner placement is disabled', (tester) async {
      final disabledConfig = const AdConfig(
        bannerHome: BannerAdPlacementConfig(enabled: false, adUnitId: ''),
      );

      final container = ProviderContainer(
        overrides: [
          adConfigStreamProvider.overrideWith((ref) => Stream.value(disabledConfig)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const Directionality(
            textDirection: TextDirection.rtl,
            child: BannerAdWidget(placement: BannerPlacement.home),
          ),
        ),
      );

      expect(find.byType(BannerAdWidget), findsOneWidget);
      // Should collapse without rendering any AdWidget or reserved space
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}

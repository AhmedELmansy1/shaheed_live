/// Configuration model for banner ad placements.
class BannerAdPlacementConfig {
  final bool enabled;
  final String adUnitId;

  const BannerAdPlacementConfig({this.enabled = false, this.adUnitId = ''});

  factory BannerAdPlacementConfig.fromMap(
    Map<String, dynamic>? map, {
    String defaultAdUnitId = '',
  }) {
    if (map == null) {
      return BannerAdPlacementConfig(adUnitId: defaultAdUnitId);
    }
    return BannerAdPlacementConfig(
      enabled: (map['enabled'] as bool?) ?? false,
      adUnitId: (map['ad_unit_id'] as String?) ?? defaultAdUnitId,
    );
  }

  Map<String, dynamic> toMap() => {'enabled': enabled, 'ad_unit_id': adUnitId};
}

/// Configuration model for interstitial ad placements.
class InterstitialAdPlacementConfig {
  final bool enabled;
  final String adUnitId;
  final int frequencyCap;

  const InterstitialAdPlacementConfig({
    this.enabled = false,
    this.adUnitId = '',
    this.frequencyCap = 3,
  });

  factory InterstitialAdPlacementConfig.fromMap(
    Map<String, dynamic>? map, {
    String defaultAdUnitId = '',
  }) {
    if (map == null) {
      return InterstitialAdPlacementConfig(adUnitId: defaultAdUnitId);
    }
    return InterstitialAdPlacementConfig(
      enabled: (map['enabled'] as bool?) ?? false,
      adUnitId: (map['ad_unit_id'] as String?) ?? defaultAdUnitId,
      frequencyCap: (map['frequency_cap'] as num?)?.toInt() ?? 3,
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'ad_unit_id': adUnitId,
    'frequency_cap': frequencyCap,
  };
}

/// Configuration model for native list ad placements.
class NativeAdPlacementConfig {
  final bool enabled;
  final String adUnitId;
  final int insertEveryNItems;

  const NativeAdPlacementConfig({
    this.enabled = false,
    this.adUnitId = '',
    this.insertEveryNItems = 5,
  });

  factory NativeAdPlacementConfig.fromMap(
    Map<String, dynamic>? map, {
    String defaultAdUnitId = '',
  }) {
    if (map == null) {
      return NativeAdPlacementConfig(adUnitId: defaultAdUnitId);
    }
    return NativeAdPlacementConfig(
      enabled: (map['enabled'] as bool?) ?? false,
      adUnitId: (map['ad_unit_id'] as String?) ?? defaultAdUnitId,
      insertEveryNItems: (map['insert_every_n_items'] as num?)?.toInt() ?? 5,
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'ad_unit_id': adUnitId,
    'insert_every_n_items': insertEveryNItems,
  };
}

/// Configuration model for app open ad placements.
class AppOpenAdPlacementConfig {
  final bool enabled;
  final String adUnitId;

  const AppOpenAdPlacementConfig({this.enabled = false, this.adUnitId = ''});

  factory AppOpenAdPlacementConfig.fromMap(
    Map<String, dynamic>? map, {
    String defaultAdUnitId = '',
  }) {
    if (map == null) {
      return AppOpenAdPlacementConfig(adUnitId: defaultAdUnitId);
    }
    return AppOpenAdPlacementConfig(
      enabled: (map['enabled'] as bool?) ?? false,
      adUnitId: (map['ad_unit_id'] as String?) ?? defaultAdUnitId,
    );
  }

  Map<String, dynamic> toMap() => {'enabled': enabled, 'ad_unit_id': adUnitId};
}

/// Configuration model for rewarded ad placements.
class RewardedAdPlacementConfig {
  final bool enabled;
  final String adUnitId;

  const RewardedAdPlacementConfig({this.enabled = false, this.adUnitId = ''});

  factory RewardedAdPlacementConfig.fromMap(
    Map<String, dynamic>? map, {
    String defaultAdUnitId = '',
  }) {
    if (map == null) {
      return RewardedAdPlacementConfig(adUnitId: defaultAdUnitId);
    }
    return RewardedAdPlacementConfig(
      enabled: (map['enabled'] as bool?) ?? false,
      adUnitId: (map['ad_unit_id'] as String?) ?? defaultAdUnitId,
    );
  }

  Map<String, dynamic> toMap() => {'enabled': enabled, 'ad_unit_id': adUnitId};
}

/// Master AdConfig model representing `config/ad_config` in Firestore.
class AdConfig {
  final BannerAdPlacementConfig bannerHome;
  final BannerAdPlacementConfig bannerMatchDetails;
  final InterstitialAdPlacementConfig interstitialMatchOpen;
  final NativeAdPlacementConfig nativeMatchList;
  final AppOpenAdPlacementConfig appOpenAd;
  final RewardedAdPlacementConfig rewardedAd;

  const AdConfig({
    this.bannerHome = const BannerAdPlacementConfig(),
    this.bannerMatchDetails = const BannerAdPlacementConfig(),
    this.interstitialMatchOpen = const InterstitialAdPlacementConfig(),
    this.nativeMatchList = const NativeAdPlacementConfig(),
    this.appOpenAd = const AppOpenAdPlacementConfig(),
    this.rewardedAd = const RewardedAdPlacementConfig(),
  });

  /// Official Google AdMob test ad unit IDs for Android.
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testNativeId = 'ca-app-pub-3940256099942544/2247696110';
  static const String testAppOpenId = 'ca-app-pub-3940256099942544/9257395921';
  static const String testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  /// Initial test configuration with official test ad unit IDs.
  factory AdConfig.testDefaults({bool enablePlacements = true}) {
    return AdConfig(
      bannerHome: BannerAdPlacementConfig(
        enabled: enablePlacements,
        adUnitId: testBannerId,
      ),
      bannerMatchDetails: BannerAdPlacementConfig(
        enabled: enablePlacements,
        adUnitId: testBannerId,
      ),
      interstitialMatchOpen: InterstitialAdPlacementConfig(
        enabled: enablePlacements,
        adUnitId: testInterstitialId,
        frequencyCap: 3,
      ),
      nativeMatchList: NativeAdPlacementConfig(
        enabled: enablePlacements,
        adUnitId: testNativeId,
        insertEveryNItems: 5,
      ),
      appOpenAd: AppOpenAdPlacementConfig(
        enabled: enablePlacements,
        adUnitId: testAppOpenId,
      ),
      rewardedAd: const RewardedAdPlacementConfig(
        enabled: false,
        adUnitId: testRewardedId,
      ),
    );
  }

  factory AdConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const AdConfig();
    }
    return AdConfig(
      bannerHome: BannerAdPlacementConfig.fromMap(
        map['banner_home'] as Map<String, dynamic>?,
      ),
      bannerMatchDetails: BannerAdPlacementConfig.fromMap(
        map['banner_match_details'] as Map<String, dynamic>?,
      ),
      interstitialMatchOpen: InterstitialAdPlacementConfig.fromMap(
        map['interstitial_match_open'] as Map<String, dynamic>?,
      ),
      nativeMatchList: NativeAdPlacementConfig.fromMap(
        map['native_match_list'] as Map<String, dynamic>?,
      ),
      appOpenAd: AppOpenAdPlacementConfig.fromMap(
        map['app_open_ad'] as Map<String, dynamic>?,
      ),
      rewardedAd: RewardedAdPlacementConfig.fromMap(
        map['rewarded_ad'] as Map<String, dynamic>?,
      ),
    );
  }

  /// Returns a copy of [AdConfig] where all placement ad unit IDs are forced
  /// to Google's official test unit IDs for debug and profile builds.
  /// Placement enablement and frequency configs from Firestore are strictly preserved.
  AdConfig withTestUnitIds() {
    return AdConfig(
      bannerHome: BannerAdPlacementConfig(
        enabled: bannerHome.enabled,
        adUnitId: testBannerId,
      ),
      bannerMatchDetails: BannerAdPlacementConfig(
        enabled: bannerMatchDetails.enabled,
        adUnitId: testBannerId,
      ),
      interstitialMatchOpen: InterstitialAdPlacementConfig(
        enabled: interstitialMatchOpen.enabled,
        adUnitId: testInterstitialId,
        frequencyCap: interstitialMatchOpen.frequencyCap,
      ),
      nativeMatchList: NativeAdPlacementConfig(
        enabled: nativeMatchList.enabled,
        adUnitId: testNativeId,
        insertEveryNItems: nativeMatchList.insertEveryNItems,
      ),
      appOpenAd: AppOpenAdPlacementConfig(
        enabled: appOpenAd.enabled,
        adUnitId: testAppOpenId,
      ),
      rewardedAd: RewardedAdPlacementConfig(
        enabled: rewardedAd.enabled,
        adUnitId: testRewardedId,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'banner_home': bannerHome.toMap(),
    'banner_match_details': bannerMatchDetails.toMap(),
    'interstitial_match_open': interstitialMatchOpen.toMap(),
    'native_match_list': nativeMatchList.toMap(),
    'app_open_ad': appOpenAd.toMap(),
    'rewarded_ad': rewardedAd.toMap(),
  };
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'remote_config_service.dart';

/// Central Ad Service managing Google Mobile Ads lifecycle, frequency capping,
/// and real-time Firestore-controlled configuration.
class AdService {
  final Ref _ref;
  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpenAd = false;
  DateTime? _appPausedTime;

  AdService(this._ref);

  /// Initializes AdMob with test device configuration.
  ///
  /// NOTE ON TEST DEVICE IDS:
  /// Test device IDs ensure Google test ad inventory is always served during
  /// development and testing, preventing AdMob policy violations.
  /// Replace/remove test configuration before final production release.
  static Future<void> initTestDeviceConfig() async {
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: [
            // Standard Android emulator test device ID
            'EMULATOR',
          ],
        ),
      );
      debugPrint('[AdService] AdMob RequestConfiguration initialized with test devices.');
    } catch (e) {
      debugPrint('[AdService] Failed to set test device configuration: $e');
    }
  }

  /// Evaluates frequency cap and shows an Interstitial Ad when opening a match details screen.
  ///
  /// Frequency rule:
  /// - Reads local counter from SharedPreferences (`match_detail_open_count`).
  /// - Increments counter by 1.
  /// - If `counter % frequencyCap == 0`, loads and displays the Interstitial Ad.
  /// - If placement is disabled or fails to load, no-ops silently without blocking navigation.
  Future<void> handleMatchOpenInterstitial({bool isLiveMatch = false}) async {
    try {
      final config = _ref.read(currentAdConfigProvider).interstitialMatchOpen;
      if (!config.enabled || config.adUnitId.isEmpty) {
        debugPrint('[AdService] Interstitial match open disabled in AdConfig.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final currentCount = (prefs.getInt('match_detail_open_count') ?? 0) + 1;
      await prefs.setInt('match_detail_open_count', currentCount);

      debugPrint('[AdService] Match open count: $currentCount, Frequency Cap: ${config.frequencyCap}');

      if (currentCount % config.frequencyCap != 0) {
        debugPrint('[AdService] Interstitial skipped (frequency cap not reached).');
        return;
      }

      // Load and show interstitial
      InterstitialAd.load(
        adUnitId: config.adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('[AdService] Interstitial failed to show: $error');
                ad.dispose();
              },
            );
            ad.show();
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('[AdService] Interstitial failed to load (non-fatal): $error');
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdService] Non-fatal error handling match open interstitial: $e');
    }
  }

  /// Preloads and manages the App Open Ad.
  void loadAppOpenAd() {
    try {
      final config = _ref.read(currentAdConfigProvider).appOpenAd;
      if (!config.enabled || config.adUnitId.isEmpty) return;

      AppOpenAd.load(
        adUnitId: config.adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            debugPrint('[AdService] App Open Ad loaded successfully.');
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdService] App Open Ad failed to load: $error');
            _appOpenAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdService] Non-fatal: loadAppOpenAd skipped: $e');
    }
  }

  /// Shows the App Open Ad if loaded and enabled when the app resumes from background.
  void showAppOpenAdIfAvailable() {
    try {
      final config = _ref.read(currentAdConfigProvider).appOpenAd;
      if (!config.enabled || _appOpenAd == null || _isShowingAppOpenAd) {
        loadAppOpenAd();
        return;
      }

      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _isShowingAppOpenAd = true;
        },
        onAdDismissedFullScreenContent: (ad) {
          _isShowingAppOpenAd = false;
          ad.dispose();
          _appOpenAd = null;
          loadAppOpenAd(); // Preload next
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _isShowingAppOpenAd = false;
          ad.dispose();
          _appOpenAd = null;
          loadAppOpenAd();
        },
      );

      _appOpenAd!.show();
    } catch (e) {
      debugPrint('[AdService] Non-fatal: showAppOpenAdIfAvailable failed: $e');
    }
  }

  /// Records app background timestamp for resume detection.
  void onAppPaused() {
    _appPausedTime = DateTime.now();
  }

  /// Called on app resume from background.
  void onAppResumed() {
    // Only show if backgrounded for at least 4 seconds (avoids flashing on transient switches)
    if (_appPausedTime != null) {
      final elapsed = DateTime.now().difference(_appPausedTime!);
      if (elapsed.inSeconds >= 4) {
        showAppOpenAdIfAvailable();
      }
    }
    _appPausedTime = null;
  }

  /// Scaffolded method for Rewarded Ads (future features).
  void loadRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onAdFailed,
  }) {
    final config = _ref.read(currentAdConfigProvider).rewardedAd;
    if (!config.enabled || config.adUnitId.isEmpty) {
      debugPrint('[AdService] Rewarded ad placement is currently disabled.');
      onAdFailed?.call();
      return;
    }

    RewardedAd.load(
      adUnitId: config.adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show(onUserEarnedReward: (_, reward) {
            onUserEarnedReward(reward);
          });
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Rewarded ad failed to load: $error');
          onAdFailed?.call();
        },
      ),
    );
  }
}

/// Riverpod provider for [AdService].
final adServiceProvider = Provider<AdService>((ref) {
  return AdService(ref);
});

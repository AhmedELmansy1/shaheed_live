import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/services/remote_config_service.dart';

enum BannerPlacement { home, matchDetails }

/// A persistent Banner Ad widget that dynamically reacts to real-time Firestore AdConfig.
///
/// Features:
/// - Adaptive banner size matching current orientation width
/// - Safe-area padding to avoid system navigation overlap
/// - Collapses to [SizedBox.shrink()] on failure or when disabled without leaving empty space
/// - Race-free lifecycle: created once per (placement, adUnitId, width), null before dispose,
///   ignores callbacks after dispose, and avoids reloading when already loaded or loading.
/// - Debug counter log of ad requests per placement
class BannerAdWidget extends ConsumerStatefulWidget {
  final BannerPlacement placement;

  const BannerAdWidget({super.key, required this.placement});

  @visibleForTesting
  static final Map<BannerPlacement, int> requestCounters = {};

  @visibleForTesting
  static void resetCounters() => requestCounters.clear();

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _isDisposed = false;

  BannerPlacement? _activePlacement;
  String? _activeAdUnitId;
  int? _activeWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndLoadAd();
  }

  void _checkAndLoadAd() {
    if (_isDisposed) return;

    final adConfig = ref.read(currentAdConfigProvider);
    final placementConfig = widget.placement == BannerPlacement.home
        ? adConfig.bannerHome
        : adConfig.bannerMatchDetails;

    if (!placementConfig.enabled || placementConfig.adUnitId.isEmpty) {
      _disposeCurrentAd();
      return;
    }

    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0) return;

    // Avoid reloading when already loaded or actively loading for the same key
    if ((_isLoaded || _isLoading) &&
        _activePlacement == widget.placement &&
        _activeAdUnitId == placementConfig.adUnitId &&
        _activeWidth == width &&
        _bannerAd != null) {
      return;
    }

    _loadBanner(placementConfig.adUnitId, width);
  }

  Future<void> _loadBanner(String adUnitId, int width) async {
    if (_isDisposed) return;

    _disposeCurrentAd();
    _activePlacement = widget.placement;
    _activeAdUnitId = adUnitId;
    _activeWidth = width;
    _isLoading = true;

    // Debug counter log of ad requests per placement
    final count = (BannerAdWidget.requestCounters[widget.placement] ?? 0) + 1;
    BannerAdWidget.requestCounters[widget.placement] = count;
    if (kDebugMode) {
      debugPrint(
        '[BannerAdWidget] 📊 Ad request #$count for placement: ${widget.placement.name} '
        '(unitId: $adUnitId, width: $width)',
      );
    }

    // Determine adaptive banner size based on screen width
    AdSize adaptiveSize = AdSize.banner;
    try {
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (size != null) {
        adaptiveSize = size;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[BannerAdWidget] Failed to resolve adaptive size, using standard banner: $e',
        );
      }
    }

    // Guard against race conditions after async gap
    if (_isDisposed ||
        !mounted ||
        _activePlacement != widget.placement ||
        _activeAdUnitId != adUnitId ||
        _activeWidth != width) {
      _isLoading = false;
      return;
    }

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: adaptiveSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (_isDisposed || !mounted || _bannerAd != ad) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (ad, LoadAdError error) {
          if (_isDisposed || !mounted || _bannerAd != ad) {
            ad.dispose();
            return;
          }
          if (kDebugMode) {
            debugPrint(
              '[BannerAdWidget] ❌ Banner failed to load (${widget.placement.name}): '
              'code=${error.code}, message="${error.message}", domain="${error.domain}"',
            );
          }
          _disposeCurrentAd();
          if (mounted) setState(() {});
        },
      ),
    );

    _bannerAd = banner;
    await banner.load();
  }

  void _disposeCurrentAd() {
    final adToDispose = _bannerAd;
    _bannerAd = null;
    _isLoaded = false;
    _isLoading = false;
    adToDispose?.dispose();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeCurrentAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to config changes to reactively update/dispose
    final adConfig = ref.watch(currentAdConfigProvider);
    final placementConfig = widget.placement == BannerPlacement.home
        ? adConfig.bannerHome
        : adConfig.bannerMatchDetails;

    if (!placementConfig.enabled || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}

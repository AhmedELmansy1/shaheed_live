import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/services/remote_config_service.dart';

enum BannerPlacement { home, matchDetails }

/// A persistent Banner Ad widget that dynamically reacts to real-time Firestore AdConfig.
///
/// If disabled or fails to load, it collapses to [SizedBox.shrink()] without reserving empty space.
class BannerAdWidget extends ConsumerStatefulWidget {
  final BannerPlacement placement;

  const BannerAdWidget({super.key, required this.placement});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  String? _currentAdUnitId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndLoadAd();
  }

  void _checkAndLoadAd() {
    final adConfig = ref.watch(currentAdConfigProvider);
    final placementConfig = widget.placement == BannerPlacement.home
        ? adConfig.bannerHome
        : adConfig.bannerMatchDetails;

    if (!placementConfig.enabled || placementConfig.adUnitId.isEmpty) {
      _disposeAd();
      return;
    }

    if (_currentAdUnitId == placementConfig.adUnitId && _bannerAd != null) {
      return;
    }

    _loadBanner(placementConfig.adUnitId);
  }

  void _loadBanner(String adUnitId) {
    _disposeAd();
    _currentAdUnitId = adUnitId;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[BannerAdWidget] Banner failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
            });
          }
        },
      ),
    );

    _bannerAd!.load();
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adConfig = ref.watch(currentAdConfigProvider);
    final placementConfig = widget.placement == BannerPlacement.home
        ? adConfig.bannerHome
        : adConfig.bannerMatchDetails;

    // Reactively hide if disabled in real-time
    if (!placementConfig.enabled || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

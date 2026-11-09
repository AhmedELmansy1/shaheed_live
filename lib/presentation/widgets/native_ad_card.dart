import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/services/remote_config_service.dart';
import '../../core/theme/app_colors.dart';

/// A native ad card widget for match lists, styled to match the dark sports theme
/// with an "إعلان" (Ad) label for full policy transparency.
class NativeAdCard extends ConsumerStatefulWidget {
  const NativeAdCard({super.key});

  @override
  ConsumerState<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends ConsumerState<NativeAdCard> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  String? _loadedAdUnitId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndLoadAd();
  }

  void _checkAndLoadAd() {
    final adConfig = ref.watch(currentAdConfigProvider);
    final nativeConfig = adConfig.nativeMatchList;

    if (!nativeConfig.enabled || nativeConfig.adUnitId.isEmpty) {
      _disposeAd();
      return;
    }

    if (_loadedAdUnitId == nativeConfig.adUnitId && _nativeAd != null) {
      return;
    }

    _loadNativeAd(nativeConfig.adUnitId);
  }

  void _loadNativeAd(String adUnitId) {
    _disposeAd();
    _loadedAdUnitId = adUnitId;

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: AppColors.surface,
        cornerRadius: 12.0,
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textPrimary,
          backgroundColor: AppColors.surface,
          style: NativeTemplateFontStyle.bold,
          size: 13.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textSecondary,
          backgroundColor: AppColors.surface,
          style: NativeTemplateFontStyle.normal,
          size: 11.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          style: NativeTemplateFontStyle.bold,
          size: 11.0,
        ),
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: AppColors.primary,
          style: NativeTemplateFontStyle.bold,
          size: 12.0,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint(
              '[NativeAdCard] ❌ Native ad failed to load: '
              'code=${error.code}, message="${error.message}"',
            );
          }
          ad.dispose();
          if (mounted) {
            setState(() {
              _nativeAd = null;
              _isLoaded = false;
            });
          }
        },
      ),
    );

    _nativeAd!.load();
  }

  void _disposeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
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
    if (!adConfig.nativeMatchList.enabled || !_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compliance Ad Label Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'إعلان',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 90, child: AdWidget(ad: _nativeAd!)),
        ],
      ),
    );
  }
}

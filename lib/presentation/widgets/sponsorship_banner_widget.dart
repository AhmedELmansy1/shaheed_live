import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/sponsorship_service.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_extensions.dart';
import '../../data/models/sponsorship_model.dart';

/// Direct Sponsorship Banner displaying active campaigns with distinct branding.
class SponsorshipBannerWidget extends ConsumerStatefulWidget {
  final SponsorshipPlacement placement;
  final EdgeInsetsGeometry margin;

  const SponsorshipBannerWidget({
    super.key,
    required this.placement,
    this.margin = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    ),
  });

  @override
  ConsumerState<SponsorshipBannerWidget> createState() =>
      _SponsorshipBannerWidgetState();
}

class _SponsorshipBannerWidgetState
    extends ConsumerState<SponsorshipBannerWidget> {
  Timer? _impressionTimer;
  String? _activeCampaignId;

  @override
  void dispose() {
    _impressionTimer?.cancel();
    super.dispose();
  }

  void _scheduleImpression(String campaignId) {
    if (_activeCampaignId == campaignId) return;
    _activeCampaignId = campaignId;

    _impressionTimer?.cancel();
    // Verify 1 continuous second of presence before counting impression
    _impressionTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        ref.read(sponsorshipServiceProvider).recordImpression(campaignId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final campaign = ref.watch(sponsorshipByPlacementProvider(widget.placement));

    if (campaign == null || !campaign.isActive) {
      return const SizedBox.shrink();
    }

    _scheduleImpression(campaign.id);

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: context.border, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(sponsorshipServiceProvider).recordClickAndOpen(campaign);
          },
          child: Stack(
            children: [
              // Banner Image
              AspectRatio(
                aspectRatio: 16 / 5,
                child: CachedNetworkImage(
                  imageUrl: campaign.bannerUrl,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => Container(
                    color: context.surfaceElevated,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (ctx, url, error) => Container(
                    color: context.surfaceElevated,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Center(
                      child: Text(
                        campaign.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // "إعلان راعي" Distinct Badge (Top Right in RTL)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'إعلان راعي • ${campaign.sponsorName}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


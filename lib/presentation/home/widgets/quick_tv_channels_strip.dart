import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/tv_channel_model.dart';
import '../../../data/repositories/tv_channels_repository.dart';
import '../../match_details/screens/embed_player_screen.dart';
import '../../match_details/screens/hls_player_screen.dart';

/// Horizontal carousel displaying live TV channels on the Home screen.
class QuickTvChannelsStrip extends ConsumerWidget {
  const QuickTvChannelsStrip({super.key});

  Future<void> _launchExternalUrl(BuildContext context, String urlString) async {
    final uri = Uri.tryParse(urlString.trim());
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الرابط الخارجي.')),
        );
      }
    }
  }

  void _onChannelTap(BuildContext context, TvChannelModel channel) {
    HapticFeedback.lightImpact();

    if (channel.defaultStreamUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رابط البث لهذه القناة غير متوفر حالياً'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final effectiveType = channel.effectivePlayerType;

    if (effectiveType == TvPlayerType.embed) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EmbedPlayerScreen(
            streamUrl: channel.defaultStreamUrl,
            serverName: channel.name,
            matchTitle: 'بث مباشر — ${channel.name}',
            serverId: channel.id,
          ),
        ),
      );
    } else if (effectiveType == TvPlayerType.external) {
      _launchExternalUrl(context, channel.defaultStreamUrl);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HlsPlayerScreen(
            streamUrl: channel.defaultStreamUrl,
            serverName: channel.name,
            matchTitle: 'بث مباشر — ${channel.name}',
            serverId: channel.id,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(activeTvChannelsProvider);
    if (channels.isEmpty) return const SizedBox.shrink();

    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final primary = AppColors.primaryOf(context);
    final liveColor = AppColors.coralCrimson;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: liveColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'قنوات البث المباشر',
                    style: AppTypography.title(color: textPrimary).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/channels');
                },
                borderRadius: AppRadii.mdRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'عرض الكل',
                        style: AppTypography.caption(color: primary).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: primary,
                        size: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs + 2),

        // Horizontal Channels Strip
        SizedBox(
          height: 94,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: channels.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final channel = channels[index];
              return InkWell(
                onTap: () => _onChannelTap(context, channel),
                borderRadius: AppRadii.lgRadius,
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: AppRadii.lgRadius,
                    border: Border.all(color: border, width: 1.0),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          // Small Channel Logo
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: border.withValues(alpha: 0.5),
                                width: 1.0,
                              ),
                            ),
                            child: ClipOval(
                              child: channel.logoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: channel.logoUrl,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => Center(
                                        child: Text(
                                          channel.name.isNotEmpty
                                              ? channel.name.characters.first
                                              : 'ق',
                                          style: TextStyle(
                                            color: primary.withValues(alpha: 0.6),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Center(
                                        child: Text(
                                          channel.name.isNotEmpty
                                              ? channel.name.characters.first
                                              : 'ق',
                                          style: TextStyle(
                                            color: primary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        channel.name.isNotEmpty
                                            ? channel.name.characters.first
                                            : 'ق',
                                        style: TextStyle(
                                          color: primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          // Quality and Live Dot
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.15),
                                    borderRadius: AppRadii.smRadius,
                                  ),
                                  child: Text(
                                    channel.qualityBadge,
                                    style: AppTypography.caption(color: primary).copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  channel.defaultPlayerType.labelArabic,
                                  style: AppTypography.caption(color: textSecondary).copyWith(
                                    fontSize: 9,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        channel.name,
                        style: AppTypography.caption(color: textPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

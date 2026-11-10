import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/tv_channel_model.dart';
import '../../data/repositories/tv_channels_repository.dart';
import '../match_details/screens/embed_player_screen.dart';
import '../match_details/screens/hls_player_screen.dart';

/// Screen displaying the catalog of live sports TV channels managed via the dashboard.
class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, fhd, hd, hls, embed

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onChannelTap(TvChannelModel channel) {
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

    if (channel.defaultPlayerType == TvPlayerType.embed) {
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
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(tvChannelsStreamProvider);
    final allChannels = channelsAsync.value ?? TvChannelModel.defaultChannels;
    final activeChannels = allChannels.where((c) => c.isActive).toList();

    // Apply filtering
    final filteredChannels = activeChannels.where((c) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!c.name.toLowerCase().contains(query) &&
            !c.defaultQuality.toLowerCase().contains(query)) {
          return false;
        }
      }

      if (_selectedFilter == 'fhd' && c.defaultQuality.toLowerCase() != 'fhd') {
        return false;
      }
      if (_selectedFilter == 'hd' && c.defaultQuality.toLowerCase() != 'hd') {
        return false;
      }
      if (_selectedFilter == 'hls' && c.defaultPlayerType != TvPlayerType.hls) {
        return false;
      }
      if (_selectedFilter == 'embed' && c.defaultPlayerType != TvPlayerType.embed) {
        return false;
      }

      return true;
    }).toList();

    final bg = AppColors.backgroundOf(context);
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final primary = AppColors.primaryOf(context);
    final liveColor = AppColors.coralCrimson;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Live Badge Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs + 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary.withValues(alpha: 0.25),
                                primary.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: AppRadii.lgRadius,
                            border: Border.all(
                              color: primary.withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            Icons.live_tv_rounded,
                            color: primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'قنوات البث المباشر',
                                style: AppTypography.headline(color: textPrimary).copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'بث مباشر على مدار الساعة بأعلى جودة',
                                style: AppTypography.bodySmall(color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: liveColor.withValues(alpha: 0.15),
                            borderRadius: AppRadii.fullRadius,
                            border: Border.all(
                              color: liveColor.withValues(alpha: 0.4),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: liveColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${activeChannels.length} قنوات',
                                style: AppTypography.caption(color: liveColor).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Search input
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: AppRadii.lgRadius,
                        border: Border.all(color: border, width: 1.0),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        style: AppTypography.bodyMedium(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن قناة رياضية...',
                          hintStyle: AppTypography.bodyMedium(
                            color: textSecondary.withValues(alpha: 0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: textSecondary,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: textSecondary,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Filter chips row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'الكل (${activeChannels.length})'),
                          const SizedBox(width: AppSpacing.xs),
                          _buildFilterChip('fhd', 'جودة فائقة FHD'),
                          const SizedBox(width: AppSpacing.xs),
                          _buildFilterChip('hd', 'جودة عالية HD'),
                          const SizedBox(width: AppSpacing.xs),
                          _buildFilterChip('hls', 'بث HLS أصلي'),
                          const SizedBox(width: AppSpacing.xs),
                          _buildFilterChip('embed', 'مشغل الويب'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: filteredChannels.isEmpty
              ? _buildEmptyState(context)
              : _buildChannelsGrid(context, filteredChannels),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    final primary = AppColors.primaryOf(context);
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedFilter = key;
        });
      },
      borderRadius: AppRadii.fullRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.18) : surface,
          borderRadius: AppRadii.fullRadius,
          border: Border.all(
            color: isSelected ? primary : border,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption(
            color: isSelected ? primary : textSecondary,
          ).copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tv_off_rounded,
              size: 56,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد قنوات مطابقة',
              style: AppTypography.title(color: textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'جرّب البحث باسم آخر أو إزالة الفلاتر',
              style: AppTypography.bodySmall(color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelsGrid(BuildContext context, List<TvChannelModel> channels) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;
        final aspectRatio = constraints.maxWidth >= 600 ? 1.15 : 0.98;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: aspectRatio,
          ),
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            return _buildChannelCard(context, channel);
          },
        );
      },
    );
  }

  Widget _buildChannelCard(BuildContext context, TvChannelModel channel) {
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final primary = AppColors.primaryOf(context);
    final liveColor = AppColors.coralCrimson;

    return InkWell(
      onTap: () => _onChannelTap(channel),
      borderRadius: AppRadii.xlRadius,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadii.xlRadius,
          border: Border.all(
            color: border,
            width: 1.0,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.04),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top badges (Quality & Live Dot)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Live Dot + Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: liveColor.withValues(alpha: 0.15),
                    borderRadius: AppRadii.fullRadius,
                    border: Border.all(
                      color: liveColor.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: liveColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'مباشر',
                        style: AppTypography.caption(color: liveColor).copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Quality Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    borderRadius: AppRadii.smRadius,
                    border: Border.all(
                      color: primary.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    channel.qualityBadge,
                    style: AppTypography.caption(color: primary).copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Channel Logo
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(
                  color: border.withValues(alpha: 0.6),
                  width: 1.0,
                ),
              ),
              child: ClipOval(
                child: channel.logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: channel.logoUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => _buildChannelMonogram(channel),
                        errorWidget: (context, url, error) => _buildChannelMonogram(channel),
                      )
                    : _buildChannelMonogram(channel),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Channel Name
            Text(
              channel.name,
              style: AppTypography.bodyMedium(color: textPrimary).copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 2),

            // Player Type Subtitle
            Text(
              channel.defaultPlayerType.labelArabic,
              style: AppTypography.caption(color: textSecondary).copyWith(
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Watch Button Pill
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary,
                    primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: AppRadii.mdRadius,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'مشاهدة',
                    style: AppTypography.caption(color: Colors.white).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelMonogram(TvChannelModel channel) {
    final primary = AppColors.primaryOf(context);
    final initial = channel.name.isNotEmpty ? channel.name.characters.first : 'ق';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: primary,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );
  }
}

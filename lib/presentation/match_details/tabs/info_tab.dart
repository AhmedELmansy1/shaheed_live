import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/match_model.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/matches_skeleton.dart';
import '../providers/match_details_providers.dart';

/// Clean, editorial Match Information tab in "Paper × Ink × Vermilion".
///
/// Features:
/// - Tidy key-value rows with semantic icons.
/// - Gracefully hides empty/unannounced fields instead of showing "غير محدد".
/// - Crisp cards with 1px border and zero neon glow.
class InfoTab extends ConsumerWidget {
  final MatchModel match;

  const InfoTab({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(matchInfoProvider(match.id));

    return infoAsync.when(
      loading: () => const MatchesSkeleton(),
      error: (err, stack) => AppErrorState(
        title: 'تعذر تحميل معلومات المباراة',
        subtitle: 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.',
        onRetry: () => ref.invalidate(matchInfoProvider(match.id)),
      ),
      data: (info) {
        final textPrimary = AppColors.textPrimaryOf(context);

        // Collect available fields (filter out empty/null values)
        final stadium = (info?.stadium?.trim().isNotEmpty ?? false)
            ? info!.stadium!.trim()
            : null;

        final referee = (info?.refereeName?.trim().isNotEmpty ?? false)
            ? info!.refereeName!.trim()
            : null;

        final channel = (info?.channel?.trim().isNotEmpty ?? false)
            ? info!.channel!.trim()
            : null;

        final commentator = (info?.commentator?.trim().isNotEmpty ?? false)
            ? info!.commentator!.trim()
            : null;

        final round = (info?.round?.trim().isNotEmpty ?? false)
            ? info!.round!.trim()
            : null;

        final hasGeneralInfo = match.leagueName.isNotEmpty || round != null;
        final hasBroadcastInfo = channel != null || commentator != null;
        final hasVenueInfo = stadium != null || referee != null;

        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          children: [
            // 1. Championship & Stage Card
            if (hasGeneralInfo)
              _buildSectionCard(
                context,
                title: 'البطولة والمرحلة',
                icon: Icons.emoji_events_rounded,
                children: [
                  Row(
                    children: [
                      if (match.leagueLogo != null && match.leagueLogo!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: match.leagueLogo!,
                          width: 26,
                          height: 26,
                          memCacheWidth: 64,
                          memCacheHeight: 64,
                          maxWidthDiskCache: 96,
                          maxHeightDiskCache: 96,
                          errorWidget: (_, _, _) => const Icon(
                            Icons.emoji_events_rounded,
                            size: 20,
                            color: AppColors.gold,
                          ),
                        )
                      else
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 20,
                          color: AppColors.gold,
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          match.leagueName,
                          style: AppTypography.titleSmall(color: textPrimary).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (round != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow(
                      context,
                      label: 'المرحلة / الجولة',
                      value: DateFormatter.toArabicNumerals(round),
                      icon: Icons.flag_rounded,
                    ),
                  ],
                ],
              ),

            // 2. Schedule Card
            const SizedBox(height: AppSpacing.md),
            _buildSectionCard(
              context,
              title: 'توقيت وتاريخ المباراة',
              icon: Icons.access_time_rounded,
              children: [
                _buildInfoRow(
                  context,
                  label: 'التاريخ',
                  value: DateFormatter.toArabicNumerals(match.displayDate),
                  icon: Icons.calendar_today_rounded,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildInfoRow(
                  context,
                  label: 'وقت الانطلاق',
                  value: DateFormatter.toArabicNumerals(match.formattedLocalTime),
                  icon: Icons.schedule_rounded,
                ),
                if (match.statusName.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoRow(
                    context,
                    label: 'الحالة',
                    value: match.statusName,
                    icon: Icons.info_outline_rounded,
                  ),
                ],
              ],
            ),

            // 3. Broadcast Card (Only if channel or commentator exist)
            if (hasBroadcastInfo) ...[
              const SizedBox(height: AppSpacing.md),
              _buildSectionCard(
                context,
                title: 'البث والتعليق',
                icon: Icons.tv_rounded,
                children: [
                  if (channel != null)
                    _buildInfoRow(
                      context,
                      label: 'القناة الناقلة',
                      value: channel,
                      icon: Icons.live_tv_rounded,
                    ),
                  if (channel != null && commentator != null)
                    const SizedBox(height: AppSpacing.sm),
                  if (commentator != null)
                    _buildInfoRow(
                      context,
                      label: 'المعلق الصوتي',
                      value: commentator,
                      icon: Icons.record_voice_over_rounded,
                    ),
                ],
              ),
            ],

            // 4. Venue & Officials Card (Only if stadium or referee exist)
            if (hasVenueInfo) ...[
              const SizedBox(height: AppSpacing.md),
              _buildSectionCard(
                context,
                title: 'الملعب وطاقم التحكيم',
                icon: Icons.stadium_rounded,
                children: [
                  if (stadium != null)
                    _buildInfoRow(
                      context,
                      label: 'الملعب',
                      value: stadium,
                      icon: Icons.stadium_rounded,
                    ),
                  if (stadium != null && referee != null)
                    const SizedBox(height: AppSpacing.sm),
                  if (referee != null)
                    _buildInfoRow(
                      context,
                      label: 'حكم الساحة',
                      value: referee,
                      icon: Icons.sports_rounded,
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      },
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final primary = AppColors.primaryOf(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadii.lgRadius,
        border: Border.all(color: border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.titleSmall(color: textPrimary).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(color: border, height: 1.0),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Row(
      children: [
        Icon(icon, size: 15, color: textSecondary),
        const SizedBox(width: AppSpacing.xs + 2),
        Text(
          label,
          style: AppTypography.bodySmall(color: textSecondary).copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelLarge(color: textPrimary).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

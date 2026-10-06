import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';

/// Reusable Section Header for League groups with logo and match count badge.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? logoUrl;
  final int? count;
  final bool isFollowed;
  final VoidCallback? onTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.logoUrl,
    this.count,
    this.isFollowed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight(context);
    final surfaceHigh = isLight
        ? AppColors.lightSurfaceHigh
        : AppColors.darkSurfaceHigh;
    final border = isLight ? AppColors.lightBorder : AppColors.darkBorder;
    final textPrimary = isLight
        ? AppColors.lightTextPrimary
        : AppColors.darkTextPrimary;
    final textSecondary = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.smRadius,
        child: Row(
          children: [
            // League Logo / Emblem
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: surfaceHigh,
                borderRadius: AppRadii.xsRadius,
                border: Border.all(color: border, width: 1),
              ),
              padding: const EdgeInsets.all(3),
              child: logoUrl != null && logoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: logoUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) => const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.gold,
                        size: 16,
                      ),
                    )
                  : const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.gold,
                      size: 16,
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // League Title with optional Followed Star
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: AppTypography.titleMedium(color: textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isFollowed) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.gold,
                    ),
                  ],
                ],
              ),
            ),

            // Match count badge
            if (count != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isFollowed
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : surfaceHigh,
                  borderRadius: AppRadii.fullRadius,
                  border: Border.all(
                    color: isFollowed
                        ? AppColors.gold.withValues(alpha: 0.4)
                        : border,
                  ),
                ),
                child: Text(
                  '${DateFormatter.toArabicNumerals('$count')} مباريات',
                  style: AppTypography.caption(
                    color: isFollowed ? AppColors.gold : textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

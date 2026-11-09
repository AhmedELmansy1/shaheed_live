import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';

/// Editorial Section Header grouping fixtures by Competition / League.
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
    final surfaceElevated = AppColors.surfaceElevatedOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.smRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              // League Emblem
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: surfaceElevated,
                  borderRadius: AppRadii.xsRadius,
                  border: Border.all(color: border, width: 1.0),
                ),
                padding: const EdgeInsets.all(2.5),
                child: logoUrl != null && logoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: logoUrl!,
                        fit: BoxFit.contain,
                        memCacheWidth: 64,
                        memCacheHeight: 64,
                        maxWidthDiskCache: 128,
                        maxHeightDiskCache: 128,
                        errorWidget: (_, _, _) => const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.gold,
                          size: 15,
                        ),
                      )
                    : const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.gold,
                        size: 15,
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // League Title
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall(color: textPrimary)
                            .copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    if (isFollowed) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.gold,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),

              // Match Count Pill
              if (count != null && count! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceElevated,
                    borderRadius: AppRadii.fullRadius,
                    border: Border.all(color: border, width: 1.0),
                  ),
                  child: Text(
                    '${DateFormatter.toArabicNumerals(count.toString())} مباريات',
                    style: AppTypography.labelSmall(color: textSecondary)
                        .copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

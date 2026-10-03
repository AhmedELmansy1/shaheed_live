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
  final VoidCallback? onTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.logoUrl,
    this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
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
                color: AppColors.darkSurfaceHigh,
                borderRadius: AppRadii.xsRadius,
                border: Border.all(color: AppColors.darkBorder, width: 1),
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

            // League Title
            Expanded(
              child: Text(
                title,
                style: AppTypography.titleMedium(color: AppColors.darkTextPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Match count badge
            if (count != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceHigh,
                  borderRadius: AppRadii.fullRadius,
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Text(
                  '${DateFormatter.toArabicNumerals('$count')} مباريات',
                  style: AppTypography.caption(color: AppColors.darkTextSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

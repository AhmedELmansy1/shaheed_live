import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

/// Skeleton loader placeholder for loading matches list with stadium shimmer sweep.
class MatchesSkeleton extends StatelessWidget {
  const MatchesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.darkSurface,
      highlightColor: AppColors.darkSurfaceHigh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs + 2,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: AppRadii.lgRadius,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                // Home team placeholder
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.darkSurfaceHigh,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceHigh,
                      borderRadius: AppRadii.xsRadius,
                    ),
                  ),
                ),

                // Center score pill placeholder
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  width: 54,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceHigh,
                    borderRadius: AppRadii.mdRadius,
                  ),
                ),

                // Away team placeholder
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceHigh,
                      borderRadius: AppRadii.xsRadius,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.darkSurfaceHigh,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

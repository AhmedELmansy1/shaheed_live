import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

/// Editorial Skeleton Loader placeholder in "Paper × Ink × Vermilion".
class MatchesSkeleton extends StatelessWidget {
  final int count;

  const MatchesSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF171A21)
        : const Color(0xFFEFEBE2);
    final highlightColor = isDark
        ? const Color(0xFF222731)
        : const Color(0xFFFDFBF7);
    final borderColor = AppColors.borderOf(context);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs + 1,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: AppRadii.mdRadius,
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              children: [
                // Home team crest placeholder
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: highlightColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: AppRadii.xsRadius,
                    ),
                  ),
                ),

                // Center score pill placeholder
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  width: 44,
                  height: 22,
                  decoration: BoxDecoration(
                    color: highlightColor,
                    borderRadius: AppRadii.smRadius,
                  ),
                ),

                // Away team placeholder
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: AppRadii.xsRadius,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: highlightColor,
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

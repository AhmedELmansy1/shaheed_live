import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Clean, editorial Error State for the "Paper × Ink × Vermilion" design system.
class AppErrorState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onRetry;
  final String retryLabel;

  const AppErrorState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.error_outline_rounded,
    required this.onRetry,
    this.retryLabel = 'إعادة المحاولة',
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final surfaceElevated = AppColors.surfaceElevatedOf(context);
    final border = AppColors.borderOf(context);
    final vermilion = AppColors.primaryOf(context);

    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.huge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: 1.0),
              ),
              child: Icon(
                icon,
                size: 32,
                color: vermilion,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge(color: textPrimary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            // Subtitle
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(color: textSecondary),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),

            // Retry Button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onRetry();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: vermilion,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadii.fullRadius,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  retryLabel,
                  style: AppTypography.labelLarge(color: Colors.white).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


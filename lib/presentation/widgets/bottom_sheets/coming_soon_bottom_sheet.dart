import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../app_button.dart';

class ComingSoonBottomSheet extends StatelessWidget {
  const ComingSoonBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (context) => const ComingSoonBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: AppRadii.fullRadius,
                  ),
                ),
              ),

              const Icon(
                Icons.movie_creation_rounded,
                color: AppColors.primary,
                size: 56,
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'ملخص المباراة قريبًا',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge(color: textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),

              Text(
                'سنضيف ملخصات المباريات في تحديث قادم. ⚽',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(color: textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),

              AppButton(
                label: 'حسناً',
                variant: AppButtonVariant.primary,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

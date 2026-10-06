import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/developer_profile.dart';

class DeveloperHeader extends StatelessWidget {
  final DeveloperProfile profile;

  const DeveloperHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final isLight = AppColors.isLight(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isLight
              ? [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.accentCyan.withValues(alpha: 0.05),
                  AppColors.lightBackground,
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.accentCyan.withValues(alpha: 0.05),
                  AppColors.darkBackground,
                ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with subtle stadium/cyber glow and verified badge
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Outer ambient glow ring
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: isLight ? 0.25 : 0.4,
                      ),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: AppColors.accentCyan.withValues(
                        alpha: isLight ? 0.2 : 0.3,
                      ),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),

              // Gradient Border Ring
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(3.0),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceOf(context),
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.brandGradient.createShader(bounds),
                      child: Text(
                        'AE',
                        style:
                            AppTypography.displayScore(
                              color: Colors.white,
                              size: 34,
                            ).copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                      ),
                    ),
                  ),
                ),
              ),

              // Verified / Tech badge
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Name (Arabic + English)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.nameAr,
                  style: AppTypography.titleLarge(color: textPrimary)
                      .copyWith(fontWeight: FontWeight.w900, fontSize: 22),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text('•', style: TextStyle(color: textSecondary)),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  profile.nameEn,
                  style: AppTypography.titleMedium(color: textSecondary)
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Title / Role
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: AppRadii.fullRadius,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              profile.titleEn,
              style: AppTypography.caption(color: AppColors.primary)
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Status Badge: Available for projects
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary, blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  'متاح للعمل على المشاريع والحلول المخصصة',
                  style: AppTypography.caption(color: textSecondary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

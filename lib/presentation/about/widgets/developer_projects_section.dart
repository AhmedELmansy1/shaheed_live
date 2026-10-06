import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/developer_profile.dart';
import '../../widgets/app_card.dart';

class DeveloperProjectsSection extends StatelessWidget {
  final List<ProjectInfo> projects;

  const DeveloperProjectsSection({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أبرز المشاريع | Featured Projects',
                      style: AppTypography.titleMedium(color: textPrimary)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'نماذج من التطبيقات والأنظمة البرمجية المنجزة',
                      style: AppTypography.caption(color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: projects.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.xs),
          itemBuilder: (context, index) {
            final project = projects[index];
            final isHighlighted = project.highlighted;

            return AppCard(
              isFeatured: isHighlighted,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? AppColors.gold.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: isHighlighted
                                ? AppColors.gold.withValues(alpha: 0.4)
                                : AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          project.icon,
                          color: isHighlighted
                              ? AppColors.gold
                              : AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.titleAr,
                              style: AppTypography.titleSmall(
                                color: textPrimary,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isHighlighted
                                    ? AppColors.gold.withValues(alpha: 0.15)
                                    : AppColors.surfaceHighOf(context),
                                borderRadius: AppRadii.xsRadius,
                                border: Border.all(
                                  color: isHighlighted
                                      ? AppColors.gold.withValues(alpha: 0.4)
                                      : AppColors.borderOf(context),
                                ),
                              ),
                              child: Text(
                                project.categoryAr,
                                style: AppTypography.caption(
                                  color: isHighlighted
                                      ? AppColors.gold
                                      : textSecondary,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  Text(
                    project.descriptionAr,
                    style: AppTypography.bodyMedium(color: textSecondary)
                        .copyWith(height: 1.45),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: project.tags.map((tag) {
                          return Container(
                            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHighOf(context),
                              borderRadius: BorderRadius.circular(AppRadii.xs),
                              border: Border.all(
                                color: AppColors.borderOf(context),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                tag,
                                style: AppTypography.caption(
                                  color: textPrimary,
                                ).copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

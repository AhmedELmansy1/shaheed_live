import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/developer_profile.dart';
import '../../widgets/app_card.dart';

class DeveloperSkillsSection extends StatelessWidget {
  final List<SkillCategory> categories;

  const DeveloperSkillsSection({super.key, required this.categories});

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
                  color: AppColors.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.accentCyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المهارات والتخصصات | Skills & Expertise',
                      style: AppTypography.titleMedium(color: textPrimary)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'التقنيات والأدوات التي أعمل بها باحترافية',
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
          itemCount: categories.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.xs),
          itemBuilder: (context, index) {
            final category = categories[index];
            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: category.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Icon(
                          category.icon,
                          color: category.accentColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.categoryNameAr,
                              style: AppTypography.titleSmall(
                                color: textPrimary,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              category.categoryNameEn,
                              style: AppTypography.caption(
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: category.skills.map((skill) {
                          return Container(
                            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: category.accentColor.withValues(alpha: 0.08),
                              borderRadius: AppRadii.fullRadius,
                              border: Border.all(
                                color: category.accentColor.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: category.accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    skill,
                                    style: AppTypography.caption(color: textPrimary)
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
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

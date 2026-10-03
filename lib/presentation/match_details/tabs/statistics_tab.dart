import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../widgets/app_empty_state.dart';
import '../providers/match_details_providers.dart';

class StatisticsTab extends ConsumerWidget {
  final MatchDetailsParams params;

  const StatisticsTab({super.key, required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(matchStatisticsProvider(params));

    return statsAsync.when(
      data: (stats) {
        if (stats == null) {
          return const Center(
            child: AppEmptyState(
              type: EmptyStateType.soccer,
              title: 'لا تتوفر إحصائيات',
              subtitle: 'لم يتم رصد إحصائيات رقمية لهذه المباراة حالياً',
            ),
          );
        }

        final h = stats.homeStats;
        final a = stats.awayStats;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            120,
          ),
          children: [
            _buildStatBarRow('الاستحواذ', '${h.possession}%', '${a.possession}%', h.possession, a.possession),
            _buildStatBarRow('إجمالي التسديدات', '${h.totalShots}', '${a.totalShots}', h.totalShots, a.totalShots),
            _buildStatBarRow('تسديدات على المرمى', '${h.shotsOnGoal}', '${a.shotsOnGoal}', h.shotsOnGoal, a.shotsOnGoal),
            _buildStatBarRow('تسديدات خارج المرمى', '${h.shotsOffGoal}', '${a.shotsOffGoal}', h.shotsOffGoal, a.shotsOffGoal),
            _buildStatBarRow('الضربات الركنية', '${h.corners}', '${a.corners}', h.corners, a.corners),
            _buildStatBarRow('الأخطاء', '${h.fouls}', '${a.fouls}', h.fouls, a.fouls),
            _buildStatBarRow('البطاقات الصفراء', '${h.yellowCards}', '${a.yellowCards}', h.yellowCards, a.yellowCards),
            _buildStatBarRow('البطاقات الحمراء', '${h.redCards}', '${a.redCards}', h.redCards, a.redCards),
            _buildStatBarRow('التسلل', '${h.offsides}', '${a.offsides}', h.offsides, a.offsides),
            _buildStatBarRow('تصدّيات الحارس', '${h.saves}', '${a.saves}', h.saves, a.saves),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, stack) => Center(
        child: AppEmptyState(
          type: EmptyStateType.error,
          title: 'تعذر تحميل الإحصائيات',
          subtitle: '$err',
        ),
      ),
    );
  }

  Widget _buildStatBarRow(
    String title,
    String homeDisplay,
    String awayDisplay,
    int homeVal,
    int awayVal,
  ) {
    final total = homeVal + awayVal;
    final homeTargetRatio = total > 0 ? homeVal / total : 0.5;
    final awayTargetRatio = total > 0 ? awayVal / total : 0.5;

    final homeArabic = DateFormatter.toArabicNumerals(homeDisplay);
    final awayArabic = DateFormatter.toArabicNumerals(awayDisplay);

    final homeHigher = homeVal > awayVal;
    final awayHigher = awayVal > homeVal;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                homeArabic,
                style: AppTypography.displayScore(
                  color: homeHigher ? AppColors.primary : AppColors.darkTextPrimary,
                  size: 15,
                ),
              ),
              Text(
                title,
                style: AppTypography.bodySmall(
                  color: AppColors.darkTextSecondary,
                ),
              ),
              Text(
                awayArabic,
                style: AppTypography.displayScore(
                  color: awayHigher ? AppColors.primary : AppColors.darkTextPrimary,
                  size: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: AppMotion.standard,
            curve: AppMotion.decelerateCurve,
            builder: (context, factor, child) {
              final animatedHomeFlex = ((homeTargetRatio * factor) * 1000).round().clamp(1, 1000);
              final animatedAwayFlex = ((awayTargetRatio * factor) * 1000).round().clamp(1, 1000);

              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.full),
                child: Container(
                  height: 7,
                  color: AppColors.darkSurfaceHigh,
                  child: Row(
                    children: [
                      Expanded(
                        flex: animatedHomeFlex,
                        child: Container(
                          decoration: BoxDecoration(
                            color: homeHigher ? AppColors.primary : AppColors.darkBorder,
                            boxShadow: homeHigher
                                ? [
                                    const BoxShadow(
                                      color: AppColors.primaryGlow,
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: animatedAwayFlex,
                        child: Container(
                          decoration: BoxDecoration(
                            color: awayHigher ? AppColors.primary : AppColors.darkBorder,
                            boxShadow: awayHigher
                                ? [
                                    const BoxShadow(
                                      color: AppColors.primaryGlow,
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

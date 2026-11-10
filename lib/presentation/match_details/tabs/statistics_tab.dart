import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_number_format.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/matches_skeleton.dart';
import '../providers/match_details_providers.dart';

/// Clean, editorial Match Statistics tab in "Paper × Ink × Vermilion".
///
/// Features:
/// - Proportional two-sided comparison bars (Home vs Away).
/// - Tabular Arabic numerals with zero jitter.
/// - Smooth entrance animation respecting reduced-motion accessibility.
/// - Robust empty and error states.
class StatisticsTab extends ConsumerWidget {
  final MatchDetailsParams params;

  const StatisticsTab({super.key, required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(matchStatisticsProvider(params));

    return statsAsync.when(
      loading: () => const MatchesSkeleton(),
      error: (err, stack) => AppErrorState(
        title: 'تعذر تحميل إحصائيات المباراة',
        subtitle: 'يرجى التحقق من اتصالك بالإنترنت وإعادة المحاولة.',
        onRetry: () => ref.invalidate(matchStatisticsProvider(params)),
      ),
      data: (stats) {
        if (stats == null) {
          return const AppEmptyState(
            type: EmptyStateType.soccer,
            title: 'لا تتوفر إحصائيات لهذه المباراة حالياً',
            subtitle: 'سيتم تحديث الإحصائيات فور توفرها أثناء سير اللقاء.',
          );
        }

        final h = stats.homeStats;
        final a = stats.awayStats;

        // Check if all stats are zero
        final isAllZero = h.possession == 0 &&
            a.possession == 0 &&
            h.totalShots == 0 &&
            a.totalShots == 0 &&
            h.corners == 0 &&
            a.corners == 0;

        if (isAllZero) {
          return const AppEmptyState(
            type: EmptyStateType.soccer,
            title: 'لم تبدأ إحصائيات المباراة بعد',
            subtitle: 'سيتم رصد وتحديث أرقام اللقاء لحظة بلحظة بعد صافرة البداية.',
          );
        }

        final statRows = [
          _StatData('الاستحواذ', '${h.possession}%', '${a.possession}%', h.possession, a.possession),
          _StatData('إجمالي التسديدات', '${h.totalShots}', '${a.totalShots}', h.totalShots, a.totalShots),
          _StatData('تسديدات على المرمى', '${h.shotsOnGoal}', '${a.shotsOnGoal}', h.shotsOnGoal, a.shotsOnGoal),
          _StatData('تسديدات خارج المرمى', '${h.shotsOffGoal}', '${a.shotsOffGoal}', h.shotsOffGoal, a.shotsOffGoal),
          _StatData('الضربات الركنية', '${h.corners}', '${a.corners}', h.corners, a.corners),
          _StatData('الأخطاء المرتكبة', '${h.fouls}', '${a.fouls}', h.fouls, a.fouls),
          _StatData('البطاقات الصفراء', '${h.yellowCards}', '${a.yellowCards}', h.yellowCards, a.yellowCards),
          _StatData('البطاقات الحمراء', '${h.redCards}', '${a.redCards}', h.redCards, a.redCards),
          _StatData('حالات التسلل', '${h.offsides}', '${a.offsides}', h.offsides, a.offsides),
          _StatData('تصديات الحارس', '${h.saves}', '${a.saves}', h.saves, a.saves),
        ];

        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          itemCount: statRows.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final row = statRows[index];
            return _StatComparisonCard(data: row);
          },
        );
      },
    );
  }
}

class _StatData {
  final String label;
  final String homeDisplay;
  final String awayDisplay;
  final int homeValue;
  final int awayValue;

  const _StatData(
    this.label,
    this.homeDisplay,
    this.awayDisplay,
    this.homeValue,
    this.awayValue,
  );
}

class _StatComparisonCard extends StatelessWidget {
  final _StatData data;

  const _StatComparisonCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final vermilion = AppColors.primaryOf(context);
    final isReducedMotion = AppMotion.isReducedMotion(context);

    final total = data.homeValue + data.awayValue;
    final homeFraction = total > 0 ? (data.homeValue / total).clamp(0.05, 0.95) : 0.5;

    final isHomeHigher = data.homeValue > data.awayValue;
    final isAwayHigher = data.awayValue > data.homeValue;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadii.lgRadius,
        border: Border.all(color: border, width: 1.0),
      ),
      child: Column(
        children: [
          // Row: Home Value | Label | Away Value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home Value (Right side in RTL)
              Text(
                AppNumberFormat.formatStat(data.homeDisplay),
                style: AppTypography.scoreHeadline(
                  color: isHomeHigher ? vermilion : textPrimary,
                ).copyWith(
                  fontSize: 16,
                  fontWeight: isHomeHigher ? FontWeight.w800 : FontWeight.w600,
                ),
              ),

              // Metric Label
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    data.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge(color: textSecondary).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              // Away Value (Left side in RTL)
              Text(
                AppNumberFormat.formatStat(data.awayDisplay),
                style: AppTypography.scoreHeadline(
                  color: isAwayHigher ? vermilion : textPrimary,
                ).copyWith(
                  fontSize: 16,
                  fontWeight: isAwayHigher ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Two-Sided Proportional Bar
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: isReducedMotion ? 1.0 : 0.0, end: 1.0),
            duration: AppMotion.medium,
            curve: Curves.easeOutCubic,
            builder: (context, animProgress, child) {
              return ClipRRect(
                borderRadius: AppRadii.fullRadius,
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      // Home side fraction (Right in RTL)
                      Expanded(
                        flex: ((homeFraction * animProgress) * 100).round().clamp(1, 100),
                        child: Container(
                          color: isHomeHigher ? vermilion : textSecondary.withValues(alpha: 0.35),
                        ),
                      ),
                      const SizedBox(width: 2), // 2px center divider seam
                      // Away side fraction (Left in RTL)
                      Expanded(
                        flex: (((1.0 - homeFraction) * animProgress) * 100).round().clamp(1, 100),
                        child: Container(
                          color: isAwayHigher ? vermilion : textSecondary.withValues(alpha: 0.35),
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

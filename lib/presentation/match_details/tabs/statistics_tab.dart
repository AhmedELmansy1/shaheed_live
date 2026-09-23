import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
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
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'لا تتوفر إحصائيات لهذه المباراة حالياً',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final h = stats.homeStats;
        final a = stats.awayStats;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
        child: CircularProgressIndicator(color: AppColors.liveIndicator),
      ),
      error: (err, stack) => Center(
        child: Text(
          'خطأ في تحميل الإحصائيات: $err',
          style: const TextStyle(color: AppColors.livePulse),
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
    final homeRatio = total > 0 ? homeVal / total : 0.5;
    final awayRatio = total > 0 ? awayVal / total : 0.5;

    final homeArabic = DateFormatter.toArabicNumerals(homeDisplay);
    final awayArabic = DateFormatter.toArabicNumerals(awayDisplay);

    final homeHigher = homeVal > awayVal;
    final awayHigher = awayVal > homeVal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                homeArabic,
                style: TextStyle(
                  color: homeHigher ? AppColors.liveIndicator : AppColors.textPrimary,
                  fontWeight: homeHigher ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                awayArabic,
                style: TextStyle(
                  color: awayHigher ? AppColors.liveIndicator : AppColors.textPrimary,
                  fontWeight: awayHigher ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (homeRatio * 100).round(),
                    child: Container(
                      color: homeHigher ? AppColors.liveIndicator : AppColors.cardBorder,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (awayRatio * 100).round(),
                    child: Container(
                      color: awayHigher ? AppColors.liveIndicator : AppColors.cardBorder,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/match_info_model.dart';
import '../../../data/models/match_model.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/matches_skeleton.dart';
import '../../widgets/team_logo.dart';
import '../providers/match_details_providers.dart';

/// Clean, editorial Head-to-Head & Recent Form Tab (Paper × Ink × Vermilion).
class H2HTab extends ConsumerWidget {
  final MatchModel match;

  const H2HTab({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(matchInfoProvider(match.id));

    return infoAsync.when(
      loading: () => const MatchesSkeleton(),
      error: (err, stack) => AppErrorState(
        title: 'تعذر تحميل سجل المواجهات المباشرة',
        subtitle: 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.',
        onRetry: () => ref.invalidate(matchInfoProvider(match.id)),
      ),
      data: (info) {
        final textPrimary = AppColors.textPrimaryOf(context);
        final textSecondary = AppColors.textSecondaryOf(context);
        final border = AppColors.borderOf(context);

        final homeForm = info?.homeForm;
        final awayForm = info?.awayForm;

        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          children: [
            // 1. Head-to-Head Form Summary Card
            _buildFormSummaryCard(
              context,
              homeForm: homeForm,
              awayForm: awayForm,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              border: border,
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2. Home Team Recent 5 Matches
            _buildTeamFormDetailsCard(
              context,
              teamName: match.homeTeam.title,
              teamLogo: match.homeTeam.image,
              form: homeForm,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              border: border,
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Away Team Recent 5 Matches
            _buildTeamFormDetailsCard(
              context,
              teamName: match.awayTeam.title,
              teamLogo: match.awayTeam.image,
              form: awayForm,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              border: border,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      },
    );
  }

  Widget _buildFormSummaryCard(
    BuildContext context, {
    required TeamFormModel? homeForm,
    required TeamFormModel? awayForm,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final homeWins = homeForm?.wins ?? 0;
    final awayWins = awayForm?.wins ?? 0;
    final totalWins = homeWins + awayWins;
    final homeRatio = totalWins > 0 ? homeWins / totalWins : 0.5;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'مقارنة الأداء والنتائج الأخيرة',
                style: AppTypography.titleSmall(color: textPrimary).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Two teams headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  TeamLogo(
                    logoUrl: match.homeTeam.image,
                    teamName: match.homeTeam.title,
                    size: 26,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    match.homeTeam.title,
                    style: AppTypography.bodySmall(color: textPrimary).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    match.awayTeam.title,
                    style: AppTypography.bodySmall(color: textPrimary).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  TeamLogo(
                    logoUrl: match.awayTeam.image,
                    teamName: match.awayTeam.title,
                    size: 26,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Proportional Win Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: (homeRatio * 100).round().clamp(10, 90),
                  child: Container(
                    height: 8,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: ((1.0 - homeRatio) * 100).round().clamp(10, 90),
                  child: Container(
                    height: 8,
                    color: AppColors.secondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Stats counters: Wins / Draws / Losses
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatPill('فوز', homeWins, AppColors.success, textSecondary),
              _buildStatPill('تعادل', homeForm?.draws ?? 0, AppColors.gold, textSecondary),
              _buildStatPill('هزيمة', homeForm?.losses ?? 0, AppColors.live, textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, int value, Color color, Color textSecondary) {
    return Column(
      children: [
        Text(
          DateFormatter.toArabicNumerals(value.toString()),
          style: AppTypography.titleMedium(color: color).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption(color: textSecondary),
        ),
      ],
    );
  }

  Widget _buildTeamFormDetailsCard(
    BuildContext context, {
    required String teamName,
    required String? teamLogo,
    required TeamFormModel? form,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final recent = form?.recentMatches ?? [];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TeamLogo(logoUrl: teamLogo, teamName: teamName, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'آخر ٥ مباريات: $teamName',
                      style: AppTypography.bodyMedium(color: textPrimary).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'من اليمين: الأحدث للأقدم',
                      style: AppTypography.caption(color: textSecondary),
                    ),
                  ],
                ),
              ),
              // Pills Row
              if (recent.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: recent.map((m) => _buildOutcomeBadge(m.result)).toList(),
                ),
            ],
          ),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(color: border, height: 1),
            const SizedBox(height: AppSpacing.xs),
            ...recent.map((m) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    _buildOutcomeBadge(m.result),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        m.title,
                        style: AppTypography.bodySmall(color: textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'سجل المباريات الأخيرة قيد التحديث من مزود البيانات...',
                style: AppTypography.caption(color: textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOutcomeBadge(String result) {
    Color bg;
    String letter;

    switch (result) {
      case 'win':
        bg = AppColors.success;
        letter = 'ف';
        break;
      case 'lose':
        bg = AppColors.live;
        letter = 'خ';
        break;
      case 'draw':
      default:
        bg = AppColors.gold;
        letter = 'ت';
        break;
    }

    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: bg.withValues(alpha: 0.5), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: bg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}


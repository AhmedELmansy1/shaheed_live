import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_number_format.dart';
import '../../../data/models/standings_model.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/matches_skeleton.dart';
import '../providers/match_details_providers.dart';

/// Editorial Standings Tab in "Paper × Ink × Vermilion".
///
/// Features:
/// - Clean typography with tabular Arabic numerals.
/// - Highlighted qualification / relegation zones using subtle neutral / accent tones (NO green).
/// - Proper empty, error (with retry), and loading skeleton states.
class StandingsTab extends ConsumerWidget {
  final int matchId;
  final int? homeTeamId;
  final int? awayTeamId;

  const StandingsTab({
    super.key,
    required this.matchId,
    this.homeTeamId,
    this.awayTeamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(matchStandingsProvider(matchId));

    return standingsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: MatchesSkeleton(),
      ),
      error: (err, stack) => AppErrorState(
        title: 'تعذر تحميل جدول الترتيب',
        subtitle: 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.',
        onRetry: () => ref.invalidate(matchStandingsProvider(matchId)),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const AppEmptyState(
            type: EmptyStateType.soccer,
            title: 'لا يتوفر جدول ترتيب لهذه البطولة حالياً',
            subtitle: 'سيتم تحديث جدول الترتيب فور توفر البيانات الرسمية.',
          );
        }

        final surface = AppColors.surfaceOf(context);
        final border = AppColors.borderOf(context);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: AppRadii.lgRadius,
              border: Border.all(color: border, width: 1.0),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTableHeader(context),
                    Divider(color: border, height: 1.0),
                    ...rows.map((row) => _buildTableRow(context, row, rows.length)),
                    Divider(color: border, height: 1.0),
                    _buildTableLegend(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final textSecondary = AppColors.textSecondaryOf(context);
    final surfaceElevated = AppColors.surfaceElevatedOf(context);

    return Container(
      width: 480,
      color: surfaceElevated,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#',
              style: AppTypography.labelSmall(color: textSecondary).copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            flex: 4,
            child: Text(
              'الفريق',
              style: AppTypography.labelSmall(color: textSecondary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _buildColHeader(context, 'لعب'),
          _buildColHeader(context, 'ف'),
          _buildColHeader(context, 'ت'),
          _buildColHeader(context, 'خ'),
          _buildColHeader(context, '+/-'),
          _buildColHeader(context, 'نقاط', isBold: true),
        ],
      ),
    );
  }

  Widget _buildColHeader(BuildContext context, String text, {bool isBold = false}) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return SizedBox(
      width: 34,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.labelSmall(
          color: isBold ? textPrimary : textSecondary,
        ).copyWith(
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    StandingRowModel row,
    int totalRows,
  ) {
    final surface = AppColors.surfaceOf(context);
    final surfaceElevated = AppColors.surfaceElevatedOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final primary = AppColors.primaryOf(context);
    final border = AppColors.borderOf(context);

    final isMatchTeam = (homeTeamId != null && row.teamId == homeTeamId) ||
        (awayTeamId != null && row.teamId == awayTeamId);

    // Subtle qualification / relegation zone indicators (NO GREEN)
    Color? zoneColor;
    if (row.rank == 1) {
      // Champion: vermilion accent
      zoneColor = primary;
    } else if (row.rank <= 4) {
      // Top 4 / Continental: subtle refined slate/indigo
      zoneColor = Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF6C85F5)
          : const Color(0xFF3B5BDB);
    } else if (totalRows > 12 && row.rank > totalRows - 3) {
      // Relegation: subtle warm coral
      zoneColor = const Color(0xFFD9480F);
    }

    return Container(
      width: 480,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isMatchTeam
            ? primary.withValues(alpha: 0.08)
            : surface,
        border: isMatchTeam
            ? Border(
                right: BorderSide(color: primary, width: 3.0),
              )
            : null,
      ),
      child: Row(
        children: [
          // Rank + Zone Marker
          SizedBox(
            width: 32,
            child: Row(
              children: [
                if (zoneColor != null)
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: zoneColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  )
                else
                  const SizedBox(width: 3),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    AppNumberFormat.formatStanding('${row.rank}'),
                    style: AppTypography.labelMedium(
                      color: isMatchTeam ? primary : textSecondary,
                    ).copyWith(
                      fontWeight: isMatchTeam ? FontWeight.w800 : FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Team Crest + Name
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: border, width: 0.6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    row.teamName.isNotEmpty ? row.teamName[0] : '•',
                    style: AppTypography.labelSmall(color: textPrimary).copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    row.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(
                      color: isMatchTeam ? primary : textPrimary,
                    ).copyWith(
                      fontWeight: isMatchTeam ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Numeric Columns
          _buildStatCell(context, row.played, textSecondary),
          _buildStatCell(context, row.won, textSecondary),
          _buildStatCell(context, row.drawn, textSecondary),
          _buildStatCell(context, row.lost, textSecondary),
          _buildStatCell(context, row.goalDiff, textSecondary),
          _buildStatCell(
            context,
            row.points,
            isMatchTeam ? primary : textPrimary,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell(
    BuildContext context,
    int val,
    Color color, {
    bool isBold = false,
  }) {
    return SizedBox(
      width: 34,
      child: Text(
        AppNumberFormat.formatStanding(val),
        textAlign: TextAlign.center,
        style: AppTypography.labelMedium(color: color).copyWith(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTableLegend(BuildContext context) {
    final textSecondary = AppColors.textSecondaryOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        'المختصرات: لعب (عدد المباريات) • ف (فوز) • ت (تعادل) • خ (خسارة) • +/- (فارق الأهداف) • نقاط',
        style: AppTypography.caption(color: textSecondary).copyWith(
          fontSize: 10.5,
        ),
      ),
    );
  }
}

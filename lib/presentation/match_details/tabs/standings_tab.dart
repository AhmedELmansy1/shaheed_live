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
import '../../widgets/team_logo.dart';
import '../providers/match_details_providers.dart';

/// Broadcast Standings Tab in the "Dark Sports Broadcast" design system.
///
/// Features:
/// - Crisp typography with tabular Western numerals (0-9).
/// - Real team crest logos via TeamLogo component.
/// - Prominent tabular Points ('نقاط') and Goal Difference ('+/-') columns.
/// - Highlighted qualification / relegation zones (UCL Blue, UEL Cyan, UECL Gold, Relegation Crimson).
/// - Highlighted match teams with glowing row background & accent bar.
/// - Responsive mobile layout fitting all key columns without accidental horizontal scroll cuts.
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

        return LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth = constraints.maxWidth > 400 ? constraints.maxWidth : 390.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
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
                  child: SizedBox(
                    width: tableWidth,
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
      },
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final textSecondary = AppColors.textSecondaryOf(context);
    final surfaceElevated = AppColors.surfaceElevatedOf(context);

    return Container(
      color: surfaceElevated,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#',
              style: AppTypography.labelSmall(color: textSecondary).copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 5,
            child: Text(
              'الفريق',
              style: AppTypography.labelSmall(color: textSecondary).copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _buildColHeader(context, 'لعب', width: 26),
          _buildColHeader(context, 'ف', width: 22),
          _buildColHeader(context, 'ت', width: 22),
          _buildColHeader(context, 'خ', width: 22),
          _buildColHeader(context, '+/-', width: 28),
          _buildColHeader(context, 'نقاط', width: 34, isBold: true),
        ],
      ),
    );
  }

  Widget _buildColHeader(BuildContext context, String text, {required double width, bool isBold = false}) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.labelSmall(
          color: isBold ? textPrimary : textSecondary,
        ).copyWith(
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          fontSize: 11,
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
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final primary = AppColors.primaryOf(context);

    final isMatchTeam = (homeTeamId != null && row.teamId == homeTeamId) ||
        (awayTeamId != null && row.teamId == awayTeamId);

    // Broadcast Zone colors
    Color? zoneColor;
    if (row.rank >= 1 && row.rank <= 4) {
      // UEFA Champions League / Top 4: Electric Blue
      zoneColor = AppColors.electricBlue;
    } else if (row.rank == 5) {
      // UEFA Europa League: Electric Cyan
      zoneColor = AppColors.electricCyan;
    } else if (row.rank == 6) {
      // UEFA Conference League: Metallic Gold
      zoneColor = AppColors.metallicGold;
    } else if (totalRows > 10 && row.rank > totalRows - 3) {
      // Relegation: Coral Crimson
      zoneColor = AppColors.coralCrimson;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: AppSpacing.sm - 1,
      ),
      decoration: BoxDecoration(
        color: isMatchTeam
            ? primary.withValues(alpha: 0.12)
            : surface,
        border: isMatchTeam
            ? BorderDirectional(
                start: BorderSide(color: AppColors.electricCyan, width: 3.5),
              )
            : null,
      ),
      child: Row(
        children: [
          // Rank + Zone Marker
          SizedBox(
            width: 28,
            child: Row(
              children: [
                if (zoneColor != null)
                  Container(
                    width: 3.0,
                    height: 16,
                    decoration: BoxDecoration(
                      color: zoneColor,
                      borderRadius: BorderRadius.circular(1.5),
                      boxShadow: [
                        BoxShadow(
                          color: zoneColor.withValues(alpha: 0.5),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(width: 3.0),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    AppNumberFormat.formatStanding('${row.rank}'),
                    style: AppTypography.labelMedium(
                      color: isMatchTeam ? AppColors.electricCyan : textSecondary,
                    ).copyWith(
                      fontWeight: isMatchTeam ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Team Crest + Name
          Expanded(
            flex: 5,
            child: Row(
              children: [
                TeamLogo(
                  logoUrl: row.teamLogo,
                  teamName: row.teamName,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  child: Text(
                    row.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(
                      color: isMatchTeam ? AppColors.electricCyan : textPrimary,
                    ).copyWith(
                      fontWeight: isMatchTeam ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Numeric Columns
          _buildStatCell(context, row.played, textSecondary, width: 26),
          _buildStatCell(context, row.won, textSecondary, width: 22),
          _buildStatCell(context, row.drawn, textSecondary, width: 22),
          _buildStatCell(context, row.lost, textSecondary, width: 22),
          _buildStatCell(context, row.goalDiff, textSecondary, width: 28),
          _buildStatCell(
            context,
            row.points,
            isMatchTeam ? AppColors.electricCyan : primary,
            width: 34,
            isBold: true,
            isPill: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell(
    BuildContext context,
    int val,
    Color color, {
    required double width,
    bool isBold = false,
    bool isPill = false,
  }) {
    final text = Text(
      AppNumberFormat.formatStanding(val),
      textAlign: TextAlign.center,
      style: AppTypography.labelMedium(color: color).copyWith(
        fontSize: isBold ? 12.5 : 11.5,
        fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
      ),
    );

    if (isPill) {
      return SizedBox(
        width: width,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadii.smRadius,
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: text,
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: text,
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
        'المختصرات: لعب • ف (فوز) • ت (تعادل) • خ (خسارة) • +/- (فارق الأهداف) • نقاط',
        style: AppTypography.caption(color: textSecondary).copyWith(
          fontSize: 10.5,
        ),
      ),
    );
  }
}

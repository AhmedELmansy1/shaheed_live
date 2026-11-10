import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/ad_service.dart';
import '../../core/services/match_reminder_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/match_model.dart';
import 'bottom_sheets/watch_match_bottom_sheet.dart';
import 'score_view.dart';
import 'status_chip.dart';
import 'team_logo.dart';

/// Clean, editorial Match Card in the "Paper × Ink × Vermilion" design system.
///
/// Distinct visual states:
/// - **Live**: Crisp vermilion accent edge, tabular figures, pulsating live minute badge.
/// - **Upcoming**: Deep cobalt kickoff time, reminder notification bell with 48dp target.
/// - **Finished**: Restrained slate status, final scores.
/// - **RTL Correctness**: Directional layout (Home on right, Away on left).
class MatchCard extends ConsumerWidget {
  final MatchModel match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLive = match.isLive;
    final isFinished = match.isFinished;
    final isUpcoming = match.status == MatchStatus.notStarted && !isLive;

    final isReminderSet = isUpcoming
        ? ref.watch(isMatchReminderActiveProvider(match))
        : false;

    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = isLive
        ? AppColors.primaryOf(context).withValues(alpha: 0.6)
        : AppColors.borderOf(context);

    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Semantics(
      button: true,
      label: 'مباراة ${match.homeTeamName} ضد ${match.awayTeamName}. '
          '${isLive ? "مباشر" : (isFinished ? "انتهت النتيجة ${match.homeScore} إلى ${match.awayScore}" : "تبدأ الساعة ${match.formattedLocalTime}")}',
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs + 1,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: AppRadii.mdRadius,
          border: Border.all(
            color: borderColor,
            width: isLive ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (Theme.of(context).brightness == Brightness.light)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadii.mdRadius,
          child: InkWell(
            borderRadius: AppRadii.mdRadius,
            onTap: () {
              HapticFeedback.selectionClick();
              ref
                  .read(adServiceProvider)
                  .handleMatchOpenInterstitial(isLiveMatch: match.isLive);
              context.push('/match/${match.matchId}', extra: match);
            },
            child: Stack(
              children: [
                // Live Vermilion Accent Line on Leading Edge (RTL right)
                if (isLive)
                  PositionedDirectional(
                    top: 8,
                    bottom: 8,
                    start: 0,
                    child: Container(
                      width: 3.5,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOf(context),
                        borderRadius: const BorderRadiusDirectional.horizontal(
                          end: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sub-header: League info & Status pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // League Name & Round
                          Expanded(
                            child: Text(
                              match.leagueName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall(
                                color: textSecondary,
                              ).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLive) ...[
                                InkWell(
                                  borderRadius: AppRadii.smRadius,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    WatchMatchBottomSheet.show(
                                      context,
                                      matchId: match.matchId,
                                      match: match,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.vermilion.withValues(alpha: 0.15),
                                      borderRadius: AppRadii.smRadius,
                                      border: Border.all(
                                        color: AppColors.vermilion.withValues(alpha: 0.5),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.live_tv_rounded,
                                          size: 13,
                                          color: AppColors.vermilion,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'مشاهدة الآن 🔴',
                                          style: AppTypography.caption(
                                            color: AppColors.vermilion,
                                          ).copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              StatusChip(match: match, isCompact: true),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Match Teams & Score Center
                      Row(
                        children: [
                          // Home Team (Leading in RTL)
                          Expanded(
                            flex: 5,
                            child: Row(
                              children: [
                                TeamLogo(
                                  logoUrl: match.homeTeamLogo,
                                  teamName: match.homeTeamName,
                                  size: 38,
                                  heroTag: 'match_home_${match.matchId}',
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    match.homeTeamName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.titleSmall(
                                      color: isFinished
                                          ? textSecondary
                                          : textPrimary,
                                    ).copyWith(
                                      fontWeight: isLive
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Center Status / Score
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: _buildCenterScoreOrTime(
                              context,
                              ref,
                              isLive,
                              isFinished,
                              isUpcoming,
                              isReminderSet,
                            ),
                          ),

                          // Away Team (Trailing in RTL)
                          Expanded(
                            flex: 5,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    match.awayTeamName,
                                    textAlign: TextAlign.end,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.titleSmall(
                                      color: isFinished
                                          ? textSecondary
                                          : textPrimary,
                                    ).copyWith(
                                      fontWeight: isLive
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                TeamLogo(
                                  logoUrl: match.awayTeamLogo,
                                  teamName: match.awayTeamName,
                                  size: 38,
                                  heroTag: 'match_away_${match.matchId}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterScoreOrTime(
    BuildContext context,
    WidgetRef ref,
    bool isLive,
    bool isFinished,
    bool isUpcoming,
    bool isReminderSet,
  ) {
    // 1. Postponed or Cancelled: show status text with semantic label
    if (match.status == MatchStatus.postponed ||
        match.status == MatchStatus.cancelled) {
      final statusLabel =
          match.status == MatchStatus.postponed ? 'تأجلت' : 'ألغيت';
      return Semantics(
        label: 'حالة المباراة: $statusLabel',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.warningOf(context).withValues(alpha: 0.12),
            borderRadius: AppRadii.smRadius,
            border: Border.all(
              color: AppColors.warningOf(context).withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Text(
            statusLabel,
            style: AppTypography.caption(
              color: AppColors.warningOf(context),
            ).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    // 2. Live, Paused (half-time), or Finished: show ScoreView (real numbers or '—')
    if (isLive || isFinished || match.status == MatchStatus.paused) {
      return ScoreView(
        homeScore: match.homeScore,
        awayScore: match.awayScore,
        isLive: isLive,
        isFinished: isFinished,
        fontSize: 22.0,
      );
    }

    // 3. Upcoming / Not started: show kickoff time (never 0:0, never placeholder dots)
    final rawKickoff = match.formattedLocalTime.trim();
    final displayTime = (rawKickoff.isNotEmpty &&
            rawKickoff != '— : —' &&
            rawKickoff != '0:0' &&
            rawKickoff != '00:00:00' &&
            rawKickoff != '· : ·' &&
            rawKickoff != '٠ : ٠')
        ? rawKickoff
        : (match.matchTime != null &&
                match.matchTime!.isNotEmpty &&
                match.matchTime != '00:00:00'
            ? match.matchTime!.substring(0, 5)
            : '— : —');

    return Semantics(
      label: 'وقت انطلاق المباراة: $displayTime',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayTime,
            style: AppTypography.scoreMedium(
              color: AppColors.secondaryOf(context),
            ).copyWith(
              fontSize: 15.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            tooltip: isReminderSet ? 'إلغاء التذكير' : 'تفعيل التذكير بالمباراة',
            icon: Icon(
              isReminderSet
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: isReminderSet
                  ? AppColors.primaryOf(context)
                  : AppColors.textSecondaryOf(context),
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              await ref
                  .read(matchReminderServiceProvider)
                  .toggleReminder(match);
            },
          ),
        ],
      ),
    );
  }
}

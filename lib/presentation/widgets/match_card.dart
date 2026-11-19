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
import 'bottom_sheets/match_reminder_sheet.dart';
import 'bottom_sheets/watch_match_bottom_sheet.dart';
import 'score_view.dart';
import 'status_chip.dart';
import 'team_logo.dart';

/// Broadcast-strip Match Card in the "Dark Sports Broadcast" design system.
///
/// Distinct visual states:
/// - **Live**: Neon emerald glowing accent edge, tabular figures, pulsating minute badge.
/// - **Upcoming**: Crisp kickoff time pill, reminder notification bell with 44dp target.
/// - **Finished**: Restrained slate status, final scores.
/// - **RTL Correctness**: Directional layout (Home on right, Away on left).
class MatchCard extends ConsumerWidget {
  final MatchModel match;
  final bool showLeagueHeader;

  const MatchCard({
    super.key,
    required this.match,
    this.showLeagueHeader = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLive = match.isLive;
    final isFinished = match.isFinished;
    final isUpcoming = match.status == MatchStatus.notStarted && !isLive;

    final isReminderSet = isUpcoming
        ? ref.watch(isMatchReminderActiveProvider(match))
        : false;

    final surfaceColor = AppColors.surfaceOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isLive
        ? AppColors.liveOf(context).withValues(alpha: 0.5)
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
            if (isDark)
              BoxShadow(
                color: isLive
                    ? AppColors.liveOf(context).withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            else
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
                // Live Neon Emerald Accent Line on Leading Edge (RTL right)
                if (isLive)
                  PositionedDirectional(
                    top: 8,
                    bottom: 8,
                    start: 0,
                    child: Container(
                      width: 3.5,
                      decoration: BoxDecoration(
                        color: AppColors.liveOf(context),
                        borderRadius: const BorderRadiusDirectional.horizontal(
                          end: Radius.circular(3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.liveOf(context).withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md + 2,
                    AppSpacing.sm + 2,
                    AppSpacing.md + 2,
                    AppSpacing.sm + 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Optional Micro Header: Only when ungrouped or standalone
                      if (showLeagueHeader) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevatedOf(context),
                                borderRadius: AppRadii.fullRadius,
                                border: Border.all(
                                  color: AppColors.borderOf(context),
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                match.leagueName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption(
                                  color: textSecondary,
                                ).copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                            StatusChip(match: match, isCompact: true),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                      ],

                      // Top Row for Live/Watch match pill (when league header is not shown)
                      if (!showLeagueHeader && (isLive || match.adminTitle != null)) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.coralCrimson.withValues(alpha: 0.15),
                                    borderRadius: AppRadii.fullRadius,
                                    border: Border.all(
                                      color: AppColors.coralCrimson.withValues(alpha: 0.4),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.live_tv_rounded,
                                        size: 12,
                                        color: AppColors.coralCrimson,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'مشاهدة الآن',
                                        style: AppTypography.caption(
                                          color: AppColors.coralCrimson,
                                        ).copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else
                              const SizedBox.shrink(),
                            StatusChip(match: match, isCompact: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Main Broadcast Strip: Home Team | Center Score/Time Pill | Away Team
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
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Center Status / Score Pill
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
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
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      fontSize: 13,
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
            rawKickoff != '٠ : ٠' &&
            rawKickoff != '----')
        ? rawKickoff
        : (match.matchTime != null &&
                match.matchTime!.isNotEmpty &&
                match.matchTime != '00:00:00'
            ? match.matchTime!.substring(0, 5)
            : 'قريباً');

    final textPrimary = AppColors.textPrimaryOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingTime = match.remainingTimeUntilKickoff;

    return Semantics(
      label: 'وقت انطلاق المباراة: $displayTime. ${remainingTime.isNotEmpty ? remainingTime : ""}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedOf(context),
          borderRadius: AppRadii.mdRadius,
          border: Border.all(
            color: isDark ? const Color(0xFF243657) : AppColors.borderOf(context),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayTime,
                  style: AppTypography.scoreMedium(
                    color: textPrimary,
                  ).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 2),
                IconButton(
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: isReminderSet ? 'إلغاء التنبيه' : 'تفعيل تنبيه المباراة',
                  icon: Icon(
                    isReminderSet
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: isReminderSet
                        ? AppColors.electricCyan
                        : AppColors.textSecondaryOf(context),
                  ),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    if (isReminderSet) {
                      await ref.read(matchReminderServiceProvider).toggleReminder(match);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم إلغاء التنبيه للمباراة'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } else {
                      MatchReminderSheet.show(context, match: match);
                    }
                  },
                ),
              ],
            ),
            if (remainingTime.isNotEmpty) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.primaryOf(context).withValues(alpha: 0.12),
                  borderRadius: AppRadii.fullRadius,
                  border: Border.all(
                    color: AppColors.primaryOf(context).withValues(alpha: 0.25),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  remainingTime,
                  style: AppTypography.caption(
                    color: AppColors.primaryOf(context),
                  ).copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

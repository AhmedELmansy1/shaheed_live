import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/match_reminder_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/match_model.dart';
import 'app_card.dart';
import 'live_badge.dart';
import 'match_countdown_widget.dart';
import 'score_text.dart';
import 'team_logo.dart';

/// Premium interactive match card with 40px circular crests, bold high-contrast score/status, and reminder toggle.
class MatchCard extends ConsumerWidget {
  final MatchModel match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLive = match.isLive;
    final isReminderSet = ref.watch(isReminderSetProvider(match.matchId));

    return AppCard(
      isLive: isLive,
      isFeatured: false,
      onTap: () {
        ref.read(adServiceProvider).handleMatchOpenInterstitial(isLiveMatch: match.isLive);
        context.push('/match/${match.matchId}', extra: match);
      },
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Home Team (Right side in RTL)
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    TeamLogo(
                      logoUrl: match.homeTeam.image,
                      teamName: match.homeTeam.title,
                      size: 40,
                      heroTag: 'match_home_${match.matchId}',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        match.homeTeam.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: match.isFinished
                              ? AppColors.darkTextSecondary
                              : AppColors.darkTextPrimary,
                          letterSpacing: 0.0,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Match Center: Status / Live Badge / Score
              Expanded(
                flex: 3,
                child: _buildCenterStatus(context),
              ),

              // Away Team (Left side in RTL)
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        match.awayTeam.title,
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: match.isFinished
                              ? AppColors.darkTextSecondary
                              : AppColors.darkTextPrimary,
                          letterSpacing: 0.0,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    TeamLogo(
                      logoUrl: match.awayTeam.image,
                      teamName: match.awayTeam.title,
                      size: 40,
                      heroTag: 'match_away_${match.matchId}',
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bell Reminder Toggle Pill (For upcoming matches)
          if (!isLive && !match.isFinished) ...[
            const SizedBox(height: AppSpacing.xs + 2),
            Center(
              child: InkWell(
                borderRadius: AppRadii.fullRadius,
                onTap: () {
                  HapticFeedback.lightImpact();
                  debugPrint('[MatchCard] Tapping bell reminder for match #${match.matchId}');
                  ref.read(matchReminderServiceProvider).toggleReminder(match);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                  decoration: BoxDecoration(
                    color: isReminderSet
                        ? AppColors.primary.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: AppRadii.fullRadius,
                    border: Border.all(
                      color: isReminderSet
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.darkBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isReminderSet
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        size: 13,
                        color: isReminderSet ? AppColors.primary : AppColors.darkTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isReminderSet ? 'تم تفعيل التذكير' : 'تذكير قبل الماتش',
                        style: GoogleFonts.cairo(
                          color: isReminderSet ? AppColors.primary : AppColors.darkTextMuted,
                          fontSize: 10.5,
                          fontWeight: isReminderSet ? FontWeight.bold : FontWeight.w600,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCenterStatus(BuildContext context) {
    if (match.isLive) {
      final minute = match.currentMinute;
      final showMinutePill = minute != null && minute.isNotEmpty && minute != 'مباشر';

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LiveBadge(),
              if (showMinutePill) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.live.withValues(alpha: 0.15),
                    borderRadius: AppRadii.fullRadius,
                    border: Border.all(
                      color: AppColors.live.withValues(alpha: 0.6),
                      width: 0.9,
                    ),
                  ),
                  child: Text(
                    minute,
                    style: GoogleFonts.cairo(
                      color: AppColors.live,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.0,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          ScoreText(
            homeScore: match.homeScore,
            awayScore: match.awayScore,
            isLive: true,
            fontSize: 24,
          ),
        ],
      );
    }

    if (match.status == MatchStatus.finished) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScoreText(
            homeScore: match.homeScore,
            awayScore: match.awayScore,
            isLive: false,
            fontSize: 22,
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceHigh,
              borderRadius: AppRadii.fullRadius,
              border: Border.all(color: AppColors.darkBorder, width: 0.8),
            ),
            child: Text(
              match.adminTitle ?? 'انتهت',
              style: GoogleFonts.cairo(
                color: AppColors.darkTextMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.0,
              ),
            ),
          ),
        ],
      );
    }

    if (match.status == MatchStatus.postponed || match.status == MatchStatus.cancelled) {
      final isPostponed = match.status == MatchStatus.postponed;
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceHigh,
            borderRadius: AppRadii.smRadius,
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Text(
            match.adminTitle ?? (isPostponed ? 'تأجلت' : 'ملغاة'),
            style: GoogleFonts.cairo(
              color: isPostponed ? AppColors.gold : AppColors.live,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.0,
            ),
          ),
        ),
      );
    }

    // Upcoming Match: Kickoff Time + Live Countdown Timer
    final timeFormatted = DateFormatter.formatMatchTime(match.matchDate, match.matchTime);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceHigh,
            borderRadius: AppRadii.smRadius,
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Text(
            timeFormatted,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: AppColors.darkTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.0,
            ),
          ),
        ),
        const SizedBox(height: 3),
        MatchCountdownWidget(
          targetDateTime: match.kickoffDateTime,
          fallbackFormattedTime: timeFormatted,
        ),
      ],
    );
  }
}

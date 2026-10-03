import 'package:cached_network_image/cached_network_image.dart';
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
import '../../data/models/match_model.dart';
import 'app_card.dart';
import 'live_badge.dart';
import 'match_countdown_widget.dart';
import 'score_text.dart';
import 'team_logo.dart';

/// Featured Hero Match Card with 60px circular crests, prominent scores/kickoff time, and zero glow for non-live matches.
class HeroMatchCard extends ConsumerWidget {
  final MatchModel match;

  const HeroMatchCard({
    super.key,
    required this.match,
  });

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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Header: League Logo & Name + Optional Bell
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (match.leagueLogo != null && match.leagueLogo!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: match.leagueLogo!,
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.emoji_events_rounded,
                        size: 18,
                        color: AppColors.gold,
                      ),
                    )
                  else
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 18,
                      color: AppColors.gold,
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    match.leagueName,
                    style: GoogleFonts.cairo(
                      color: isLive ? AppColors.darkTextPrimary : AppColors.darkTextSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
              ),
              if (!isLive && !match.isFinished)
                IconButton(
                  icon: Icon(
                    isReminderSet
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: isReminderSet ? AppColors.primary : AppColors.darkTextMuted,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(matchReminderServiceProvider).toggleReminder(match);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md + 4),

          // Main Center Stage: Home Team | Scores/Status | Away Team
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Home Team (Right side in RTL)
              Expanded(
                child: Column(
                  children: [
                    TeamLogo(
                      logoUrl: match.homeTeamLogo,
                      teamName: match.homeTeamName,
                      size: 60,
                      heroTag: 'hero_home_${match.matchId}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      match.homeTeamName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextPrimary,
                        letterSpacing: 0.0,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Center Score / Status / Live Minute
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const LiveBadge(isLarge: true),
                          if (match.currentMinute != null &&
                              match.currentMinute!.isNotEmpty &&
                              match.currentMinute != 'مباشر') ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppColors.live.withValues(alpha: 0.15),
                                borderRadius: AppRadii.fullRadius,
                                border: Border.all(
                                  color: AppColors.live.withValues(alpha: 0.6),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                match.currentMinute!,
                                style: GoogleFonts.cairo(
                                  color: AppColors.live,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.0,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ScoreText(
                        homeScore: match.homeScore,
                        awayScore: match.awayScore,
                        isLive: true,
                        fontSize: 30,
                      ),
                    ] else if (match.isFinished) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurfaceHigh,
                          borderRadius: AppRadii.fullRadius,
                          border: Border.all(color: AppColors.darkBorder, width: 0.8),
                        ),
                        child: Text(
                          match.adminTitle ?? 'انتهت',
                          style: GoogleFonts.cairo(
                            color: AppColors.darkTextMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ScoreText(
                        homeScore: match.homeScore,
                        awayScore: match.awayScore,
                        isLive: false,
                        fontSize: 28,
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurfaceHigh,
                          borderRadius: AppRadii.mdRadius,
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Text(
                          match.formattedLocalTime,
                          style: GoogleFonts.cairo(
                            color: AppColors.darkTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      MatchCountdownWidget(
                        targetDateTime: match.kickoffDateTime,
                        fallbackFormattedTime: match.formattedLocalTime,
                        isHero: true,
                      ),
                    ],
                  ],
                ),
              ),

              // Away Team (Left side in RTL)
              Expanded(
                child: Column(
                  children: [
                    TeamLogo(
                      logoUrl: match.awayTeamLogo,
                      teamName: match.awayTeamName,
                      size: 60,
                      heroTag: 'hero_away_${match.matchId}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      match.awayTeamName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextPrimary,
                        letterSpacing: 0.0,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_constants.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/match_reminder_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/match_model.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'bottom_sheets/watch_match_bottom_sheet.dart';
import 'live_badge.dart';
import 'match_countdown_widget.dart';
import 'score_text.dart';
import 'team_logo.dart';

/// Lightweight Featured Hero Match Card in the "Paper × Ink × Vermilion" design system.
///
/// Features:
/// - Prominent 56px team crests with crisp alignment.
/// - Tabular scores/kickoff time with zero decorative clutter or neon glow.
/// - Tactile card boundary with subtle 1px border.
/// - Fully responsive down to 360dp with text scaling up to 1.3x.
class HeroMatchCard extends ConsumerWidget {
  final MatchModel match;

  const HeroMatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLive = match.isLive;
    final isReminderSet = ref.watch(isMatchReminderActiveProvider(match));
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final border = AppColors.borderOf(context);
    final surfaceElevated = AppColors.surfaceElevatedOf(context);
    final finishedText = AppColors.finishedTextOf(context);

    return AppCard(
      isLive: isLive,
      isFeatured: !isLive,
      onTap: () {
        ref
            .read(adServiceProvider)
            .handleMatchOpenInterstitial(isLiveMatch: match.isLive);
        context.push('/match/${match.matchId}', extra: match);
      },
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        children: [
          // Header: League Logo & Name + Optional Bell
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (match.leagueLogo != null && match.leagueLogo!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: match.leagueLogo!,
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        memCacheWidth: 48,
                        memCacheHeight: 48,
                        maxWidthDiskCache: 96,
                        maxHeightDiskCache: 96,
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
                    Flexible(
                      child: Text(
                        match.leagueName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge(
                          color: isLive ? textPrimary : textSecondary,
                        ).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLive && !match.isFinished)
                Semantics(
                  button: true,
                  label: isReminderSet ? 'إلغاء التنبيه' : 'تفعيل التنبيه للمباراة',
                  child: IconButton(
                    icon: Icon(
                      isReminderSet
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: isReminderSet ? AppColors.primaryOf(context) : textMuted,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(matchReminderServiceProvider)
                          .toggleReminder(match);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Main Center Stage: Home Team | Scores/Status | Away Team
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Home Team (Right side in RTL)
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    TeamLogo(
                      logoUrl: match.homeTeamLogo,
                      teamName: match.homeTeamName,
                      size: 56,
                      heroTag: 'hero_home_${match.matchId}',
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      match.homeTeamName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall(color: textPrimary).copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Center Score / Status / Live Minute
              Expanded(
                flex: 5,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLive) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LiveBadge(
                                minuteText: match.currentMinute,
                                isLarge: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ScoreText(
                            homeScore: match.homeScore,
                            awayScore: match.awayScore,
                            isLive: true,
                            fontSize: 28,
                          ),
                        ] else if (match.isFinished) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: finishedText.withValues(alpha: 0.08),
                              borderRadius: AppRadii.fullRadius,
                              border: Border.all(
                                color: finishedText.withValues(alpha: 0.25),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              match.adminTitle ?? 'انتهت',
                              style: AppTypography.labelSmall(
                                color: finishedText,
                              ).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ScoreText(
                            homeScore: match.homeScore,
                            awayScore: match.awayScore,
                            isLive: false,
                            fontSize: 26,
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceElevated,
                              borderRadius: AppRadii.mdRadius,
                              border: Border.all(color: border),
                            ),
                            child: Text(
                              match.formattedLocalTime,
                              style: AppTypography.labelLarge(
                                color: textPrimary,
                              ).copyWith(
                                fontWeight: FontWeight.w800,
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
                ),
              ),

              // Away Team (Left side in RTL)
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    TeamLogo(
                      logoUrl: match.awayTeamLogo,
                      teamName: match.awayTeamName,
                      size: 56,
                      heroTag: 'hero_away_${match.matchId}',
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      match.awayTeamName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall(color: textPrimary).copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Action Buttons: Details & Live Stream
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'تفاصيل المباراة',
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/match/${match.matchId}');
                  },
                ),
              ),
              if (AppConstants.enableStreaming) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'شاهد المباراة الآن ⚽',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      WatchMatchBottomSheet.show(
                        context,
                        matchId: match.matchId,
                        match: match,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

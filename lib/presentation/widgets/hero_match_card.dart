import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_constants.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/match_reminder_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/match_model.dart';
import 'app_button.dart';
import 'bottom_sheets/watch_match_bottom_sheet.dart';
import 'live_badge.dart';
import 'match_countdown_widget.dart';
import 'score_text.dart';
import 'team_logo.dart';

/// High-craft Featured Hero Match Card in the "Dark Sports Broadcast" design system.
///
/// Features:
/// - True stadium/spotlight atmosphere with rich diagonal lighting & ambient logo glow.
/// - Prominent 58-60px team crests seated in glowing circular pedestals.
/// - Dramatic tabular scores/kickoff time with broadcast hierarchy.
/// - Electric blue-to-cyan gradient primary CTA button with glow shadow.
/// - Sleek glassmorphic secondary details button.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: 'المباراة المميزة: ${match.homeTeamName} ضد ${match.awayTeamName}. '
          '${isLive ? "مباشر الآن" : (match.isFinished ? "انتهت" : "تبدأ ${match.formattedLocalTime}")}',
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: AppDecorations.heroStadiumCard(
          context: context,
          isLive: isLive,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadii.lgRadius,
          child: InkWell(
            borderRadius: AppRadii.lgRadius,
            onTap: () {
              ref
                  .read(adServiceProvider)
                  .handleMatchOpenInterstitial(isLiveMatch: match.isLive);
              context.push('/match/${match.matchId}', extra: match);
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md + 4),
              child: Column(
                children: [
                  // Top Header: Featured Badge + League Name + Optional Reminder Bell
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Featured Pill + League
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0x26FFB300)
                                    : const Color(0x1AF59E0B),
                                borderRadius: AppRadii.fullRadius,
                                border: Border.all(
                                  color: AppColors.metallicGold.withValues(alpha: 0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 13,
                                    color: AppColors.metallicGold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'قمة الجولة',
                                    style: AppTypography.caption(
                                      color: AppColors.metallicGold,
                                    ).copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            if (match.leagueLogo != null && match.leagueLogo!.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: match.leagueLogo!,
                                width: 18,
                                height: 18,
                                fit: BoxFit.contain,
                                memCacheWidth: 48,
                                memCacheHeight: 48,
                                maxWidthDiskCache: 96,
                                maxHeightDiskCache: 96,
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.emoji_events_rounded,
                                  size: 16,
                                  color: AppColors.metallicGold,
                                ),
                              ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                match.leagueName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMedium(
                                  color: textSecondary,
                                ).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Notification Bell (for upcoming matches)
                      if (!isLive && !match.isFinished)
                        Semantics(
                          button: true,
                          label: isReminderSet ? 'إلغاء التنبيه' : 'تفعيل التنبيه للمباراة',
                          child: IconButton(
                            icon: Icon(
                              isReminderSet
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_none_rounded,
                              color: isReminderSet ? AppColors.electricCyan : textMuted,
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
                  const SizedBox(height: AppSpacing.md + 2),

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
                            _buildTeamPedestal(
                              context,
                              logoUrl: match.homeTeamLogo,
                              teamName: match.homeTeamName,
                              heroTag: 'hero_home_${match.matchId}',
                              isLive: isLive,
                              isHome: true,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              match.homeTeamName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleSmall(color: textPrimary).copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                fontSize: 13.5,
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
                                  const SizedBox(height: AppSpacing.xs + 2),
                                  ScoreText(
                                    homeScore: match.homeScore,
                                    awayScore: match.awayScore,
                                    isLive: true,
                                    fontSize: 32,
                                  ),
                                ] else if (match.isFinished) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: finishedText.withValues(alpha: 0.12),
                                      borderRadius: AppRadii.fullRadius,
                                      border: Border.all(
                                        color: finishedText.withValues(alpha: 0.3),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      match.adminTitle ?? 'انتهت',
                                      style: AppTypography.labelSmall(
                                        color: finishedText,
                                      ).copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs + 2),
                                  ScoreText(
                                    homeScore: match.homeScore,
                                    awayScore: match.awayScore,
                                    isLive: false,
                                    fontSize: 30,
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: surfaceElevated,
                                      borderRadius: AppRadii.fullRadius,
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF2C3E63) : border,
                                      ),
                                    ),
                                    child: Text(
                                      (match.formattedLocalTime.isNotEmpty &&
                                              match.formattedLocalTime != '----')
                                          ? match.formattedLocalTime
                                          : 'قريباً',
                                      style: AppTypography.labelLarge(
                                        color: textPrimary,
                                      ).copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs + 2),
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
                            _buildTeamPedestal(
                              context,
                              logoUrl: match.awayTeamLogo,
                              teamName: match.awayTeamName,
                              heroTag: 'hero_away_${match.matchId}',
                              isLive: isLive,
                              isHome: false,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              match.awayTeamName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleSmall(color: textPrimary).copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Action Buttons: Details & Live Stream
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      if (AppConstants.enableStreaming) ...[
                        Expanded(
                          child: AppButton(
                            label: match.isLive ? 'مشاهدة الآن 🔴' : 'مشاهدة المباراة ⚽',
                            variant: AppButtonVariant.primary,
                            gradient: AppColors.electricCtaGradient,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x402979FF),
                                blurRadius: 14,
                                offset: Offset(0, 4),
                              ),
                            ],
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
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: AppButton(
                          label: 'تفاصيل المباراة',
                          variant: AppButtonVariant.secondary,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.push('/match/${match.matchId}');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamPedestal(
    BuildContext context, {
    required String? logoUrl,
    required String teamName,
    required String heroTag,
    required bool isLive,
    required bool isHome,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isLive
        ? AppColors.neonEmerald
        : (isHome ? AppColors.electricCyan : AppColors.coralCrimson);

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0x1F142344) : const Color(0x08000000),
        border: Border.all(
          color: isDark ? accent.withValues(alpha: 0.25) : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          if (isDark)
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: 1,
            ),
        ],
      ),
      alignment: Alignment.center,
      child: TeamLogo(
        logoUrl: logoUrl,
        teamName: teamName,
        size: 56,
        heroTag: heroTag,
      ),
    );
  }
}

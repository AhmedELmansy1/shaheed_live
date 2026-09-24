import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/match_reminder_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/match_model.dart';

class HeroMatchCard extends ConsumerWidget {
  final MatchModel match;

  const HeroMatchCard({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLive = match.isLive;
    final isReminderSetAsync = ref.watch(isReminderSetProvider(match.matchId));
    final isReminderSet = isReminderSetAsync.value ?? false;

    return GestureDetector(
      onTap: () {
        ref.read(adServiceProvider).handleMatchOpenInterstitial(isLiveMatch: match.isLive);
        context.push('/match/${match.matchId}', extra: match);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLive ? AppColors.liveIndicator : AppColors.cardBorder,
            width: isLive ? 1.5 : 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isLive
                  ? AppColors.liveIndicator.withValues(alpha: 0.15)
                  : AppColors.surfaceLight,
              AppColors.surface,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: isLive
                  ? AppColors.liveIndicator.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (match.leagueLogo != null && match.leagueLogo!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: match.leagueLogo!,
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.emoji_events_outlined,
                          size: 16,
                          color: AppColors.liveIndicator,
                        ),
                      )
                    else
                      const Icon(
                        Icons.emoji_events_outlined,
                        size: 16,
                        color: AppColors.liveIndicator,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      match.leagueName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
                      color: isReminderSet
                          ? AppColors.liveIndicator
                          : AppColors.textMuted,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      ref.read(matchReminderServiceProvider).toggleReminder(match);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Home Team
                Expanded(
                  child: Column(
                    children: [
                      _buildTeamLogo(match.homeTeamLogo),
                      const SizedBox(height: 8),
                      Text(
                        match.homeTeamName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Score / Status / Time
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.livePulse.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.livePulse),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.livePulse,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                match.statusName.isNotEmpty ? match.statusName : 'مباشر',
                                style: const TextStyle(
                                  color: AppColors.livePulse,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${match.homeScore ?? '٠'} - ${match.awayScore ?? '٠'}',
                          style: const TextStyle(
                            color: AppColors.liveIndicator,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else if (match.isFinished) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'انتهت',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${match.homeScore ?? '٠'} - ${match.awayScore ?? '٠'}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            match.formattedLocalTime,
                            style: const TextStyle(
                              color: AppColors.liveIndicator,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Away Team
                Expanded(
                  child: Column(
                    children: [
                      _buildTeamLogo(match.awayTeamLogo),
                      const SizedBox(height: 8),
                      Text(
                        match.awayTeamName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLogo(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.shield_outlined, size: 28, color: AppColors.textMuted),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: 48,
      height: 48,
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.shield_outlined, size: 28, color: AppColors.textMuted),
      ),
    );
  }
}

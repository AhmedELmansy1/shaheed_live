import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/match_reminder_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/match_model.dart';

/// Polished match card displaying teams, logos, scores, live status pulse, kick-off times, and reminder toggle.
class MatchCard extends ConsumerWidget {
  final MatchModel match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLive = match.isLive;
    final isReminderSetAsync = ref.watch(isReminderSetProvider(match.matchId));
    final isReminderSet = isReminderSetAsync.value ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive ? AppColors.liveIndicator : AppColors.cardBorder,
          width: isLive ? 1.5 : 1,
        ),
        boxShadow: isLive
            ? [
                BoxShadow(
                  color: AppColors.liveIndicator.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: () {
          // Trigger interstitial evaluation based on frequency cap
          ref.read(adServiceProvider).handleMatchOpenInterstitial(isLiveMatch: match.isLive);
          context.push('/match/${match.matchId}', extra: match);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // Home Team (Right side in RTL)
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    _buildTeamLogo(match.homeTeam.image),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        match.homeTeam.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Match Center Status / Score Block + Bell Icon
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCenterStatus(context),
                    if (!isLive && !match.isFinished) ...[
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          ref.read(matchReminderServiceProvider).toggleReminder(match);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Icon(
                            isReminderSet
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_none_rounded,
                            size: 16,
                            color: isReminderSet
                                ? AppColors.liveIndicator
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
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
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildTeamLogo(match.awayTeam.image),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamLogo(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.shield_outlined, size: 18, color: AppColors.textMuted),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: 32,
      height: 32,
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.shield_outlined, size: 18, color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildCenterStatus(BuildContext context) {
    if (match.isLive) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.livePulse.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.livePulse, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.livePulse,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  match.adminTitle ?? 'مباشر',
                  style: const TextStyle(
                    color: AppColors.livePulse,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${match.homeScore ?? '٠'} - ${match.awayScore ?? '٠'}',
            style: const TextStyle(
              color: AppColors.liveIndicator,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    if (match.status == MatchStatus.finished) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${match.homeScore ?? '٠'} - ${match.awayScore ?? '٠'}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            match.adminTitle ?? 'انتهت',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      );
    }

    if (match.status == MatchStatus.postponed ||
        match.status == MatchStatus.cancelled) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            match.adminTitle ??
                (match.status == MatchStatus.postponed ? 'تأجلت' : 'ملغاة'),
            style: const TextStyle(
              color: AppColors.livePulse,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    // Upcoming Match
    final timeFormatted =
        DateFormatter.formatMatchTime(match.matchDate, match.matchTime);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        timeFormatted,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

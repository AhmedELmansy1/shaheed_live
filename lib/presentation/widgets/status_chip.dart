import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/match_model.dart';
import 'live_badge.dart';

/// Minimalist Status Chip representing match lifecycle states in "Paper × Ink × Vermilion".
class StatusChip extends StatelessWidget {
  final MatchModel match;
  final bool isCompact;

  const StatusChip({
    super.key,
    required this.match,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (match.isLive) {
      return LiveBadge(
        minuteText: match.currentMinute,
        isLarge: !isCompact,
      );
    }

    if (match.status == MatchStatus.finished) {
      final finishedColor = AppColors.finishedOf(context);
      final finishedTextColor = AppColors.finishedTextOf(context);
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? AppSpacing.xs + 2 : AppSpacing.sm,
          vertical: isCompact ? AppSpacing.xxs : AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: finishedColor.withValues(alpha: 0.10),
          borderRadius: AppRadii.fullRadius,
          border: Border.all(
            color: finishedColor.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
        child: Text(
          'انتهت',
          style: AppTypography.labelSmall(color: finishedTextColor).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (match.status == MatchStatus.postponed) {
      final isLight = Theme.of(context).brightness == Brightness.light;
      final postponedColor = isLight ? const Color(0xFFB45309) : const Color(0xFFF59E0B);
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? AppSpacing.xs + 2 : AppSpacing.sm,
          vertical: isCompact ? AppSpacing.xxs : AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: postponedColor.withValues(alpha: 0.10),
          borderRadius: AppRadii.fullRadius,
          border: Border.all(
            color: postponedColor.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        child: Text(
          'تأجلت',
          style: AppTypography.labelSmall(color: postponedColor).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (match.status == MatchStatus.cancelled) {
      final cancelledColor = AppColors.textMutedOf(context);
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? AppSpacing.xs + 2 : AppSpacing.sm,
          vertical: isCompact ? AppSpacing.xxs : AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: cancelledColor.withValues(alpha: 0.10),
          borderRadius: AppRadii.fullRadius,
          border: Border.all(
            color: cancelledColor.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
        child: Text(
          'ملغاة',
          style: AppTypography.labelSmall(color: cancelledColor).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Default: Upcoming match kickoff time
    final upcomingColor = AppColors.secondaryOf(context);
    final upcomingTextColor = AppColors.upcomingTextOf(context);
    final timeStr = (match.formattedLocalTime.isNotEmpty && match.formattedLocalTime != '----')
        ? match.formattedLocalTime
        : 'قريباً';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppSpacing.xs + 2 : AppSpacing.sm,
        vertical: isCompact ? AppSpacing.xxs : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: upcomingColor.withValues(alpha: 0.08),
        borderRadius: AppRadii.fullRadius,
        border: Border.all(
          color: upcomingColor.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Text(
        timeStr,
        style: AppTypography.labelSmall(color: upcomingTextColor).copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}


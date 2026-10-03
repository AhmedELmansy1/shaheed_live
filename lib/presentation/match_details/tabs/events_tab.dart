import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/match_event_model.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../providers/match_details_providers.dart';

class EventsTab extends ConsumerWidget {
  final MatchDetailsParams params;
  final dynamic homeTeamId;
  final dynamic awayTeamId;

  const EventsTab({
    super.key,
    required this.params,
    required this.homeTeamId,
    required this.awayTeamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(matchEventsProvider(params));

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const Center(
            child: AppEmptyState(
              type: EmptyStateType.soccer,
              title: 'لا توجد أحداث مسجلة',
              subtitle: 'لم يتم تسجيل أي أحداث لهذه المباراة حتى الآن',
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            120,
          ),
          itemCount: events.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final event = events[index];
            if (event.eventType == MatchEventType.periodMarker) {
              return _buildPeriodMarker(event);
            }
            final isHome = event.teamId.toString() == homeTeamId.toString();
            return _buildEventItem(context, event, isHome: isHome);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, stack) => Center(
        child: AppEmptyState(
          type: EmptyStateType.error,
          title: 'تعذر تحميل الأحداث',
          subtitle: '$err',
        ),
      ),
    );
  }

  Widget _buildPeriodMarker(MatchEventModel event) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceHigh,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Center(
        child: Text(
          event.statusName.isNotEmpty ? event.statusName : DateFormatter.toArabicNumerals(event.formattedMinute),
          style: AppTypography.caption(color: AppColors.darkTextSecondary),
        ),
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, MatchEventModel event, {required bool isHome}) {
    final minuteText = DateFormatter.toArabicNumerals(event.formattedMinute);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Home side (if isHome, display content; else empty space)
        Expanded(
          child: isHome
              ? _buildEventContent(event, Alignment.centerRight, CrossAxisAlignment.end)
              : const SizedBox.shrink(),
        ),

        // Timeline Minute Badge with glow ring
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _getEventBgColor(event.eventType),
            shape: BoxShape.circle,
            border: Border.all(
              color: _getEventBorderColor(event.eventType),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _getEventBorderColor(event.eventType).withValues(alpha: 0.25),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              minuteText,
              style: AppTypography.badge(color: Colors.white, size: 11),
            ),
          ),
        ),

        // Away side (if !isHome, display content; else empty space)
        Expanded(
          child: !isHome
              ? _buildEventContent(event, Alignment.centerLeft, CrossAxisAlignment.start)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildEventContent(
    MatchEventModel event,
    Alignment alignment,
    CrossAxisAlignment crossAxis,
  ) {
    final isGoal = event.eventType == MatchEventType.goal;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      margin: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      borderColor: isGoal ? AppColors.primary.withValues(alpha: 0.5) : null,
      child: Column(
        crossAxisAlignment: crossAxis,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEventIcon(event.eventType),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  event.playerName ?? event.statusName,
                  style: AppTypography.bodySmall(
                    color: isGoal ? AppColors.primary : AppColors.darkTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (event.assistPlayerName != null && event.assistPlayerName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                event.eventType == MatchEventType.substitution
                    ? 'خروج: ${event.assistPlayerName}'
                    : 'تمريرة حاسمة: ${event.assistPlayerName}',
                style: AppTypography.caption(color: AppColors.darkTextSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventIcon(MatchEventType type) {
    switch (type) {
      case MatchEventType.goal:
        return const Icon(Icons.sports_soccer_rounded, color: AppColors.primary, size: 18);
      case MatchEventType.yellowCard:
        return Container(
          width: 11,
          height: 15,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldGlow,
                blurRadius: 4,
              ),
            ],
          ),
        );
      case MatchEventType.redCard:
        return Container(
          width: 11,
          height: 15,
          decoration: BoxDecoration(
            color: AppColors.live,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: AppColors.liveGlowColor,
                blurRadius: 4,
              ),
            ],
          ),
        );
      case MatchEventType.substitution:
        return const Icon(Icons.swap_horiz_rounded, color: AppColors.accentCyan, size: 18);
      default:
        return const Icon(Icons.info_outline_rounded, color: AppColors.darkTextSecondary, size: 16);
    }
  }

  Color _getEventBgColor(MatchEventType type) {
    switch (type) {
      case MatchEventType.goal:
        return AppColors.primary.withValues(alpha: 0.2);
      case MatchEventType.yellowCard:
        return AppColors.gold.withValues(alpha: 0.2);
      case MatchEventType.redCard:
        return AppColors.live.withValues(alpha: 0.2);
      case MatchEventType.substitution:
        return AppColors.accentCyan.withValues(alpha: 0.2);
      default:
        return AppColors.darkSurface;
    }
  }

  Color _getEventBorderColor(MatchEventType type) {
    switch (type) {
      case MatchEventType.goal:
        return AppColors.primary;
      case MatchEventType.yellowCard:
        return AppColors.gold;
      case MatchEventType.redCard:
        return AppColors.live;
      case MatchEventType.substitution:
        return AppColors.accentCyan;
      default:
        return AppColors.darkBorder;
    }
  }
}

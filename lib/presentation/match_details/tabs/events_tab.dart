import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/match_event_model.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/matches_skeleton.dart';
import '../providers/match_details_providers.dart';

/// Clean, editorial Events Timeline in "Paper × Ink × Vermilion".
///
/// Features:
/// - Vertical timeline axis with minute markers in tabular figures.
/// - RTL-correct alignment: Home events on right, Away events on left.
/// - Distinct semantic icons: Goal (vermilion), Cards (yellow/red), Subs, VAR.
/// - Graceful handling of period markers and empty event feeds.
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
      loading: () => const MatchesSkeleton(),
      error: (err, stack) => AppErrorState(
        title: 'تعذر تحميل أحداث المباراة',
        subtitle: 'يرجى التحقق من اتصالك بالإنترنت وإعادة المحاولة.',
        onRetry: () => ref.invalidate(matchEventsProvider(params)),
      ),
      data: (events) {
        if (events.isEmpty) {
          return const AppEmptyState(
            type: EmptyStateType.soccer,
            title: 'لا توجد أحداث مسجلة لهذه المباراة حتى الآن',
            subtitle: 'سيتم تسجيل الأهداف والبطاقات والتبديلات فور حدوثها في أرضية الميدان.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            // Neutral centered marker for period markers (type 100), team_id 0, or unassigned events
            final isNeutral = event.eventType == MatchEventType.periodMarker ||
                event.teamId == 0 ||
                event.teamId == '0' ||
                event.teamId == null;

            if (isNeutral) {
              return _buildPeriodMarker(context, event);
            }

            final isHome = event.teamId.toString() == homeTeamId.toString();
            return _buildTimelineItem(context, event, isHome: isHome);
          },
        );
      },
    );
  }

  Widget _buildPeriodMarker(BuildContext context, MatchEventModel event) {
    final surfaceElevated = AppColors.surfaceElevatedOf(context);
    final border = AppColors.borderOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    final title = event.statusName.trim().isNotEmpty
        ? event.statusName.trim()
        : (event.minute > 0 ? event.formattedMinute : 'صافرة الحكم');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Divider(color: border, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: surfaceElevated,
                borderRadius: AppRadii.fullRadius,
                border: Border.all(color: border, width: 1.0),
              ),
              child: Text(
                title,
                style: AppTypography.labelSmall(color: textSecondary).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: border, height: 1)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    MatchEventModel event, {
    required bool isHome,
  }) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);

    // Determine semantic accent color for the event
    final Color accentColor = switch (event.eventType) {
      MatchEventType.goal || MatchEventType.penaltyScored => AppColors.neonEmerald,
      MatchEventType.redCard || MatchEventType.secondYellow || MatchEventType.penaltyMissed => AppColors.coralCrimson,
      MatchEventType.yellowCard => AppColors.metallicGold,
      MatchEventType.substitution || MatchEventType.crossbar || MatchEventType.save || MatchEventType.missedChance => AppColors.electricCyan,
      _ => AppColors.primaryOf(context),
    };

    final eventBadge = _buildEventIcon(context, event, accentColor);

    final contentWidget = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: border, width: 1.0),
        boxShadow: [
          if (Theme.of(context).brightness == Brightness.dark)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isHome ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHome) ...[
                eventBadge,
                const SizedBox(width: AppSpacing.xs + 2),
              ],
              Flexible(
                child: Text(
                  event.statusName,
                  style: AppTypography.labelMedium(color: textPrimary).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!isHome) ...[
                const SizedBox(width: AppSpacing.xs + 2),
                eventBadge,
              ],
            ],
          ),
          if (event.playerName != null && event.playerName!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              event.playerName!,
              style: AppTypography.bodySmall(color: textPrimary).copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (event.assistPlayerName != null &&
              event.assistPlayerName!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'صناعة: ${event.assistPlayerName!}',
              style: AppTypography.labelSmall(color: textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    // Glowing Minute Indicator (Middle Axis)
    final minuteWidget = Container(
      width: 48,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: AppRadii.fullRadius,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: [
          if (Theme.of(context).brightness == Brightness.dark)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.25),
              blurRadius: 8,
            ),
        ],
      ),
      child: Text(
        event.formattedMinute,
        style: AppTypography.scoreHeadline(color: textPrimary).copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Home Side (Right side in RTL)
          Expanded(
            child: isHome ? contentWidget : const SizedBox.shrink(),
          ),

          // Central Minute Axis
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: minuteWidget,
          ),

          // Away Side (Left side in RTL)
          Expanded(
            child: !isHome ? contentWidget : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventIcon(BuildContext context, MatchEventModel event, Color accentColor) {
    switch (event.eventType) {
      case MatchEventType.goal:
      case MatchEventType.penaltyScored:
        return const Icon(
          Icons.sports_soccer_rounded,
          color: AppColors.neonEmerald,
          size: 16,
        );
      case MatchEventType.ownGoal:
        return Icon(
          Icons.sports_soccer_rounded,
          color: AppColors.coralCrimson,
          size: 16,
        );
      case MatchEventType.penaltyMissed:
        return const Icon(
          Icons.highlight_off_rounded,
          color: AppColors.coralCrimson,
          size: 16,
        );
      case MatchEventType.yellowCard:
        return Container(
          width: 10,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.metallicGold,
            borderRadius: BorderRadius.circular(2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66FFB300),
                blurRadius: 4,
              ),
            ],
          ),
        );
      case MatchEventType.redCard:
        return Container(
          width: 10,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.coralCrimson,
            borderRadius: BorderRadius.circular(2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66FF3D57),
                blurRadius: 4,
              ),
            ],
          ),
        );
      case MatchEventType.secondYellow:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 13,
              decoration: BoxDecoration(
                color: AppColors.metallicGold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 2),
            Container(
              width: 9,
              height: 13,
              decoration: BoxDecoration(
                color: AppColors.coralCrimson,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        );
      case MatchEventType.substitution:
        return const Icon(
          Icons.swap_horiz_rounded,
          color: AppColors.electricCyan,
          size: 17,
        );
      case MatchEventType.varDisallowed:
        return const Icon(
          Icons.tv_rounded,
          color: AppColors.coralCrimson,
          size: 16,
        );
      case MatchEventType.crossbar:
      case MatchEventType.save:
      case MatchEventType.missedChance:
        return Icon(
          Icons.sports_rounded,
          color: accentColor,
          size: 16,
        );
      default:
        return Icon(
          Icons.info_outline_rounded,
          color: AppColors.textSecondaryOf(context),
          size: 15,
        );
    }
  }
}

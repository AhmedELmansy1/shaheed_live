import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/match_event_model.dart';
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
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'لا توجد أحداث مسجلة لهذه المباراة حتى الآن',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: events.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
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
        child: CircularProgressIndicator(color: AppColors.liveIndicator),
      ),
      error: (err, stack) => Center(
        child: Text(
          'خطأ في تحميل الأحداث: $err',
          style: const TextStyle(color: AppColors.livePulse),
        ),
      ),
    );
  }

  Widget _buildPeriodMarker(MatchEventModel event) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Center(
        child: Text(
          event.statusName.isNotEmpty ? event.statusName : event.formattedMinute,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, MatchEventModel event, {required bool isHome}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Home side (if isHome, display content; else spacer)
        Expanded(
          child: isHome
              ? _buildEventContent(event, Alignment.centerRight, CrossAxisAlignment.end)
              : const SizedBox.shrink(),
        ),

        // Timeline Minute Badge
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getEventBgColor(event.eventType),
            shape: BoxShape.circle,
            border: Border.all(color: _getEventBorderColor(event.eventType), width: 1.5),
          ),
          child: Text(
            event.formattedMinute,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Away side (if !isHome, display content; else spacer)
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
    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEventIcon(event.eventType),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                event.playerName ?? event.statusName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
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
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildEventIcon(MatchEventType type) {
    switch (type) {
      case MatchEventType.goal:
        return const Icon(Icons.sports_soccer, color: AppColors.liveIndicator, size: 18);
      case MatchEventType.yellowCard:
        return Container(
          width: 12,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case MatchEventType.redCard:
        return Container(
          width: 12,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.livePulse,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case MatchEventType.substitution:
        return const Icon(Icons.swap_horiz, color: Colors.blueAccent, size: 18);
      default:
        return const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 16);
    }
  }

  Color _getEventBgColor(MatchEventType type) {
    switch (type) {
      case MatchEventType.goal:
        return AppColors.liveIndicator.withValues(alpha: 0.2);
      case MatchEventType.yellowCard:
        return Colors.amber.withValues(alpha: 0.2);
      case MatchEventType.redCard:
        return AppColors.livePulse.withValues(alpha: 0.2);
      default:
        return AppColors.surface;
    }
  }

  Color _getEventBorderColor(MatchEventType type) {
    switch (type) {
      case MatchEventType.goal:
        return AppColors.liveIndicator;
      case MatchEventType.yellowCard:
        return Colors.amber;
      case MatchEventType.redCard:
        return AppColors.livePulse;
      default:
        return AppColors.cardBorder;
    }
  }
}

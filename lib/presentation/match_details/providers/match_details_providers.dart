import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/match_event_model.dart';
import '../../../data/models/match_info_model.dart';
import '../../../data/models/match_lineup_model.dart';
import '../../../data/models/match_statistics_model.dart';
import '../../home/providers/matches_provider.dart';

/// Parameter object identifying a match for detail family providers.
class MatchDetailsParams {
  final String matchId;
  final dynamic homeTeamId;
  final dynamic awayTeamId;
  final bool isLive;

  const MatchDetailsParams({
    required this.matchId,
    required this.homeTeamId,
    required this.awayTeamId,
    this.isLive = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchDetailsParams &&
          runtimeType == other.runtimeType &&
          matchId == other.matchId &&
          homeTeamId == other.homeTeamId &&
          awayTeamId == other.awayTeamId &&
          isLive == other.isLive;

  @override
  int get hashCode => Object.hash(matchId, homeTeamId, awayTeamId, isLive);
}

/// Provider for match info metadata (`match_info`).
final matchInfoProvider = FutureProvider.family<MatchInfoModel?, String>((ref, matchId) async {
  final repo = ref.watch(matchesRepositoryProvider);
  return repo.getMatchInfo(matchId);
});

/// Provider for match events timeline (`matches_event`) with 30-second live polling.
///
/// TIMER LIFECYCLE:
/// When `ref.invalidateSelf()` fires, Riverpod disposes the current provider state
/// (triggering `ref.onDispose` → cancelling the old timer), then re-executes this
/// function body (creating exactly one new timer). This guarantees at most one active
/// timer per provider instance at any time.
final matchEventsProvider = FutureProvider.family<List<MatchEventModel>, MatchDetailsParams>((ref, params) async {
  if (params.isLive) {
    final timerId = Object.hash('events', params.matchId, DateTime.now().millisecondsSinceEpoch);
    developer.log(
      '[POLL] matchEventsProvider: Creating timer #$timerId for match ${params.matchId}',
      name: 'LivePolling',
    );

    final timer = Timer.periodic(const Duration(seconds: 30), (_) {
      developer.log(
        '[POLL] matchEventsProvider: Timer #$timerId FIRED → invalidateSelf() for match ${params.matchId}',
        name: 'LivePolling',
      );
      ref.invalidateSelf();
    });

    ref.onDispose(() {
      timer.cancel();
      developer.log(
        '[POLL] matchEventsProvider: Timer #$timerId CANCELLED (onDispose) for match ${params.matchId}',
        name: 'LivePolling',
      );
    });
  }

  final repo = ref.watch(matchesRepositoryProvider);
  return repo.getMatchEvents(params.matchId);
});

/// Provider for match statistics (`statics_match`) with 30-second live polling.
///
/// Same timer lifecycle guarantees as [matchEventsProvider].
final matchStatisticsProvider = FutureProvider.family<MatchStatisticsModel?, MatchDetailsParams>((ref, params) async {
  if (params.isLive) {
    final timerId = Object.hash('stats', params.matchId, DateTime.now().millisecondsSinceEpoch);
    developer.log(
      '[POLL] matchStatisticsProvider: Creating timer #$timerId for match ${params.matchId}',
      name: 'LivePolling',
    );

    final timer = Timer.periodic(const Duration(seconds: 30), (_) {
      developer.log(
        '[POLL] matchStatisticsProvider: Timer #$timerId FIRED → invalidateSelf() for match ${params.matchId}',
        name: 'LivePolling',
      );
      ref.invalidateSelf();
    });

    ref.onDispose(() {
      timer.cancel();
      developer.log(
        '[POLL] matchStatisticsProvider: Timer #$timerId CANCELLED (onDispose) for match ${params.matchId}',
        name: 'LivePolling',
      );
    });
  }

  final repo = ref.watch(matchesRepositoryProvider);
  return repo.getMatchStatistics(
    params.matchId,
    homeTeamId: params.homeTeamId,
    awayTeamId: params.awayTeamId,
  );
});

/// Provider for match lineups (`matches_lineup`).
final matchLineupProvider = FutureProvider.family<MatchLineupModel?, MatchDetailsParams>((ref, params) async {
  final repo = ref.watch(matchesRepositoryProvider);
  return repo.getMatchLineup(
    params.matchId,
    homeTeamId: params.homeTeamId,
    awayTeamId: params.awayTeamId,
  );
});

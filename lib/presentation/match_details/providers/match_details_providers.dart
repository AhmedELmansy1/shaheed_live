import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/match_score_api.dart';
import '../../../data/models/match_event_model.dart';
import '../../../data/models/match_info_model.dart';
import '../../../data/models/match_lineup_model.dart';
import '../../../data/models/match_news_model.dart';
import '../../../data/models/match_statistics_model.dart';
import '../../../data/models/standings_model.dart';
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
final matchInfoProvider = FutureProvider.family<MatchInfoModel?, String>((
  ref,
  matchId,
) async {
  final repo = ref.watch(matchesRepositoryProvider);
  return repo.getMatchInfo(matchId);
});

/// Provider for match events timeline (`matches_event`).
///
/// Lifecycle-managed 30s polling is coordinated cleanly by [LiveMatchPollingManager]
/// on the active [MatchDetailsScreen], pausing on background and cancelling on dispose.
final matchEventsProvider =
    FutureProvider.family<List<MatchEventModel>, MatchDetailsParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(matchesRepositoryProvider);
      return repo.getMatchEvents(params.matchId);
    });

/// Provider for match statistics (`statics_match`).
///
/// Lifecycle-managed 30s polling is coordinated cleanly by [LiveMatchPollingManager]
/// on the active [MatchDetailsScreen], pausing on background and cancelling on dispose.
final matchStatisticsProvider =
    FutureProvider.family<MatchStatisticsModel?, MatchDetailsParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(matchesRepositoryProvider);
      return repo.getMatchStatistics(
        params.matchId,
        homeTeamId: params.homeTeamId,
        awayTeamId: params.awayTeamId,
      );
    });

/// Provider for match lineups (`matches_lineup`).
final matchLineupProvider =
    FutureProvider.family<MatchLineupModel?, MatchDetailsParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(matchesRepositoryProvider);
      return repo.getMatchLineup(
        params.matchId,
        homeTeamId: params.homeTeamId,
        awayTeamId: params.awayTeamId,
      );
    });

/// Provider for YsscoresSource instance.
final ysscoresSourceProvider = Provider<YsscoresSource>((ref) {
  return YsscoresSource();
});

/// Provider for league standings table (`get_league_rank`).
final matchStandingsProvider =
    FutureProvider.family<List<StandingRowModel>, int>((ref, matchId) async {
  final source = ref.watch(ysscoresSourceProvider);
  try {
    final raw = await source.rawLeagueRank(matchId);
    return StandingRowModel.fromResponse(raw);
  } catch (e) {
    developer.log(
      '[MatchStandings] Error fetching standings: $e',
      name: 'Standings',
    );
    return [];
  }
});

/// Provider for match news articles (`get_match_news`).
final matchNewsProvider =
    FutureProvider.family<List<MatchNewsItemModel>, int>((ref, matchId) async {
  final source = ref.watch(ysscoresSourceProvider);
  try {
    final raw = await source.rawMatchNews(matchId);
    return MatchNewsItemModel.fromResponse(raw);
  } catch (e) {
    developer.log(
      '[MatchNews] Error fetching news: $e',
      name: 'News',
    );
    return [];
  }
});

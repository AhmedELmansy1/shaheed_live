import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/team_model.dart';
import '../../home/providers/matches_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';

// 1. All Teams Provider - AsyncNotifier
class AllTeamsNotifier extends AsyncNotifier<List<TeamModel>> {
  @override
  Future<List<TeamModel>> build() async {
    final repository = ref.read(onboardingRepositoryProvider);
    try {
      final leagues = await repository.getPopularLeagues();
      final leagueIds = leagues.map((l) => l.id).toList();
      final teams = await repository.getTeamsForLeagues(leagueIds);
      return teams;
    } catch (e) {
      debugPrint('Error fetching all teams: $e');
      return [];
    }
  }
}

final allTeamsProvider = AsyncNotifierProvider<AllTeamsNotifier, List<TeamModel>>(() {
  return AllTeamsNotifier();
});

// 2. Search Query Notifier
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

// 3. Filtered Teams Provider
final filteredTeamsProvider = Provider<List<TeamModel>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final allTeamsState = ref.watch(allTeamsProvider);

  return allTeamsState.maybeWhen(
    data: (teams) {
      if (query.isEmpty) return teams;
      
      return teams.where((team) {
        final nameAr = team.name.toLowerCase();
        final nameEn = team.nameEn.toLowerCase();
        return nameAr.contains(query) || nameEn.contains(query);
      }).toList();
    },
    orElse: () => [],
  );
});

// 4. Team Fixtures Provider
final teamFixturesProvider = FutureProvider.family<List<MatchModel>, String>((ref, teamName) async {
  final matchesRepo = ref.read(matchesRepositoryProvider);
  
  final now = DateTime.now();
  final dates = [
    now,
    now.add(const Duration(days: 1)),
    now.add(const Duration(days: 2)),
  ];

  List<MatchModel> allMatches = [];

  for (final date in dates) {
    try {
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final matches = await matchesRepo.getMatchesByDate(formattedDate);
      allMatches.addAll(matches);
    } catch (e) {
      debugPrint('Error fetching matches for team fixtures: $e');
    }
  }

  // Filter matches by team name
  final teamNameLower = teamName.toLowerCase();
  final filteredMatches = allMatches.where((match) {
    final homeTitle = match.homeTeam.title.toLowerCase();
    final awayTitle = match.awayTeam.title.toLowerCase();
    return homeTitle.contains(teamNameLower) || awayTitle.contains(teamNameLower);
  }).toList();

  return filteredMatches;
});

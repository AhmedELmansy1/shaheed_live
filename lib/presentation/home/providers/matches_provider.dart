import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/match_model.dart';
import '../../../data/repositories/matches_repository.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiMatchesRepository(dioClient: dioClient);
});

enum HomeTab { yesterday, today, tomorrow, customDate }

class ActiveTabNotifier extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.today;

  void setTab(HomeTab tab) {
    state = tab;
  }
}

final activeTabProvider = NotifierProvider<ActiveTabNotifier, HomeTab>(() {
  return ActiveTabNotifier();
});

class SelectedCustomDateNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void setDate(DateTime? date) {
    state = date;
  }
}

final selectedCustomDateProvider =
    NotifierProvider<SelectedCustomDateNotifier, DateTime?>(() {
  return SelectedCustomDateNotifier();
});

/// State notifier managing matches fetching, error handling, and 30-second auto-polling for live matches.
class MatchesNotifier extends AsyncNotifier<List<MatchModel>> {
  Timer? _pollingTimer;

  @override
  FutureOr<List<MatchModel>> build() async {
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    return fetchMatches();
  }

  Future<List<MatchModel>> fetchMatches() async {
    final repository = ref.read(matchesRepositoryProvider);
    final activeTab = ref.read(activeTabProvider);
    final customDate = ref.read(selectedCustomDateProvider);

    final now = DateTime.now();
    late DateTime targetDate;

    switch (activeTab) {
      case HomeTab.yesterday:
        targetDate = now.subtract(const Duration(days: 1));
        break;
      case HomeTab.today:
        targetDate = now;
        break;
      case HomeTab.tomorrow:
        targetDate = now.add(const Duration(days: 1));
        break;
      case HomeTab.customDate:
        targetDate = customDate ?? now;
        break;
    }

    final dateStr = DateFormatter.toApiDateString(targetDate);
    final matches = await repository.getMatchesByDate(dateStr);

    _checkAndSchedulePolling(matches);

    return matches;
  }

  void _checkAndSchedulePolling(List<MatchModel> matches) {
    _pollingTimer?.cancel();

    final hasLiveMatches = matches.any((m) => m.isLive);
    if (hasLiveMatches) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        final updatedMatches = await fetchMatches();
        state = AsyncData(updatedMatches);
      });
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => fetchMatches());
  }
}

final matchesProvider =
    AsyncNotifierProvider<MatchesNotifier, List<MatchModel>>(() {
  return MatchesNotifier();
});

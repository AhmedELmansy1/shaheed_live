import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/services/league_resolver_service.dart';
import 'package:shoot_live/data/models/league_model.dart';
import 'package:shoot_live/data/models/match_event_model.dart';
import 'package:shoot_live/data/models/match_info_model.dart';
import 'package:shoot_live/data/models/match_lineup_model.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/match_statistics_model.dart';
import 'package:shoot_live/data/models/standings_model.dart';
import 'package:shoot_live/data/repositories/matches_repository.dart';
import 'package:shoot_live/presentation/home/providers/matches_provider.dart';
import 'package:shoot_live/core/utils/date_formatter.dart';
import 'package:shoot_live/presentation/leagues/league_details_screen.dart';

class FakeMatchesRepository implements MatchesRepository {
  @override
  Future<List<MatchModel>> getMatchesByDate(String date, {bool forceRefresh = false}) async => [];
  @override
  Future<List<MatchModel>> getMatchesToday({bool forceRefresh = false}) async => [];
  @override
  Future<List<MatchModel>> getMatchesTomorrow({bool forceRefresh = false}) async => [];
  @override
  Future<List<MatchModel>> getMatchesYesterday({bool forceRefresh = false}) async => [];
  @override
  Future<MatchInfoModel?> getMatchInfo(String matchId, {bool forceRefresh = false}) async => null;
  @override
  Future<MatchStatisticsModel?> getMatchStatistics(String matchId, {required dynamic homeTeamId, required dynamic awayTeamId, bool forceRefresh = false}) async => null;
  @override
  Future<List<MatchEventModel>> getMatchEvents(String matchId, {bool forceRefresh = false}) async => [];
  @override
  Future<MatchLineupModel?> getMatchLineup(String matchId, {required dynamic homeTeamId, required dynamic awayTeamId, bool forceRefresh = false}) async => null;
}

class MockTestRepo implements MatchesRepository {
  final Future<List<MatchModel>> Function(String date) onGetDate;

  MockTestRepo({required this.onGetDate});

  @override
  Future<List<MatchModel>> getMatchesByDate(String date, {bool forceRefresh = false}) => onGetDate(date);
  @override
  Future<List<MatchModel>> getMatchesToday({bool forceRefresh = false}) async => [];
  @override
  Future<List<MatchModel>> getMatchesTomorrow({bool forceRefresh = false}) async => [];
  @override
  Future<List<MatchModel>> getMatchesYesterday({bool forceRefresh = false}) async => [];
  @override
  Future<MatchInfoModel?> getMatchInfo(String matchId, {bool forceRefresh = false}) async => null;
  @override
  Future<MatchStatisticsModel?> getMatchStatistics(String matchId, {required dynamic homeTeamId, required dynamic awayTeamId, bool forceRefresh = false}) async => null;
  @override
  Future<List<MatchEventModel>> getMatchEvents(String matchId, {bool forceRefresh = false}) async => [];
  @override
  Future<MatchLineupModel?> getMatchLineup(String matchId, {required dynamic homeTeamId, required dynamic awayTeamId, bool forceRefresh = false}) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 3 — League Details & Features Completion Tests', () {
    const testLeague = LeagueModel(
      id: 'esp_1',
      name: 'الدوري الإسباني',
      nameEn: 'La Liga',
      country: 'إسبانيا',
      logoUrl: 'https://imgs.ysscores.com/championship/48/1933.png',
    );

    test('LeagueResolverService contains seeded championship mappings', () {
      final seeded = LeagueResolverService.seededChampToLeague;
      expect(seeded['1933'], 'esp_1'); // La Liga
      expect(seeded['6811'], 'eng_1'); // Premier League
      expect(seeded['3734'], 'ita_1'); // Serie A
      expect(seeded['6047'], 'egy_1'); // Egyptian Premier League
      expect(seeded['1929'], 'ucl');   // UEFA Champions League
    });

    testWidgets('LeagueDetailsScreen renders header with title, country, and tabs', (tester) async {
      final container = ProviderContainer(
        overrides: [
          matchesRepositoryProvider.overrideWithValue(FakeMatchesRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LeagueDetailsScreen(
              leagueId: 'esp_1',
              initialLeague: testLeague,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify League Header
      expect(find.text('الدوري الإسباني'), findsWidgets);
      expect(find.textContaining('La Liga'), findsOneWidget);
      expect(find.textContaining('إسبانيا'), findsOneWidget);

      // 2. Verify Tab Bar
      expect(find.text('المباريات'), findsOneWidget);
      expect(find.text('الترتيب'), findsOneWidget);
      expect(find.text('معلومات البطولة'), findsOneWidget);

      // 3. Switch to Information Tab
      await tester.tap(find.text('معلومات البطولة'));
      await tester.pumpAndSettle();

      expect(find.text('بيانات البطولة'), findsOneWidget);
      expect(find.text('اسم البطولة (بالعربية)'), findsOneWidget);
      expect(find.text('الاسم الرسمي (بالإنجليزية)'), findsOneWidget);
      expect(find.text('رمز البطولة التعريفي'), findsOneWidget);
      expect(find.text('تفضيلات المتابعة'), findsOneWidget);
    });

    test('StandingRowModel parses real ranking data and formats stats correctly', () {
      final sampleJson = {
        "list_match": [
          {
            "1": {
              "name": "ريال مدريد",
              "team_name": {
                "row_id": 8633,
                "title": "ريال مدريد",
                "image": "https://imgs.ysscores.com/teams/64/8633.png"
              },
              "team_id": 8633,
              "play": 10,
              "wins": 8,
              "draw": 1,
              "lose": 1,
              "for": 25,
              "against": 8,
              "diff": 17,
              "points": 25,
              "last_stand": 1,
              "color": "#4986e7"
            }
          }
        ]
      };

      final rows = StandingRowModel.fromResponse(sampleJson);
      expect(rows.length, 1);
      final topTeam = rows.first;
      expect(topTeam.rank, 1);
      expect(topTeam.teamId, 8633);
      expect(topTeam.teamName, 'ريال مدريد');
      expect(topTeam.played, 10);
      expect(topTeam.won, 8);
      expect(topTeam.drawn, 1);
      expect(topTeam.lost, 1);
      expect(topTeam.goalDiff, 17);
      expect(topTeam.points, 25);
      expect(topTeam.color, '#4986e7');
    });

    test('getLeagueDateRangeStrings generates correct 30-day and 60-day ranges', () {
      final upcoming = getLeagueDateRangeStrings(LeagueMatchesRange.upcoming);
      expect(upcoming.length, 31);
      final todayStr = DateFormatter.toApiDateString(DateTime.now());
      expect(upcoming.first, todayStr);

      final past = getLeagueDateRangeStrings(LeagueMatchesRange.past);
      expect(past.length, 30);
      final yesterdayStr = DateFormatter.toApiDateString(DateTime.now().subtract(const Duration(days: 1)));
      expect(past.last, yesterdayStr);

      final all = getLeagueDateRangeStrings(LeagueMatchesRange.all);
      expect(all.length, 61);
      expect(all.contains(todayStr), isTrue);
      expect(all.contains(yesterdayStr), isTrue);
    });

    test('fetchMatchesWithConcurrencyLimit enforces concurrency limit and handles partial failures', () async {
      var activeWorkers = 0;
      var maxObservedConcurrency = 0;

      final testDates = List.generate(20, (i) => '2026-11-${(i + 1).toString().padLeft(2, '0')}');

      final repo = MockTestRepo(onGetDate: (date) async {
        activeWorkers++;
        if (activeWorkers > maxObservedConcurrency) {
          maxObservedConcurrency = activeWorkers;
        }
        await Future.delayed(const Duration(milliseconds: 10));
        activeWorkers--;

        if (date == '2026-11-05') {
          throw Exception('Simulated network glitch for 2026-11-05');
        }
        return [
          MatchModel(
            matchId: date.hashCode.abs(),
            matchDate: date,
            matchTime: '18:00:00',
            isLive: false,
            status: MatchStatus.notStarted,
            championship: const ChampionshipInfo(id: 1933, title: 'الدوري الإسباني'),
            homeTeam: const TeamInfo(rowId: 1, title: 'فريق 1'),
            awayTeam: const TeamInfo(rowId: 2, title: 'فريق 2'),
            homeScore: null,
            awayScore: null,
            adminBadge: null,
            adminTitle: null,
            eventStatus: null,
          ),
        ];
      });

      final results = await fetchMatchesWithConcurrencyLimit(
        repo: repo,
        dateStrings: testDates,
        concurrencyLimit: 4,
      );

      expect(maxObservedConcurrency, lessThanOrEqualTo(4));
      expect(results.length, 19);
    });

    test('leagueMatchesProvider aggregates 30 days, deduplicates, filters, and sorts chronologically', () async {
      final now = DateTime.now();
      final todayStr = DateFormatter.toApiDateString(now);
      final day10Str = DateFormatter.toApiDateString(now.add(const Duration(days: 10)));

      final repo = MockTestRepo(onGetDate: (date) async {
        if (date == todayStr) {
          return [
            // Out of chronological order match (20:00)
            MatchModel(
              matchId: 102,
              matchDate: todayStr,
              matchTime: '20:00:00',
              isLive: false,
              status: MatchStatus.notStarted,
              championship: const ChampionshipInfo(id: 1933, title: 'الدوري الإسباني'),
              homeTeam: const TeamInfo(rowId: 8633, title: 'ريال مدريد'),
              awayTeam: const TeamInfo(rowId: 8634, title: 'برشلونة'),
              homeScore: null,
              awayScore: null,
              adminBadge: null,
              adminTitle: null,
              eventStatus: null,
            ),
            // Earlier match (16:00)
            MatchModel(
              matchId: 101,
              matchDate: todayStr,
              matchTime: '16:00:00',
              isLive: false,
              status: MatchStatus.notStarted,
              championship: const ChampionshipInfo(id: 1933, title: 'الدوري الإسباني'),
              homeTeam: const TeamInfo(rowId: 8633, title: 'ريال مدريد'),
              awayTeam: const TeamInfo(rowId: 8650, title: 'أتلتيكو مدريد'),
              homeScore: null,
              awayScore: null,
              adminBadge: null,
              adminTitle: null,
              eventStatus: null,
            ),
            // Match from a DIFFERENT league (should be filtered out)
            MatchModel(
              matchId: 999,
              matchDate: todayStr,
              matchTime: '17:00:00',
              isLive: false,
              status: MatchStatus.notStarted,
              championship: const ChampionshipInfo(id: 6811, title: 'الدوري الإنجليزي الممتاز'),
              homeTeam: const TeamInfo(rowId: 99, title: 'أرسنال'),
              awayTeam: const TeamInfo(rowId: 100, title: 'تشيلسي'),
              homeScore: null,
              awayScore: null,
              adminBadge: null,
              adminTitle: null,
              eventStatus: null,
            ),
          ];
        }
        if (date == day10Str) {
          return [
            // Duplicate of match 102 (same match ID on another sync date)
            MatchModel(
              matchId: 102,
              matchDate: day10Str,
              matchTime: '20:00:00',
              isLive: false,
              status: MatchStatus.notStarted,
              championship: const ChampionshipInfo(id: 1933, title: 'الدوري الإسباني'),
              homeTeam: const TeamInfo(rowId: 8633, title: 'ريال مدريد'),
              awayTeam: const TeamInfo(rowId: 8634, title: 'برشلونة'),
              homeScore: null,
              awayScore: null,
              adminBadge: null,
              adminTitle: null,
              eventStatus: null,
            ),
            // Valid upcoming match
            MatchModel(
              matchId: 103,
              matchDate: day10Str,
              matchTime: '19:00:00',
              isLive: false,
              status: MatchStatus.notStarted,
              championship: const ChampionshipInfo(id: 1933, title: 'الدوري الإسباني'),
              homeTeam: const TeamInfo(rowId: 8634, title: 'برشلونة'),
              awayTeam: const TeamInfo(rowId: 8650, title: 'أتلتيكو مدريد'),
              homeScore: null,
              awayScore: null,
              adminBadge: null,
              adminTitle: null,
              eventStatus: null,
            ),
          ];
        }
        return [];
      });

      final container = ProviderContainer(
        overrides: [
          matchesRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final matches = await container.read(leagueMatchesProvider('esp_1').future);

      expect(matches.any((m) => m.matchId == 999), isFalse);
      expect(matches.where((m) => m.matchId == 102).length, 1);
      expect(matches.length, 3);

      expect(matches[0].matchId, 101);
      expect(matches[1].matchId, 102);
      expect(matches[2].matchId, 103);
    });
  });
}

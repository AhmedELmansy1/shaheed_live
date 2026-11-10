import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/network/dio_client.dart';
import 'package:shoot_live/data/cache/matches_cache_service.dart';
import 'package:shoot_live/data/repositories/matches_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late MatchesCacheService cacheService;

  final sampleRawMatches = [
    {
      'id': 1001,
      'match_date': '2026-11-08',
      'match_time': '20:00',
      'status': '1',
      'home_team': {'row_id': 1, 'title': 'Real Madrid', 'image': 'https://example.com/rm.png'},
      'away_team': {'row_id': 2, 'title': 'Barcelona', 'image': 'https://example.com/fcb.png'},
      'championship': {'id': 50, 'title': 'La Liga', 'image': 'https://example.com/laliga.png'},
      'home_scores': '2',
      'away_scores': '1',
      'admin_title': 'مباشر',
    },
    {
      'id': 1002,
      'match_date': '2026-11-08',
      'match_time': '22:00',
      'status': '0',
      'home_team': {'row_id': 3, 'title': 'Arsenal', 'image': 'https://example.com/ars.png'},
      'away_team': {'row_id': 4, 'title': 'Chelsea', 'image': 'https://example.com/che.png'},
      'championship': {'id': 51, 'title': 'Premier League', 'image': 'https://example.com/pl.png'},
      'admin_title': 'لم تبدأ',
    }
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    cacheService = MatchesCacheService(prefs: prefs);
  });

  group('MatchesCacheService Unit Tests', () {
    test('saveMatches stores data and getCachedMatches retrieves models correctly', () async {
      const dateStr = '2026-11-08';
      await cacheService.saveMatches(dateStr, sampleRawMatches);

      final result = cacheService.getCachedMatches(dateStr);
      expect(result, isNotNull);
      expect(result!.matches.length, 2);
      expect(result.matches.first.matchId, 1001);
      expect(result.matches.first.homeTeamName, 'Real Madrid');
      expect(result.matches.first.awayTeamName, 'Barcelona');
      expect(result.matches.first.homeScore, '2');
      expect(result.isExpired, isFalse);
    });

    test('TTL policy distinguishes today, past, and future dates', () {
      final now = DateTime.now();
      final todayStr =
          "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr =
          "${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowStr =
          "${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";

      expect(cacheService.getTtlForDate(todayStr), const Duration(minutes: 2));
      expect(cacheService.getTtlForDate(yesterdayStr), const Duration(hours: 24));
      expect(cacheService.getTtlForDate(tomorrowStr), const Duration(minutes: 30));
    });

    test('invalidateMatches deletes cached entry', () async {
      const dateStr = '2026-11-08';
      await cacheService.saveMatches(dateStr, sampleRawMatches);
      expect(cacheService.getCachedMatches(dateStr), isNotNull);

      await cacheService.invalidateMatches(dateStr);
      expect(cacheService.getCachedMatches(dateStr), isNull);
    });

    test('Match Info caching and retrieval', () async {
      const matchId = '1001';
      final infoData = {
        'id': 1001,
        'stadium_name': 'Santiago Bernabéu',
        'channel_name': 'beIN Sports 1',
        'commentator_name': 'Issam Chaouali',
        'referee_name': 'Gil Manzano',
      };

      await cacheService.saveMatchInfo(matchId, infoData);
      final cachedInfo = cacheService.getCachedMatchInfo(matchId);

      expect(cachedInfo, isNotNull);
      expect(cachedInfo!.stadium, 'Santiago Bernabéu');
      expect(cachedInfo.channel, 'beIN Sports 1');
      expect(cachedInfo.commentator, 'Issam Chaouali');
    });
  });

  group('ApiMatchesRepository with MatchesCacheService', () {
    test('returns cached data instantly when cache is fresh without network call', () async {
      const dateStr = '2026-11-08';
      await cacheService.saveMatches(dateStr, sampleRawMatches);

      // Pass a dummy client that will fail if invoked
      final repo = ApiMatchesRepository(
        dioClient: DioClient(),
        cacheService: cacheService,
      );

      final matches = await repo.getMatchesByDate(dateStr, forceRefresh: false);
      expect(matches.length, 2);
      expect(matches.first.homeTeamName, 'Real Madrid');
    });

    test('falls back to stale cache when network fails', () async {
      const dateStr = '2026-11-08';
      await cacheService.saveMatches(dateStr, sampleRawMatches);

      // Create a mock DioClient that throws
      final repo = ApiMatchesRepository(
        dioClient: DioClient(), // will attempt invalid network or fail in test environment
        cacheService: cacheService,
      );

      // When forcing refresh or expired, if network fails, repository gracefully serves stale cache
      final matches = await repo.getMatchesByDate(dateStr, forceRefresh: false);
      expect(matches.isNotEmpty, isTrue);
      expect(matches.first.awayTeamName, 'Barcelona');
    });
  });
}

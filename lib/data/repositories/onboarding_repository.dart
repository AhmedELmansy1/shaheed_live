import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/dio_client.dart';
import '../models/league_model.dart';
import '../models/team_model.dart';

/// Exception thrown when the catalog cannot be loaded (no network and no local cache).
class CatalogException implements Exception {
  final String message;
  const CatalogException(this.message);

  @override
  String toString() => message;
}

/// Abstract repository contract for fetching leagues and teams during onboarding and management.
abstract class OnboardingRepository {
  Future<List<LeagueModel>> getPopularLeagues({bool forceRefresh = false});
  Future<List<TeamModel>> getTeamsForLeagues(List<String> leagueIds, {bool forceRefresh = false});
  Future<List<TeamModel>> getTeamsByLeagueId(String leagueId, {bool forceRefresh = false});
  Future<List<TeamModel>> getPopularTeams({bool forceRefresh = false});
}

/// Local mock implementation of [OnboardingRepository] with realistic Arabic names.
class MockOnboardingRepository implements OnboardingRepository {
  static const List<LeagueModel> _mockLeagues = [
    LeagueModel(
      id: 'egy_1',
      name: 'الدوري المصري الممتاز',
      nameEn: 'Egyptian Premier League',
      country: 'مصر',
      isPopular: true,
      displayOrder: 1,
    ),
    LeagueModel(
      id: 'eng_1',
      name: 'الدوري الإنجليزي الممتاز',
      nameEn: 'Premier League',
      country: 'إنجلترا',
      isPopular: true,
      displayOrder: 2,
    ),
    LeagueModel(
      id: 'esp_1',
      name: 'الدوري الإسباني',
      nameEn: 'La Liga',
      country: 'إسبانيا',
      isPopular: true,
      displayOrder: 3,
    ),
    LeagueModel(
      id: 'ucl',
      name: 'دوري أبطال أوروبا',
      nameEn: 'UEFA Champions League',
      country: 'أوروبا',
      isPopular: true,
      displayOrder: 4,
    ),
    LeagueModel(
      id: 'ita_1',
      name: 'الدوري الإيطالي',
      nameEn: 'Serie A',
      country: 'إيطاليا',
    ),
    LeagueModel(
      id: 'sau_1',
      name: 'دوري روشن السعودي',
      nameEn: 'Saudi Pro League',
      country: 'السعودية',
    ),
    LeagueModel(
      id: 'caf_cl',
      name: 'دوري أبطال إفريقيا',
      nameEn: 'CAF Champions League',
      country: 'إفريقيا',
    ),
    LeagueModel(
      id: 'ger_1',
      name: 'الدوري الألماني',
      nameEn: 'Bundesliga',
      country: 'ألمانيا',
    ),
    LeagueModel(
      id: 'fra_1',
      name: 'الدوري الفرنسي',
      nameEn: 'Ligue 1',
      country: 'فرنسا',
    ),
    LeagueModel(
      id: 'mar_1',
      name: 'الدوري المغربي للمحترفين',
      nameEn: 'Botola Pro',
      country: 'المغرب',
    ),
    LeagueModel(
      id: 'alg_1',
      name: 'الرابطة الجزائرية المحترفة',
      nameEn: 'Algerian Ligue 1',
      country: 'الجزائر',
    ),
    LeagueModel(
      id: 'tun_1',
      name: 'الرابطة التونسية المحترفة',
      nameEn: 'Tunisian Ligue 1',
      country: 'تونس',
    ),
    LeagueModel(
      id: 'uae_1',
      name: 'دوري أدنوك للمحترفين',
      nameEn: 'UAE Pro League',
      country: 'الإمارات',
    ),
    LeagueModel(
      id: 'irq_1',
      name: 'دوري نجوم العراق',
      nameEn: 'Iraq Stars League',
      country: 'العراق',
    ),
    LeagueModel(
      id: 'uel',
      name: 'الدوري الأوروبي',
      nameEn: 'UEFA Europa League',
      country: 'أوروبا',
    ),
    LeagueModel(
      id: 'afcon',
      name: 'كأس الأمم الإفريقية',
      nameEn: 'Africa Cup of Nations',
      country: 'إفريقيا',
    ),
    LeagueModel(
      id: 'tur_1',
      name: 'الدوري التركي',
      nameEn: 'Süper Lig',
      country: 'تركيا',
    ),
    LeagueModel(
      id: 'bra_1',
      name: 'الدوري البرازيلي',
      nameEn: 'Brasileirão',
      country: 'البرازيل',
    ),
    LeagueModel(
      id: 'por_1',
      name: 'الدوري البرتغالي الممتاز',
      nameEn: 'Primeira Liga',
      country: 'البرتغال',
    ),
    LeagueModel(
      id: 'caf_cc',
      name: 'كأس الكونفيدرالية',
      nameEn: 'CAF Confederation Cup',
      country: 'إفريقيا',
    ),
  ];

  static const List<TeamModel> _mockTeams = [
    // الدوري المصري
    TeamModel(id: 'ahly', name: 'الأهلي', nameEn: 'Al Ahly', leagueId: 'egy_1'),
    TeamModel(
      id: 'zamalek',
      name: 'الزمالك',
      nameEn: 'Zamalek',
      leagueId: 'egy_1',
    ),
    TeamModel(
      id: 'pyramids',
      name: 'بيراميدز',
      nameEn: 'Pyramids FC',
      leagueId: 'egy_1',
    ),
    TeamModel(
      id: 'ismaily',
      name: 'الإسماعيلي',
      nameEn: 'Ismaily SC',
      leagueId: 'egy_1',
    ),
    TeamModel(
      id: 'ittihad_alex',
      name: 'الاتحاد السكندري',
      nameEn: 'Al Ittihad',
      leagueId: 'egy_1',
    ),
    TeamModel(
      id: 'masry',
      name: 'المصري البورسعيدي',
      nameEn: 'Al Masry',
      leagueId: 'egy_1',
    ),
    TeamModel(
      id: 'future',
      name: 'مودرن سبورت',
      nameEn: 'Modern Sport',
      leagueId: 'egy_1',
    ),
    TeamModel(
      id: 'smouha',
      name: 'سموحة',
      nameEn: 'Smouha SC',
      leagueId: 'egy_1',
    ),

    // الدوري الإنجليزي الممتاز & دوري أبطال أوروبا
    TeamModel(
      id: 'liverpool',
      name: 'ليفربول',
      nameEn: 'Liverpool',
      leagueId: 'eng_1',
    ),
    TeamModel(
      id: 'man_city',
      name: 'مانشستر سيتي',
      nameEn: 'Manchester City',
      leagueId: 'eng_1',
    ),
    TeamModel(
      id: 'arsenal',
      name: 'أرسنال',
      nameEn: 'Arsenal',
      leagueId: 'eng_1',
    ),
    TeamModel(
      id: 'man_utd',
      name: 'مانشستر يونايتد',
      nameEn: 'Manchester United',
      leagueId: 'eng_1',
    ),
    TeamModel(
      id: 'chelsea',
      name: 'تشيلسي',
      nameEn: 'Chelsea',
      leagueId: 'eng_1',
    ),
    TeamModel(
      id: 'tottenham',
      name: 'توتنهام هوتسبير',
      nameEn: 'Tottenham',
      leagueId: 'eng_1',
    ),
    TeamModel(
      id: 'aston_villa',
      name: 'أستون فيلا',
      nameEn: 'Aston Villa',
      leagueId: 'eng_1',
    ),
    TeamModel(
      id: 'newcastle',
      name: 'نيوكاسل يونايتد',
      nameEn: 'Newcastle',
      leagueId: 'eng_1',
    ),

    // الدوري الإسباني
    TeamModel(
      id: 'real_madrid',
      name: 'ريال مدريد',
      nameEn: 'Real Madrid',
      leagueId: 'esp_1',
    ),
    TeamModel(
      id: 'barcelona',
      name: 'برشلونة',
      nameEn: 'FC Barcelona',
      leagueId: 'esp_1',
    ),
    TeamModel(
      id: 'atletico_madrid',
      name: 'أتلتيكو مدريد',
      nameEn: 'Atletico Madrid',
      leagueId: 'esp_1',
    ),
    TeamModel(
      id: 'sevilla',
      name: 'إشبيلية',
      nameEn: 'Sevilla FC',
      leagueId: 'esp_1',
    ),
    TeamModel(
      id: 'villarreal',
      name: 'فياريال',
      nameEn: 'Villarreal',
      leagueId: 'esp_1',
    ),
    TeamModel(
      id: 'real_betis',
      name: 'ريال بيتيس',
      nameEn: 'Real Betis',
      leagueId: 'esp_1',
    ),
    TeamModel(
      id: 'athletic_bilbao',
      name: 'أتلتيك بيلباو',
      nameEn: 'Athletic Bilbao',
      leagueId: 'esp_1',
    ),
    TeamModel(
      id: 'girona',
      name: 'جيرونا',
      nameEn: 'Girona FC',
      leagueId: 'esp_1',
    ),

    // الدوري الإيطالي
    TeamModel(
      id: 'inter',
      name: 'إنتر ميلان',
      nameEn: 'Inter Milan',
      leagueId: 'ita_1',
    ),
    TeamModel(
      id: 'milan',
      name: 'إيه سي ميلان',
      nameEn: 'AC Milan',
      leagueId: 'ita_1',
    ),
    TeamModel(
      id: 'juventus',
      name: 'يوفنتوس',
      nameEn: 'Juventus',
      leagueId: 'ita_1',
    ),
    TeamModel(
      id: 'napoli',
      name: 'نابولي',
      nameEn: 'Napoli',
      leagueId: 'ita_1',
    ),
    TeamModel(id: 'roma', name: 'روما', nameEn: 'AS Roma', leagueId: 'ita_1'),
    TeamModel(id: 'lazio', name: 'لاتسيو', nameEn: 'Lazio', leagueId: 'ita_1'),
    TeamModel(
      id: 'atalanta',
      name: 'أتالانتا',
      nameEn: 'Atalanta',
      leagueId: 'ita_1',
    ),
    TeamModel(
      id: 'fiorentina',
      name: 'فيورنتينا',
      nameEn: 'Fiorentina',
      leagueId: 'ita_1',
    ),

    // دوري روشن السعودي
    TeamModel(
      id: 'hilal',
      name: 'الهلال',
      nameEn: 'Al Hilal',
      leagueId: 'sau_1',
    ),
    TeamModel(
      id: 'nassr',
      name: 'النصر',
      nameEn: 'Al Nassr',
      leagueId: 'sau_1',
    ),
    TeamModel(
      id: 'ittihad_sau',
      name: 'الاتحاد',
      nameEn: 'Al Ittihad',
      leagueId: 'sau_1',
    ),
    TeamModel(
      id: 'ahli_sau',
      name: 'الأهلي السعودي',
      nameEn: 'Al Ahli Saudi',
      leagueId: 'sau_1',
    ),
    TeamModel(
      id: 'shabab',
      name: 'الشباب',
      nameEn: 'Al Shabab',
      leagueId: 'sau_1',
    ),
    TeamModel(
      id: 'ettifaq',
      name: 'الاتفاق',
      nameEn: 'Al Ettifaq',
      leagueId: 'sau_1',
    ),

    // دوري أبطال إفريقيا / المغرب / تونس
    TeamModel(
      id: 'wydad',
      name: 'الوداد الرياضي',
      nameEn: 'Wydad AC',
      leagueId: 'caf_cl',
    ),
    TeamModel(
      id: 'raja',
      name: 'الرجاء الرياضي',
      nameEn: 'Raja CA',
      leagueId: 'caf_cl',
    ),
    TeamModel(
      id: 'esperance',
      name: 'الترجي التونسي',
      nameEn: 'Esperance ST',
      leagueId: 'caf_cl',
    ),
    TeamModel(
      id: 'sundowns',
      name: 'ماميلودي سان داونز',
      nameEn: 'Mamelodi Sundowns',
      leagueId: 'caf_cl',
    ),

    // الدوري الألماني
    TeamModel(
      id: 'bayern',
      name: 'بايرن ميونخ',
      nameEn: 'Bayern Munich',
      leagueId: 'ger_1',
    ),
    TeamModel(
      id: 'dortmund',
      name: 'بروسيا دورتموند',
      nameEn: 'Borussia Dortmund',
      leagueId: 'ger_1',
    ),
    TeamModel(
      id: 'leverkusen',
      name: 'باير ليفركوزن',
      nameEn: 'Bayer Leverkusen',
      leagueId: 'ger_1',
    ),

    // الدوري الفرنسي
    TeamModel(
      id: 'psg',
      name: 'باريس سان جيرمان',
      nameEn: 'Paris Saint-Germain',
      leagueId: 'fra_1',
    ),
    TeamModel(
      id: 'marseille',
      name: 'أولمبيك مارسيليا',
      nameEn: 'Olympique Marseille',
      leagueId: 'fra_1',
    ),
  ];

  @override
  Future<List<LeagueModel>> getPopularLeagues({bool forceRefresh = false}) async {
    return _mockLeagues;
  }

  @override
  Future<List<TeamModel>> getTeamsForLeagues(List<String> leagueIds, {bool forceRefresh = false}) async {
    if (leagueIds.isEmpty) return _mockTeams;
    return _mockTeams
        .where((team) => leagueIds.contains(team.leagueId))
        .toList();
  }

  @override
  Future<List<TeamModel>> getTeamsByLeagueId(String leagueId, {bool forceRefresh = false}) async {
    return _mockTeams.where((team) => team.leagueId == leagueId).toList();
  }

  @override
  Future<List<TeamModel>> getPopularTeams({bool forceRefresh = false}) async => _mockTeams;

  List<TeamModel> getPopularTeamsSync() => _mockTeams;
}

/// Production API-backed implementation of [OnboardingRepository] with persistent caching.
class ApiOnboardingRepository implements OnboardingRepository {
  final DioClient dioClient;
  final SharedPreferences? prefs;

  static const String _leaguesCacheKey = 'cached_catalog_leagues_v1';
  static const String _teamsCacheKey = 'cached_catalog_teams_v1';

  ApiOnboardingRepository({
    required this.dioClient,
    this.prefs,
  });

  Future<SharedPreferences> _getPrefs() async => prefs ?? await SharedPreferences.getInstance();

  @override
  Future<List<LeagueModel>> getPopularLeagues({bool forceRefresh = false}) async {
    final p = await _getPrefs();

    // 1. Check local cache if not forcing refresh
    if (!forceRefresh) {
      final cachedJson = p.getString(_leaguesCacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJson);
          if (decoded is List && decoded.isNotEmpty) {
            final list = decoded
                .whereType<Map<String, dynamic>>()
                .map((m) => LeagueModel.fromMap(m))
                .toList();
            if (list.isNotEmpty) return _sortLeagues(list);
          }
        } catch (e) {
          debugPrint('[ApiOnboardingRepository] Error parsing cached leagues: $e');
        }
      }
    }

    // 2. Fetch fresh from API
    try {
      final response = await dioClient.get(
        queryParameters: {'type': 'leagues'},
      );

      final leagues = LeagueModel.fromListOrMap(response);

      if (leagues.isNotEmpty) {
        // Cache locally for offline resilience
        final serialized = jsonEncode(leagues.map((l) => l.toMap()).toList());
        await p.setString(_leaguesCacheKey, serialized);
        return _sortLeagues(leagues);
      }
    } catch (e) {
      debugPrint('[ApiOnboardingRepository] Remote fetch error for leagues: $e');
      // If network failed, try fallback cache again
      final cachedJson = p.getString(_leaguesCacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJson);
          if (decoded is List) {
            final list = decoded
                .whereType<Map<String, dynamic>>()
                .map((m) => LeagueModel.fromMap(m))
                .toList();
            if (list.isNotEmpty) return _sortLeagues(list);
          }
        } catch (_) {}
      }
      throw const CatalogException('تعذر تحميل الدوريات. يرجى التحقق من الاتصال بالإنترنت والمحاولة مجدداً.');
    }

    throw const CatalogException('لا توجد بيانات متاحة للدوريات حالياً.');
  }

  @override
  Future<List<TeamModel>> getTeamsByLeagueId(String leagueId, {bool forceRefresh = false}) async {
    final p = await _getPrefs();
    final cacheKey = 'cached_league_teams_${leagueId}_v1';

    // 1. Check persistent disk cache if not forcing refresh
    if (!forceRefresh) {
      final cachedJson = p.getString(cacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJson);
          if (decoded is List && decoded.isNotEmpty) {
            final list = decoded
                .whereType<Map<String, dynamic>>()
                .map((m) => TeamModel.fromMap(m))
                .toList();
            if (list.isNotEmpty) return list;
          }
        } catch (e) {
          debugPrint('[ApiOnboardingRepository] Error parsing cached league teams ($leagueId): $e');
        }
      }
    }

    // 2. Fetch directly with type=teams&league_id=<id>
    try {
      final response = await dioClient.get(
        queryParameters: {'type': 'teams', 'league_id': leagueId},
      );

      final teams = TeamModel.fromListOrMap(response);

      if (teams.isNotEmpty) {
        final serialized = jsonEncode(teams.map((t) => t.toMap()).toList());
        await p.setString(cacheKey, serialized);
        return teams;
      }
    } catch (e) {
      debugPrint('[ApiOnboardingRepository] Error fetching teams for league $leagueId: $e');
      // Fallback: check cache again in case of network error
      final cachedJson = p.getString(cacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJson);
          if (decoded is List) {
            final list = decoded
                .whereType<Map<String, dynamic>>()
                .map((m) => TeamModel.fromMap(m))
                .toList();
            if (list.isNotEmpty) return list;
          }
        } catch (_) {}
      }
      rethrow;
    }

    return [];
  }

  @override
  Future<List<TeamModel>> getTeamsForLeagues(List<String> leagueIds, {bool forceRefresh = false}) async {
    if (leagueIds.isEmpty) return _getAllTeams(forceRefresh: forceRefresh);

    final List<TeamModel> combined = [];
    final idSet = leagueIds.map((id) => id.trim()).toSet();

    // Fetch in parallel for each league
    final futures = idSet.map((id) async {
      try {
        return await getTeamsByLeagueId(id, forceRefresh: forceRefresh);
      } catch (_) {
        return <TeamModel>[];
      }
    });

    final results = await Future.wait(futures);
    for (final list in results) {
      combined.addAll(list);
    }

    if (combined.isNotEmpty) {
      return combined;
    }

    // Fallback to global catalog if per-league failed
    final allTeams = await _getAllTeams(forceRefresh: forceRefresh);
    return allTeams.where((t) => idSet.contains(t.leagueId)).toList();
  }

  @override
  Future<List<TeamModel>> getPopularTeams({bool forceRefresh = false}) async {
    return _getAllTeams(forceRefresh: forceRefresh);
  }

  Future<List<TeamModel>> _getAllTeams({bool forceRefresh = false}) async {
    final p = await _getPrefs();

    if (!forceRefresh) {
      final cachedJson = p.getString(_teamsCacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJson);
          if (decoded is List && decoded.isNotEmpty) {
            final list = decoded
                .whereType<Map<String, dynamic>>()
                .map((m) => TeamModel.fromMap(m))
                .toList();
            if (list.isNotEmpty) return list;
          }
        } catch (e) {
          debugPrint('[ApiOnboardingRepository] Error parsing cached teams: $e');
        }
      }
    }

    try {
      final response = await dioClient.get(
        queryParameters: {'type': 'teams'},
      );

      List<TeamModel> teams = [];
      if (response is Map<String, dynamic>) {
        final list = response['teams'] ?? response['data'];
        if (list is List) {
          teams = list
              .whereType<Map<String, dynamic>>()
              .map((m) => TeamModel.fromMap(m))
              .toList();
        }
      } else if (response is List) {
        teams = response
            .whereType<Map<String, dynamic>>()
            .map((m) => TeamModel.fromMap(m))
            .toList();
      }

      if (teams.isNotEmpty) {
        final serialized = jsonEncode(teams.map((t) => t.toMap()).toList());
        await p.setString(_teamsCacheKey, serialized);
        return teams;
      }
    } catch (e) {
      debugPrint('[ApiOnboardingRepository] Remote fetch error for teams: $e');
      final cachedJson = p.getString(_teamsCacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJson);
          if (decoded is List) {
            final list = decoded
                .whereType<Map<String, dynamic>>()
                .map((m) => TeamModel.fromMap(m))
                .toList();
            if (list.isNotEmpty) return list;
          }
        } catch (_) {}
      }
      throw const CatalogException('تعذر تحميل الفرق. يرجى التحقق من الاتصال بالإنترنت والمحاولة مجدداً.');
    }

    return [];
  }

  List<LeagueModel> _sortLeagues(List<LeagueModel> list) {
    final sorted = List<LeagueModel>.from(list);
    sorted.sort((a, b) {
      if (a.isPopular && !b.isPopular) return -1;
      if (!a.isPopular && b.isPopular) return 1;
      if (a.displayOrder != b.displayOrder) {
        return a.displayOrder.compareTo(b.displayOrder);
      }
      return a.name.compareTo(b.name);
    });
    return sorted;
  }
}

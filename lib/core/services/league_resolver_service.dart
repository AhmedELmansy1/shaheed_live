import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/league_model.dart';
import '../../data/models/match_model.dart';

/// Mapping and normalization layer that resolves API championship names and IDs
/// (including stage suffixes like "دوري أبطال أفريقيا | الأدوار الإقصائية")
/// to canonical onboarding league IDs (e.g. 'caf_cl', 'fra_1', 'mar_1').
class LeagueResolverService {
  static const String _storageKey = 'api_champ_id_to_league_slug';

  /// Pre-seeded mappings for verified championships from real API responses.
  static const Map<String, String> _seededChampToLeague = {
    '1985': 'fra_1', // الدوري الفرنسي
    '2606': 'ger_1', // الدوري الألماني
    '3734': 'ita_1', // الدوري الإيطالي
    '6682': 'tur_1', // الدوري التركي
    '40224': 'bra_1', // الدوري البرازيلي
    '41135': 'mar_1', // البطولة الوطنية المغربية
    '44444': 'caf_cc', // كأس الكونفيدرالية | الأدوار الإقصائية
    '54416': 'por_1', // الدوري البرتغالي الممتاز
    '57146': 'alg_1', // الرابطة المحترفة الجزائرية
    '97533': 'caf_cl', // دوري أبطال أفريقيا | الأدوار الإقصائية
    '99376': 'irq_1', // دوري نجوم العراق
    '1933': 'esp_1', // الدوري الإسباني
    '6811': 'eng_1', // الدوري الإنجليزي
    '6047': 'egy_1', // الدوري المصري
    '1928': 'sau_1', // دوري روشن السعودي
    '1929': 'ucl', // دوري أبطال أوروبا
    '1930': 'uel', // الدوري الأوروبي
  };

  static Map<String, String> get seededChampToLeague => _seededChampToLeague;

  static final Map<String, String> _memoryCache = Map.from(_seededChampToLeague);
  static bool _hasLoadedFromPrefs = false;

  /// Loads persisted mappings from SharedPreferences.
  static Future<void> init() async {
    if (_hasLoadedFromPrefs) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          _memoryCache[entry.key] = entry.value.toString();
        }
      }
      _hasLoadedFromPrefs = true;
    } catch (e) {
      debugPrint('[LeagueResolver] Error loading cached league mappings: $e');
    }
  }

  /// Normalises league names according to rule:
  /// 1. Cuts everything after '|' (removes stage suffixes)
  /// 2. Strips Arabic diacritics / tashkeel
  /// 3. Unifies Alefs: أ, إ, آ, ٱ -> ا
  /// 4. Unifies ى -> ي
  /// 5. Unifies ة -> ه
  /// 6. Strips punctuation and collapses extra spaces
  static String normalizeLeagueName(String name) {
    if (name.isEmpty) return '';
    // 1. Cut everything after '|'
    String s = name.contains('|') ? name.split('|').first : name;

    // 2. Strip diacritics / tashkeel
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

    // 3. Unify Alefs: أ, إ, آ, ٱ -> ا
    s = s.replaceAll(RegExp(r'[أإآٱ]'), 'ا');

    // 4. Unify ى -> ي
    s = s.replaceAll('ى', 'ي');

    // 5. Unify ة -> ه
    s = s.replaceAll('ة', 'ه');

    // 6. Strip punctuation and collapse whitespace
    s = s.replaceAll(RegExp(r'[^\w\s\u0621-\u064A]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

    return s;
  }

  /// Resolves an API championship to its canonical onboarding league ID.
  static String? resolveToOnboardingLeagueId({
    dynamic champId,
    required String champTitle,
    required List<LeagueModel> allLeagues,
  }) {
    final idStr = champId?.toString().trim() ?? '';
    // 1. Fast path: check memory cache / seeded IDs
    if (idStr.isNotEmpty && _memoryCache.containsKey(idStr)) {
      return _memoryCache[idStr];
    }

    final normTitle = normalizeLeagueName(champTitle);
    if (normTitle.isEmpty) return null;

    final titleWords = normTitle.split(' ').where((w) => w.isNotEmpty).toSet();

    // 2. Match against allLeagues by normalized name or word set
    for (final league in allLeagues) {
      final normLeagueName = normalizeLeagueName(league.name);
      if (normLeagueName.isEmpty) continue;

      // Exact match after cutting stage suffix and normalizing
      if (normTitle == normLeagueName) {
        _cacheAndPersist(idStr, league.id);
        return league.id;
      }

      // Word set equality (e.g. 'الرابطة المحترفة الجزائرية' vs 'الرابطة الجزائرية المحترفة')
      final leagueWords =
          normLeagueName.split(' ').where((w) => w.isNotEmpty).toSet();
      if (titleWords.length >= 2 &&
          leagueWords.length >= 2 &&
          titleWords.difference(leagueWords).isEmpty &&
          leagueWords.difference(titleWords).isEmpty) {
        _cacheAndPersist(idStr, league.id);
        return league.id;
      }

      // Substring containment if sufficiently specific
      if ((normTitle.length >= 6 && normLeagueName.contains(normTitle)) ||
          (normLeagueName.length >= 6 && normTitle.contains(normLeagueName))) {
        _cacheAndPersist(idStr, league.id);
        return league.id;
      }
    }

    // 3. Known country/competition keyword fallback
    for (final league in allLeagues) {
      if (league.id == 'mar_1' &&
          (normTitle.contains('المغربي') ||
              normTitle.contains('المغربيه') ||
              normTitle.contains('المغرب'))) {
        _cacheAndPersist(idStr, league.id);
        return league.id;
      }
      if (league.id == 'caf_cc' &&
          (normTitle.contains('الكونفيدراليه') ||
              normTitle.contains('الكونفدراليه'))) {
        _cacheAndPersist(idStr, league.id);
        return league.id;
      }
      if (league.id == 'caf_cl' &&
          (normTitle.contains('ابطال افريقيا') ||
              (normTitle.contains('ابطال') && normTitle.contains('افريقيا')))) {
        _cacheAndPersist(idStr, league.id);
        return league.id;
      }
    }

    return null;
  }

  /// Automatically registers mappings from a list of matches.
  static void updateMappingsFromMatches(
    List<MatchModel> matches,
    List<LeagueModel> allLeagues,
  ) {
    if (matches.isEmpty || allLeagues.isEmpty) return;
    for (final match in matches) {
      final champId = match.championship.id;
      final champTitle = match.championship.title;
      if (champId != null && champTitle.trim().isNotEmpty) {
        resolveToOnboardingLeagueId(
          champId: champId,
          champTitle: champTitle,
          allLeagues: allLeagues,
        );
      }
    }
  }

  static void _cacheAndPersist(String champId, String leagueId) {
    if (champId.isEmpty) return;
    _memoryCache[champId] = leagueId;
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageKey, jsonEncode(_memoryCache));
      } catch (e) {
        debugPrint('[LeagueResolver] Error saving league mapping: $e');
      }
    });
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/league_resolver_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/league_model.dart';
import '../../data/models/match_model.dart';
import '../../data/models/standings_model.dart';
import '../../data/repositories/matches_repository.dart';
import '../home/providers/matches_provider.dart';
import '../match_details/providers/match_details_providers.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/match_card.dart';
import '../widgets/matches_skeleton.dart';

/// Range selector for league matches date window.
enum LeagueMatchesRange {
  /// Today through the next 30 days (preferred default).
  upcoming,

  /// Previous 30 days for completed match results.
  past,

  /// Both previous 30 days and next 30 days (full 60-day window).
  all,
}

/// State notifier for selecting the active date range filter for a given league.
class LeagueMatchesRangeNotifier extends Notifier<LeagueMatchesRange> {
  @override
  LeagueMatchesRange build() => LeagueMatchesRange.upcoming;

  void setRange(LeagueMatchesRange range) {
    state = range;
  }
}

/// State provider for selecting the active date range filter for a given league.
final leagueMatchesRangeProvider =
    NotifierProvider.family<LeagueMatchesRangeNotifier, LeagueMatchesRange, String>((arg) {
  return LeagueMatchesRangeNotifier();
});

/// Computes the list of YYYY-MM-DD date strings for the requested [range].
List<String> getLeagueDateRangeStrings(LeagueMatchesRange range) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dates = <String>[];

  switch (range) {
    case LeagueMatchesRange.upcoming:
      // Today through the next 30 days (31 dates)
      for (var i = 0; i <= 30; i++) {
        final d = today.add(Duration(days: i));
        dates.add(DateFormatter.toApiDateString(d));
      }
      break;
    case LeagueMatchesRange.past:
      // Previous 30 days up to yesterday (30 dates)
      for (var i = 30; i >= 1; i--) {
        final d = today.subtract(Duration(days: i));
        dates.add(DateFormatter.toApiDateString(d));
      }
      break;
    case LeagueMatchesRange.all:
      // Past 30 days through next 30 days (61 dates)
      for (var i = 30; i >= 1; i--) {
        final d = today.subtract(Duration(days: i));
        dates.add(DateFormatter.toApiDateString(d));
      }
      for (var i = 0; i <= 30; i++) {
        final d = today.add(Duration(days: i));
        dates.add(DateFormatter.toApiDateString(d));
      }
      break;
  }
  return dates;
}

/// Fetches matches across [dateStrings] using [repo] with a controlled concurrency limit.
Future<List<MatchModel>> fetchMatchesWithConcurrencyLimit({
  required MatchesRepository repo,
  required List<String> dateStrings,
  int concurrencyLimit = 5,
}) async {
  if (dateStrings.isEmpty) return const [];

  final results = List<List<MatchModel>?>.filled(dateStrings.length, null);
  var currentIndex = 0;
  var successCount = 0;
  Object? lastError;
  StackTrace? lastStackTrace;

  Future<void> worker() async {
    while (true) {
      final index = currentIndex++;
      if (index >= dateStrings.length) break;
      final dateStr = dateStrings[index];

      try {
        final matches = await repo.getMatchesByDate(dateStr);
        results[index] = matches;
        successCount++;
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;
        // Non-fatal individual day error; record null and continue collecting remaining dates
        results[index] = null;
      }
    }
  }

  final poolSize = concurrencyLimit.clamp(1, dateStrings.length);
  final workers = List.generate(poolSize, (_) => worker());
  await Future.wait(workers);

  if (successCount == 0 && lastError != null && dateStrings.isNotEmpty) {
    Error.throwWithStackTrace(lastError!, lastStackTrace ?? StackTrace.current);
  }

  final aggregated = <MatchModel>[];
  for (final list in results) {
    if (list != null && list.isNotEmpty) {
      aggregated.addAll(list);
    }
  }
  return aggregated;
}

/// Provider that aggregates matches across a 30-day date range (preferred: today through next 30 days,
/// with optional previous 30 days for completed results) for a given [leagueId].
final leagueMatchesProvider =
    FutureProvider.family<List<MatchModel>, String>((ref, leagueId) async {
  final repo = ref.watch(matchesRepositoryProvider);
  final range = ref.watch(leagueMatchesRangeProvider(leagueId));
  final allLeagues = ref.read(onboardingProvider).leagues;

  final dateStrings = getLeagueDateRangeStrings(range);

  // Controlled concurrent requests with concurrency limit = 5
  final rawMatches = await fetchMatchesWithConcurrencyLimit(
    repo: repo,
    dateStrings: dateStrings,
    concurrencyLimit: 5,
  );

  // Deduplicate by match ID
  final seenIds = <String>{};
  final uniqueMatches = <MatchModel>[];
  for (final m in rawMatches) {
    if (m.id.isNotEmpty && seenIds.add(m.id)) {
      uniqueMatches.add(m);
    }
  }

  // Filter matches belonging to this league
  final leagueMatches = uniqueMatches.where((m) {
    final resolvedId = LeagueResolverService.resolveToOnboardingLeagueId(
      champId: m.championship.id,
      champTitle: m.championship.title,
      allLeagues: allLeagues,
    );
    if (resolvedId == leagueId) return true;
    return isFavoriteLeagueMatch(m, [leagueId], allLeagues);
  }).toList();

  // Sort chronologically
  leagueMatches.sort((a, b) {
    final aTime = a.kickoffDateTime;
    final bTime = b.kickoffDateTime;
    if (aTime != null && bTime != null) {
      return aTime.compareTo(bTime);
    }
    if (aTime != null) return -1;
    if (bTime != null) return 1;
    final aStr = '${a.matchDate ?? ''} ${a.matchTime ?? ''}';
    final bStr = '${b.matchDate ?? ''} ${b.matchTime ?? ''}';
    return aStr.compareTo(bStr);
  });

  return leagueMatches;
});

/// Provider resolving the standings for a league.
/// Finds any recent match in this league and queries `matchStandingsProvider`.
final leagueStandingsProvider =
    FutureProvider.family<List<StandingRowModel>, String>((ref, leagueId) async {
  final matchesAsync = ref.watch(leagueMatchesProvider(leagueId));
  final matches = matchesAsync.value ?? [];

  // 1. Try to find an active match ID from recent matches in this league
  for (final m in matches) {
    final matchId = int.tryParse(m.id);
    if (matchId != null && matchId > 0) {
      final standings = await ref.read(matchStandingsProvider(matchId).future);
      if (standings.isNotEmpty) {
        return standings;
      }
    }
  }

  // 2. Fallback: Check if this league has a known championship ID in seeded mappings
  final source = ref.read(ysscoresSourceProvider);
  final onboardingState = ref.read(onboardingProvider);
  final league = onboardingState.leagues.where((l) => l.id == leagueId).firstOrNull;

  if (league != null) {
    // If championship has a known numeric match code or ID
    for (final champEntry in LeagueResolverService.seededChampToLeague.entries) {
      if (champEntry.value == leagueId) {
        final sampleId = int.tryParse(champEntry.key);
        if (sampleId != null) {
          try {
            final raw = await source.rawLeagueRank(sampleId);
            final rows = StandingRowModel.fromResponse(raw);
            if (rows.isNotEmpty) return rows;
          } catch (_) {}
        }
      }
    }
  }

  return [];
});

/// Comprehensive League Details Screen presenting:
/// 1. League Header with logo, titles, country, and favorite toggle.
/// 2. Tabs:
///    - المباريات (Recent, today, and upcoming fixtures for this league).
///    - الترتيب (Responsive League Standings Table with followed club highlights).
///    - معلومات البطولة (League details and management).
class LeagueDetailsScreen extends ConsumerStatefulWidget {
  final String leagueId;
  final LeagueModel? initialLeague;

  const LeagueDetailsScreen({
    super.key,
    required this.leagueId,
    this.initialLeague,
  });

  @override
  ConsumerState<LeagueDetailsScreen> createState() => _LeagueDetailsScreenState();
}

class _LeagueDetailsScreenState extends ConsumerState<LeagueDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final isLight = AppColors.isLight(context);
    final bg = AppColors.backgroundOf(context);
    final surface = AppColors.surfaceOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final textMuted = AppColors.textMutedOf(context);

    // Resolve league model
    final league = widget.initialLeague ??
        onboardingState.leagues.where((l) => l.id == widget.leagueId).firstOrNull ??
        LeagueModel(
          id: widget.leagueId,
          name: widget.leagueId,
          nameEn: widget.leagueId,
          country: '',
        );

    final isFollowed = onboardingState.selectedLeagueIds.contains(league.id);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          league.name,
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFollowed ? Icons.star_rounded : Icons.star_border_rounded,
              color: isFollowed ? AppColors.gold : textMuted,
              size: 26,
            ),
            tooltip: isFollowed ? 'إلغاء متابعة البطولة' : 'متابعة البطولة',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(onboardingProvider.notifier).toggleLeagueSelection(league.id);
            },
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildLeagueHeader(context, league, isFollowed, isLight),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: 'المباريات', icon: Icon(Icons.sports_soccer_rounded, size: 20)),
                    Tab(text: 'الترتيب', icon: Icon(Icons.leaderboard_rounded, size: 20)),
                    Tab(text: 'معلومات البطولة', icon: Icon(Icons.info_outline_rounded, size: 20)),
                  ],
                ),
                color: surface,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMatchesTab(context, league.id),
            _buildStandingsTab(context, league.id),
            _buildInfoTab(context, league, isFollowed),
          ],
        ),
      ),
    );
  }

  Widget _buildLeagueHeader(
    BuildContext context,
    LeagueModel league,
    bool isFollowed,
    bool isLight,
  ) {
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Container(
      color: surface,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isLight ? AppColors.lightSurfaceHigh : AppColors.darkSurfaceHigh,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: border, width: 1),
            ),
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: league.logoUrl != null && league.logoUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: league.logoUrl!,
                    fit: BoxFit.contain,
                    memCacheWidth: 80,
                    memCacheHeight: 80,
                    maxWidthDiskCache: 120,
                    maxHeightDiskCache: 120,
                    errorWidget: (_, _, _) => const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.gold,
                      size: 28,
                    ),
                  )
                : const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.gold,
                    size: 28,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  league.name,
                  style: AppTypography.titleLarge(color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${league.nameEn}${league.country.isNotEmpty ? ' • ${league.country}' : ''}',
                  style: AppTypography.bodySmall(color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: isFollowed
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : (isLight ? AppColors.lightSurfaceHigh : AppColors.darkSurfaceHigh),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(
                color: isFollowed ? AppColors.primary : border,
                width: 1,
              ),
            ),
            child: Text(
              isFollowed ? 'مفضلة ⭐' : 'غير مفضلة',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isFollowed ? AppColors.primary : textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesTab(BuildContext context, String leagueId) {
    final range = ref.watch(leagueMatchesRangeProvider(leagueId));
    final matchesAsync = ref.watch(leagueMatchesProvider(leagueId));

    return Column(
      children: [
        _buildMatchesRangeFilterBar(context, leagueId, range),
        Expanded(
          child: matchesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, _) => SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppEmptyState(
                    type: EmptyStateType.error,
                    title: 'حدث خطأ أثناء تحميل مباريات البطولة',
                    subtitle: err.toString(),
                    action: AppButton(
                      label: 'إعادة المحاولة',
                      icon: Icons.refresh_rounded,
                      onPressed: () => ref.invalidate(leagueMatchesProvider(leagueId)),
                    ),
                  ),
                ),
              ),
            ),
            data: (matches) {
              if (matches.isEmpty) {
                final subtitle = switch (range) {
                  LeagueMatchesRange.upcoming =>
                    'لم يتم العثور على مباريات قادمة خلال الـ 30 يوماً القادمة لهذه البطولة',
                  LeagueMatchesRange.past =>
                    'لم يتم العثور على نتائج مسجلة خلال الـ 30 يوماً السابقة لهذه البطولة',
                  LeagueMatchesRange.all =>
                    'لا توجد مباريات مسجلة حالياً لهذه البطولة في نطاق الـ 60 يوماً',
                };

                return SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: AppEmptyState(
                        type: EmptyStateType.calendar,
                        title: 'لا توجد مباريات مسجلة حالياً',
                        subtitle: subtitle,
                        action: AppButton(
                          label: 'تحديث البيانات',
                          icon: Icons.refresh_rounded,
                          onPressed: () => ref.invalidate(leagueMatchesProvider(leagueId)),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  return MatchCard(match: match);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMatchesRangeFilterBar(
    BuildContext context,
    String leagueId,
    LeagueMatchesRange currentRange,
  ) {
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);

    Widget buildChip({
      required String label,
      required IconData icon,
      required LeagueMatchesRange range,
    }) {
      final isSelected = currentRange == range;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: () {
              if (!isSelected) {
                HapticFeedback.selectionClick();
                ref.read(leagueMatchesRangeProvider(leagueId).notifier).setRange(range);
              }
            },
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : surface,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: isSelected ? AppColors.primary : border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: isSelected ? AppColors.primary : AppColors.textSecondaryOf(context),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textSecondaryOf(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          buildChip(
            label: 'القادمة (30 يوم)',
            icon: Icons.event_available_rounded,
            range: LeagueMatchesRange.upcoming,
          ),
          buildChip(
            label: 'السابقة (30 يوم)',
            icon: Icons.history_rounded,
            range: LeagueMatchesRange.past,
          ),
          buildChip(
            label: 'الكل (60 يوم)',
            icon: Icons.all_inclusive_rounded,
            range: LeagueMatchesRange.all,
          ),
        ],
      ),
    );
  }

  Widget _buildStandingsTab(BuildContext context, String leagueId) {
    final standingsAsync = ref.watch(leagueStandingsProvider(leagueId));
    final onboardingState = ref.watch(onboardingProvider);
    final followedTeamIds = onboardingState.selectedTeamIds.toSet();

    return standingsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: MatchesSkeleton(),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppEmptyState(
            type: EmptyStateType.error,
            title: 'حدث خطأ أثناء تحميل جدول الترتيب',
            subtitle: err.toString(),
            action: AppButton(
              label: 'إعادة المحاولة',
              icon: Icons.refresh_rounded,
              onPressed: () => ref.invalidate(leagueStandingsProvider(leagueId)),
            ),
          ),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppEmptyState(
                type: EmptyStateType.soccer,
                title: 'لا يتوفر جدول ترتيب لهذه البطولة حالياً',
                subtitle: 'يتم تحديث جدول الترتيب تلقائياً فور توفر بيانات الجولات الرسمية',
                action: AppButton(
                  label: 'إعادة الفحص',
                  icon: Icons.refresh_rounded,
                  onPressed: () => ref.invalidate(leagueStandingsProvider(leagueId)),
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Responsive Scrollable Table Container
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 420),
                  child: Column(
                    children: [
                      _buildStandingsHeader(context),
                      const SizedBox(height: 6),
                      ...rows.map((row) {
                        final isFollowedTeam = followedTeamIds.contains(row.teamId.toString());
                        return _buildStandingsRow(context, row, isFollowedTeam);
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildStandingsLegend(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStandingsHeader(BuildContext context) {
    final surface = AppColors.surfaceOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Container(
      width: 440,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#',
              style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(
              'الفريق',
              style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          _buildHeaderCol('لعب', textSecondary),
          _buildHeaderCol('ف', textSecondary),
          _buildHeaderCol('ت', textSecondary),
          _buildHeaderCol('خ', textSecondary),
          _buildHeaderCol('+/-', textSecondary),
          _buildHeaderCol('نقاط', textSecondary, isBold: true),
        ],
      ),
    );
  }

  Widget _buildHeaderCol(String label, Color color, {bool isBold = false}) {
    return SizedBox(
      width: 32,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isBold ? AppColors.primary : color,
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStandingsRow(BuildContext context, StandingRowModel row, bool isFollowedTeam) {
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final primary = AppColors.primaryOf(context);

    // Subtle qualification / relegation zone indicators (NO GREEN)
    Color? zoneColor;
    if (row.rank == 1) {
      zoneColor = primary;
    } else if (row.rank <= 4) {
      zoneColor = Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF6C85F5)
          : const Color(0xFF3B5BDB);
    } else if (row.rank >= 18) {
      zoneColor = const Color(0xFFD9480F);
    }

    return Container(
      width: 440,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isFollowedTeam
            ? primary.withValues(alpha: 0.10)
            : surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: isFollowedTeam
            ? Border.all(color: primary.withValues(alpha: 0.45), width: 1.0)
            : Border.all(color: border, width: 0.6),
      ),
      child: Row(
        children: [
          // Rank + Color Badge
          SizedBox(
            width: 28,
            child: Row(
              children: [
                if (zoneColor != null)
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: zoneColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  )
                else
                  const SizedBox(width: 3),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    DateFormatter.toArabicNumerals('${row.rank}'),
                    style: TextStyle(
                      color: isFollowedTeam ? primary : textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Team Crest + Title
          Expanded(
            flex: 4,
            child: Row(
              children: [
                if (row.teamLogo != null && row.teamLogo!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: row.teamLogo!,
                      width: 20,
                      height: 20,
                      memCacheWidth: 48,
                      memCacheHeight: 48,
                      maxWidthDiskCache: 64,
                      maxHeightDiskCache: 64,
                      errorWidget: (_, _, _) => const Icon(
                        Icons.sports_soccer,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.sports_soccer, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    row.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isFollowedTeam ? AppColors.primary : textPrimary,
                      fontSize: 12,
                      fontWeight: isFollowedTeam ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (isFollowedTeam)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                  ),
              ],
            ),
          ),
          // Stats
          _buildStatCell(row.played, textSecondary),
          _buildStatCell(row.won, textSecondary),
          _buildStatCell(row.drawn, textSecondary),
          _buildStatCell(row.lost, textSecondary),
          _buildStatCell(row.goalDiff, textSecondary),
          _buildStatCell(row.points, isFollowedTeam ? AppColors.primary : textPrimary, isBold: true),
        ],
      ),
    );
  }

  Widget _buildStatCell(int val, Color color, {bool isBold = false}) {
    return SizedBox(
      width: 32,
      child: Text(
        DateFormatter.toArabicNumerals('$val'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStandingsLegend(BuildContext context) {
    final textSecondary = AppColors.textSecondaryOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text(
        'المختصرات: لعب (عدد المباريات) • ف (فوز) • ت (تعادل) • خ (خسارة) • +/- (فارق الأهداف) • نقاط',
        style: TextStyle(fontSize: 11, color: textSecondary, height: 1.4),
      ),
    );
  }

  Widget _buildInfoTab(BuildContext context, LeagueModel league, bool isFollowed) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('بيانات البطولة', style: AppTypography.titleMedium(color: textPrimary)),
              const SizedBox(height: AppSpacing.md),
              _buildInfoRow('اسم البطولة (بالعربية)', league.name, textPrimary, textSecondary),
              const Divider(height: 20),
              _buildInfoRow('الاسم الرسمي (بالإنجليزية)', league.nameEn, textPrimary, textSecondary),
              const Divider(height: 20),
              _buildInfoRow('الدولة / المنطقة', league.country.isNotEmpty ? league.country : 'دولي', textPrimary, textSecondary),
              const Divider(height: 20),
              _buildInfoRow('رمز البطولة التعريفي', league.id, textPrimary, textSecondary),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تفضيلات المتابعة', style: AppTypography.titleMedium(color: textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'عند متابعة البطولة، ستظهر مبارياتها في أعلى شاشة المباريات الرئيسية وتُعطى الأولوية في العرض.',
                style: AppTypography.caption(color: textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: isFollowed ? 'إلغاء متابعة البطولة' : 'متابعة هذه البطولة ⭐',
                  icon: isFollowed ? Icons.star_border_rounded : Icons.star_rounded,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(onboardingProvider.notifier).toggleLeagueSelection(league.id);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color primary, Color secondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: secondary)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primary),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color color;

  _SliverAppBarDelegate(this._tabBar, {required this.color});

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: color,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

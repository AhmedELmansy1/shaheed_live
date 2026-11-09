import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/league_model.dart';
import '../widgets/app_button.dart';
import 'providers/onboarding_provider.dart';

class TeamSelectionScreen extends ConsumerStatefulWidget {
  const TeamSelectionScreen({super.key});

  @override
  ConsumerState<TeamSelectionScreen> createState() =>
      _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends ConsumerState<TeamSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Ensure selected leagues have their team fetching triggered lazily
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(onboardingProvider);
      final notifier = ref.read(onboardingProvider.notifier);
      for (final lId in state.selectedLeagueIds) {
        if (!state.leagueTeams.containsKey(lId)) {
          notifier.loadTeamsForLeague(lId);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    final bg = AppColors.backgroundOf(context);
    final surface = AppColors.surfaceOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);
    final primary = AppColors.primaryOf(context);

    final selectedIdsSet = state.selectedTeamIdsSet;
    final canFinish = state.selectedTeamIds.isNotEmpty;

    final query = _searchQuery.trim().toLowerCase();

    // Map selected league IDs to actual LeagueModel
    final selectedLeagues = state.selectedLeagueIds.map((id) {
      return state.leagues.firstWhere(
        (l) => l.id == id,
        orElse: () => LeagueModel(
          id: id,
          name: 'بطولة #$id',
          nameEn: 'League #$id',
          country: '',
        ),
      );
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'اختيار الفرق المفضلة',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header title
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Column(
                children: [
                  Text(
                    'اختر فرقك المفضلة',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleLarge(color: textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'اختر نادياً واحداً على الأقل لمتابعة أخباره وتنبيهاته (${state.selectedTeamIds.length} محدد)',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall(color: textSecondary),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: border),
                ),
                child: TextField(
                  controller: _searchController,
                  style: AppTypography.bodyMedium(color: textPrimary),
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن نادٍ...',
                    hintStyle: AppTypography.bodyMedium(color: textSecondary),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: textSecondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 2,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                ),
              ),
            ),

            // Teams Viewport using high-performance Slivers (O(1) viewport virtualization)
            Expanded(
              child: selectedLeagues.isEmpty
                  ? Center(
                      child: Text(
                        'يرجى اختيار دوري واحد على الأقل أولاً',
                        style: AppTypography.bodyMedium(color: textSecondary),
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        for (final league in selectedLeagues) ...[
                          _buildLeagueSliver(
                            context: context,
                            league: league,
                            state: state,
                            notifier: notifier,
                            query: query,
                            selectedIdsSet: selectedIdsSet,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            surface: surface,
                            border: border,
                            primary: primary,
                          ),
                        ],
                      ],
                    ),
            ),

            // Bottom action button: "ابدأ الآن"
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: surface,
                border: Border(top: BorderSide(color: border)),
              ),
              child: AppButton(
                label: canFinish ? 'ابدأ الآن' : 'اختر نادياً واحداً على الأقل',
                onPressed: canFinish
                    ? () {
                        HapticFeedback.lightImpact();
                        // 1. Instant local persistence & fire-and-forget sync
                        notifier.fastCompleteOnboarding();
                        // 2. Immediate zero-latency navigation to home
                        if (!context.mounted) return;
                        context.go('/home');
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeagueSliver({
    required BuildContext context,
    required LeagueModel league,
    required OnboardingState state,
    required OnboardingNotifier notifier,
    required String query,
    required Set<String> selectedIdsSet,
    required Color textPrimary,
    required Color textSecondary,
    required Color surface,
    required Color border,
    required Color primary,
  }) {
    final isLoading = state.leagueLoading[league.id] ?? false;
    final errorMessage = state.leagueErrors[league.id];
    final teams = state.leagueTeams[league.id] ?? const [];

    final filteredTeams = query.isEmpty
        ? teams
        : teams.where((t) {
            return t.name.toLowerCase().contains(query) ||
                t.nameEn.toLowerCase().contains(query);
          }).toList();

    // If searching and this league has no matching teams and is not loading/error, omit it
    if (query.isNotEmpty && filteredTeams.isEmpty && !isLoading && errorMessage == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverMainAxisGroup(
      slivers: [
        // League Header with team count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                if (league.logoUrl != null && league.logoUrl!.isNotEmpty) ...[
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: league.logoUrl!,
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: Text(
                    league.name,
                    style: AppTypography.titleSmall(color: textPrimary).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isLoading && errorMessage == null)
                  Text(
                    '(${teams.length} نادٍ)',
                    style: AppTypography.caption(color: textSecondary),
                  ),
              ],
            ),
          ),
        ),

        // Body: Loading, Error with Retry, or Teams Grid
        if (isLoading && teams.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: primary,
                  ),
                ),
              ),
            ),
          )
        else if (errorMessage != null && teams.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.vermilion,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: AppTypography.bodySmall(color: textSecondary),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('إعادة المحاولة'),
                      style: TextButton.styleFrom(
                        foregroundColor: primary,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        notifier.retryLeagueTeams(league.id);
                      },
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.95,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final team = filteredTeams[index];
                  final isSelected = selectedIdsSet.contains(team.id);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      notifier.toggleTeamSelection(team.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary.withValues(alpha: 0.08)
                            : surface,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: isSelected ? primary : border,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundOf(context),
                                    shape: BoxShape.circle,
                                  ),
                                  child: team.logoUrl != null &&
                                          team.logoUrl!.isNotEmpty
                                      ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: team.logoUrl!,
                                            fit: BoxFit.contain,
                                            errorWidget: (context, url, error) =>
                                                Icon(
                                              Icons.shield_rounded,
                                              color: primary,
                                              size: 22,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.shield_rounded,
                                          color: primary,
                                          size: 22,
                                        ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  team.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption(color: textPrimary)
                                      .copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: filteredTeams.length,
              ),
            ),
          ),
      ],
    );
  }
}

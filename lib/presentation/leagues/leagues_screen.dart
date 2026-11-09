import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/league_model.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/matches_skeleton.dart';
import '../widgets/section_header.dart';

/// Clean, editorial Leagues Screen in "Paper × Ink × Vermilion".
class LeaguesScreen extends ConsumerStatefulWidget {
  const LeaguesScreen({super.key});

  @override
  ConsumerState<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends ConsumerState<LeaguesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'الدوريات والبطولات',
            style: AppTypography.titleMedium(color: textPrimary).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          shape: Border(bottom: BorderSide(color: border, width: 1.0)),
        ),
        body: const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: MatchesSkeleton(),
        ),
      );
    }

    final query = _searchQuery.trim().toLowerCase();
    final allLeagues = state.leagues;
    final followedIds = state.selectedLeagueIds.toSet();

    final filteredLeagues = query.isEmpty
        ? allLeagues
        : allLeagues.where((l) {
            return l.name.toLowerCase().contains(query) ||
                l.nameEn.toLowerCase().contains(query) ||
                l.country.toLowerCase().contains(query);
          }).toList();

    final followedLeagues =
        filteredLeagues.where((l) => followedIds.contains(l.id)).toList();
    final otherLeagues =
        filteredLeagues.where((l) => !followedIds.contains(l.id)).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'الدوريات والبطولات',
          style: AppTypography.titleMedium(color: textPrimary).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: border, width: 1.0)),
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: AppTypography.bodyMedium(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'ابحث عن بطولة أو دولة...',
                  hintStyle: AppTypography.bodyMedium(color: textSecondary),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: textSecondary,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: textSecondary,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.mdRadius,
                    borderSide: BorderSide(color: border, width: 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadii.mdRadius,
                    borderSide: BorderSide(color: border, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadii.mdRadius,
                    borderSide: BorderSide(
                      color: AppColors.primaryOf(context),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                ),
              ),
            ),
          ),

          // 2. Followed Leagues Section
          if (followedLeagues.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: SectionHeader(
                  title: 'البطولات المفضلة',
                  count: followedLeagues.length,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final league = followedLeagues[index];
                    return _buildLeagueCard(
                      context,
                      league,
                      isFollowed: true,
                      onToggle: () => notifier.toggleLeagueSelection(league.id),
                    );
                  },
                  childCount: followedLeagues.length,
                ),
              ),
            ),
          ],

          // 3. Other Leagues Section
          if (otherLeagues.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: SectionHeader(
                  title: followedLeagues.isEmpty ? 'جميع البطولات' : 'بطولات أخرى',
                  count: otherLeagues.length,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final league = otherLeagues[index];
                    return _buildLeagueCard(
                      context,
                      league,
                      isFollowed: false,
                      onToggle: () => notifier.toggleLeagueSelection(league.id),
                    );
                  },
                  childCount: otherLeagues.length,
                ),
              ),
            ),
          ],

          // 4. Empty Search State
          if (filteredLeagues.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AppEmptyState(
                  type: EmptyStateType.leagues,
                  title: 'لم يتم العثور على بطولات مطابقة',
                  subtitle: 'تأكد من كتابة اسم البطولة أو الدولة بشكل صحيح.',
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  Widget _buildLeagueCard(
    BuildContext context,
    LeagueModel league, {
    required bool isFollowed,
    required VoidCallback onToggle,
  }) {
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final primary = AppColors.primaryOf(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadii.mdRadius,
        border: Border.all(
          color: isFollowed ? primary.withValues(alpha: 0.45) : border,
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadii.mdRadius,
        child: InkWell(
          borderRadius: AppRadii.mdRadius,
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/league/${league.id}', extra: league);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                // Trophy / Medal Emblem
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isFollowed
                        ? primary.withValues(alpha: 0.12)
                        : AppColors.surfaceElevatedOf(context),
                    borderRadius: AppRadii.smRadius,
                    border: Border.all(color: border, width: 0.8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: isFollowed ? primary : textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // League Titles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        league.name,
                        style: AppTypography.titleSmall(color: textPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${league.nameEn} • ${league.country.isNotEmpty ? league.country : "دولي"}',
                        style: AppTypography.labelSmall(color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Star Follow Toggle Button (48dp target)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: Icon(
                      isFollowed ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isFollowed ? primary : textSecondary,
                      size: 24,
                    ),
                    tooltip: isFollowed ? 'إلغاء المتابعة' : 'متابعة البطولة',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onToggle();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

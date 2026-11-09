import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/team_model.dart';
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

    final canFinish = state.selectedTeamIds.isNotEmpty;

    // Filter teams by search
    final query = _searchQuery.trim().toLowerCase();
    final filteredTeams = query.isEmpty
        ? state.filteredTeams
        : state.filteredTeams.where((t) {
            return t.name.toLowerCase().contains(query) ||
                t.nameEn.toLowerCase().contains(query);
          }).toList();

    // Group teams by league title
    final Map<String, List<TeamModel>> groupedTeams = {};
    for (final team in filteredTeams) {
      final league = state.leagues.firstWhere(
        (l) => l.id == team.leagueId,
        orElse: () => state.leagues.isNotEmpty
            ? state.leagues.first
            : const TeamModel(id: '', name: '', nameEn: '', leagueId: '')
                as dynamic,
      );
      final leagueTitle = league.name.isNotEmpty ? league.name : 'أخرى';
      groupedTeams.putIfAbsent(leagueTitle, () => []).add(team);
    }

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

            // Teams list
            Expanded(
              child: filteredTeams.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد أندية متاحة حالياً',
                        style: AppTypography.bodyMedium(color: textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: groupedTeams.keys.length,
                      itemBuilder: (context, index) {
                        final leagueName = groupedTeams.keys.elementAt(index);
                        final teams = groupedTeams[leagueName]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              child: Text(
                                leagueName,
                                style: AppTypography.titleSmall(
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.95,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: teams.length,
                              itemBuilder: (context, teamIdx) {
                                final team = teams[teamIdx];
                                final isSelected =
                                    state.selectedTeamIds.contains(team.id);

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
                                      borderRadius:
                                          BorderRadius.circular(AppRadii.md),
                                      border: Border.all(
                                        color: isSelected ? primary : border,
                                        width: isSelected ? 2.0 : 1.0,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(
                                            AppSpacing.xs,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppColors.backgroundOf(
                                                    context,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: team.logoUrl != null &&
                                                        team.logoUrl!.isNotEmpty
                                                    ? ClipOval(
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl:
                                                              team.logoUrl!,
                                                          fit: BoxFit.contain,
                                                          errorWidget:
                                                              (context, url, error) =>
                                                                  Icon(
                                                            Icons
                                                                .shield_rounded,
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
                                              const SizedBox(
                                                height: AppSpacing.xs,
                                              ),
                                              Text(
                                                team.name,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTypography.caption(
                                                  color: textPrimary,
                                                ).copyWith(
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
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        );
                      },
                    ),
            ),

            // Bottom action button
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: surface,
                border: Border(top: BorderSide(color: border)),
              ),
              child: AppButton(
                label: canFinish ? 'ابدأ الآن' : 'اختر نادياً واحداً على الأقل',
                
                onPressed: canFinish ? () async {
                  HapticFeedback.lightImpact();
                  await notifier.saveSelectedTeams();
                  if (!context.mounted) return;
                  context.go('/home');
                } : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}




import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../search/providers/search_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';

class FavoriteTeamsScreen extends ConsumerStatefulWidget {
  const FavoriteTeamsScreen({super.key});

  @override
  ConsumerState<FavoriteTeamsScreen> createState() => _FavoriteTeamsScreenState();
}

class _FavoriteTeamsScreenState extends ConsumerState<FavoriteTeamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    final allTeamsAsync = ref.watch(allTeamsProvider);
    final selectedIds = onboardingState.selectedTeamIds.toSet();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('إدارة الفرق المفضلة'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              style: AppTypography.bodyMedium(color: AppColors.darkTextPrimary),
              decoration: InputDecoration(
                hintText: 'ابحث عن فريقك المفضل...',
                hintStyle: AppTypography.bodyMedium(color: AppColors.darkTextMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.darkTextSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.darkTextSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.darkSurface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Selected Count Badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الفرق المختارة (${DateFormatter.toArabicNumerals('${selectedIds.length}')})',
                  style: AppTypography.bodySmall(color: AppColors.darkTextSecondary),
                ),
                if (selectedIds.isNotEmpty)
                  Text(
                    'يتم حفظ التفضيلات تلقائياً',
                    style: AppTypography.caption(color: AppColors.primary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Teams List
          Expanded(
            child: allTeamsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: AppEmptyState(
                  type: EmptyStateType.error,
                  title: 'حدث خطأ في تحميل الفرق',
                  subtitle: '$err',
                ),
              ),
              data: (teams) {
                final filtered = _searchQuery.isEmpty
                    ? teams
                    : teams.where((t) {
                        return t.name.toLowerCase().contains(_searchQuery) ||
                            t.nameEn.toLowerCase().contains(_searchQuery);
                      }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: AppEmptyState(
                      type: EmptyStateType.soccer,
                      title: 'لا توجد نتائج مطابقة للبحث',
                      subtitle: 'تأكد من اسم الفريق المدخل',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    120,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final team = filtered[index];
                    final isSelected = selectedIds.contains(team.id);

                    return AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      margin: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      borderColor: isSelected
                          ? AppColors.gold.withValues(alpha: 0.6)
                          : null,
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        onboardingNotifier.toggleTeamSelection(team.id);
                        await onboardingNotifier.saveSelectedTeams();
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.gold.withValues(alpha: 0.18)
                                  : AppColors.darkSurfaceHigh,
                              shape: BoxShape.circle,
                              boxShadow: isSelected
                                  ? [
                                      const BoxShadow(
                                        color: AppColors.goldGlow,
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              isSelected
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: isSelected
                                  ? AppColors.gold
                                  : AppColors.darkTextMuted,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  team.name,
                                  style: AppTypography.titleSmall(
                                    color: isSelected
                                        ? AppColors.darkTextPrimary
                                        : AppColors.darkTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  team.nameEn,
                                  style: AppTypography.caption(
                                    color: AppColors.darkTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.black,
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

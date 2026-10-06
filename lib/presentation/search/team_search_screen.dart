import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import 'providers/search_provider.dart';

class TeamSearchScreen extends ConsumerStatefulWidget {
  const TeamSearchScreen({super.key});

  @override
  ConsumerState<TeamSearchScreen> createState() => _TeamSearchScreenState();
}

class _TeamSearchScreenState extends ConsumerState<TeamSearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Preload teams list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(allTeamsProvider.notifier);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final allTeamsState = ref.watch(allTeamsProvider);
    final filteredTeams = ref.watch(filteredTeamsProvider);

    final bg = AppColors.backgroundOf(context);
    final surface = AppColors.surfaceOf(context);
    final surfaceHigh = AppColors.surfaceHighOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final textMuted = AppColors.textMutedOf(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'البحث عن فريق',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: textPrimary),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              style: AppTypography.bodyMedium(color: textPrimary),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).setQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن فريقك...',
                hintStyle: AppTypography.bodyMedium(color: textMuted),
                prefixIcon: Icon(Icons.search_rounded, color: textMuted),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: textMuted),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: allTeamsState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => Center(
                child: AppEmptyState(
                  type: EmptyStateType.error,
                  title: 'حدث خطأ أثناء تحميل الفرق',
                  subtitle: '$err',
                ),
              ),
              data: (_) {
                if (query.isEmpty) {
                  return const Center(
                    child: AppEmptyState(
                      type: EmptyStateType.soccer,
                      title: 'اكتب اسم الفريق للبحث',
                      subtitle:
                          'ابحث في قائمة أندية الدوريات العربية والعالمية',
                    ),
                  );
                }

                if (filteredTeams.isEmpty) {
                  return const Center(
                    child: AppEmptyState(
                      type: EmptyStateType.soccer,
                      title: 'لا توجد نتائج مطابقة',
                      subtitle: 'تأكد من كتابة اسم الفريق بشكل صحيح',
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
                  itemCount: filteredTeams.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final team = filteredTeams[index];
                    return AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      margin: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push(
                          '/team/${Uri.encodeComponent(team.name)}/fixtures',
                          extra: team,
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sports_soccer_rounded,
                              color: AppColors.primary,
                              size: 20,
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
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  team.nameEn,
                                  style: AppTypography.caption(
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceHigh,
                              borderRadius: BorderRadius.circular(
                                AppRadii.full,
                              ),
                              border: Border.all(color: border),
                            ),
                            child: Text(
                              team.leagueId,
                              style: AppTypography.caption(
                                color: textSecondary,
                              ),
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

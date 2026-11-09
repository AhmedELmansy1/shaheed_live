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

class LeagueSelectionScreen extends ConsumerStatefulWidget {
  final bool isEditing;

  const LeagueSelectionScreen({
    super.key,
    this.isEditing = false,
  });

  @override
  ConsumerState<LeagueSelectionScreen> createState() =>
      _LeagueSelectionScreenState();
}

class _LeagueSelectionScreenState
    extends ConsumerState<LeagueSelectionScreen> {
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

    final canContinue = state.selectedLeagueIds.isNotEmpty;

    // Filter leagues by search query
    final query = _searchQuery.trim().toLowerCase();
    final filteredLeagues = query.isEmpty
        ? state.leagues
        : state.leagues.where((l) {
            return l.name.toLowerCase().contains(query) ||
                l.nameEn.toLowerCase().contains(query) ||
                l.country.toLowerCase().contains(query);
          }).toList();

    // Grouping: Popular first, then by country
    final popularLeagues =
        filteredLeagues.where((l) => l.isPopular).toList();
    final Map<String, List<LeagueModel>> countryGroups = {};
    for (final l in filteredLeagues) {
      if (!l.isPopular || query.isNotEmpty) {
        countryGroups.putIfAbsent(l.country, () => []).add(l);
      }
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.isEditing ? 'إدارة الدوريات المفضلة' : 'اختيار الدوريات',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: widget.isEditing,
      ),
      body: SafeArea(
        child: state.isLoading
            ? Center(
                child: CircularProgressIndicator(color: primary),
              )
            : state.errorMessage != null && state.leagues.isEmpty
                ? _buildErrorView(context, state.errorMessage!, notifier)
                : Column(
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
                              'اختر الدوريات المفضلة لديك',
                              textAlign: TextAlign.center,
                              style: AppTypography.titleLarge(
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'يجب اختيار دوري واحد على الأقل للمتابعة (${state.selectedLeagueIds.length} محدد)',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall(
                                color: textSecondary,
                              ),
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
                            borderRadius:
                                BorderRadius.circular(AppRadii.md),
                            border: Border.all(color: border),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: AppTypography.bodyMedium(
                              color: textPrimary,
                            ),
                            textDirection: TextDirection.rtl,
                            decoration: InputDecoration(
                              hintText: 'ابحث عن بطولة أو دولة...',
                              hintStyle: AppTypography.bodyMedium(
                                color: textSecondary,
                              ),
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

                      // Grouped list
                      Expanded(
                        child: filteredLeagues.isEmpty
                            ? Center(
                                child: Text(
                                  'لا توجد نتائج مطابقة لبحثك',
                                  style: AppTypography.bodyMedium(
                                    color: textSecondary,
                                  ),
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.sm,
                                ),
                                children: [
                                  // 1. Popular section (if no search query)
                                  if (query.isEmpty &&
                                      popularLeagues.isNotEmpty) ...[
                                    _buildSectionHeader(
                                      context,
                                      title: 'البطولات الأكثر متابعة',
                                      icon: Icons.star_rounded,
                                      iconColor: AppColors.gold,
                                    ),
                                    _buildGrid(
                                      popularLeagues,
                                      state.selectedLeagueIds,
                                      notifier,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                  ],

                                  // 2. Country sections
                                  for (final entry in countryGroups.entries) ...[
                                    _buildSectionHeader(
                                      context,
                                      title: entry.key,
                                      icon: Icons.public_rounded,
                                      iconColor: primary,
                                    ),
                                    _buildGrid(
                                      entry.value,
                                      state.selectedLeagueIds,
                                      notifier,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                ],
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
                          label: widget.isEditing
                              ? 'التالي: اختيار الأندية'
                              : 'المتابعة لاختيار الأندية',
                          onPressed: canContinue
                              ? () async {
                                  HapticFeedback.lightImpact();
                                  await notifier.saveSelectedLeagues();
                                  if (!context.mounted) return;
                                  context.push('/onboarding/teams');
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
  }) {
    final textPrimary = AppColors.textPrimaryOf(context);

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            title,
            style: AppTypography.titleSmall(color: textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    List<LeagueModel> leagues,
    List<String> selectedIds,
    OnboardingNotifier notifier,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.35,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: leagues.length,
      itemBuilder: (context, index) {
        final league = leagues[index];
        final isSelected = selectedIds.contains(league.id);
        final surface = AppColors.surfaceOf(context);
        final border = AppColors.borderOf(context);
        final primary = AppColors.primaryOf(context);
        final textPrimary = AppColors.textPrimaryOf(context);
        final textSecondary = AppColors.textSecondaryOf(context);

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            notifier.toggleLeagueSelection(league.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? primary.withValues(alpha: 0.08) : surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: isSelected ? primary : border,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo or fallback icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundOf(context),
                          shape: BoxShape.circle,
                        ),
                        child: league.logoUrl != null &&
                                league.logoUrl!.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: league.logoUrl!,
                                  fit: BoxFit.contain,
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.sports_soccer_rounded,
                                    color: primary,
                                    size: 22,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.sports_soccer_rounded,
                                color: primary,
                                size: 22,
                              ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        league.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall(
                          color: textPrimary,
                        ).copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      if (league.country.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          league.country,
                          style: AppTypography.caption(
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Checkmark indicator
                if (isSelected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    String message,
    OnboardingNotifier notifier,
  ) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 56,
            color: AppColors.vermilion,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'حدث خطأ في تحميل البيانات',
            style: AppTypography.titleMedium(color: textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(color: textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 160,
            child: AppButton(
              label: 'إعادة المحاولة',
              onPressed: () {
                HapticFeedback.lightImpact();
                notifier.retry();
              },
            ),
          ),
        ],
      ),
    );
  }
}

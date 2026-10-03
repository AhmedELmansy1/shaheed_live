import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/match_model.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../update/widgets/soft_update_banner.dart';
import '../widgets/app_button.dart';
import '../widgets/app_chip.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/hero_match_card.dart';
import '../widgets/live_badge.dart';
import '../widgets/match_card.dart';
import '../widgets/matches_skeleton.dart';
import '../widgets/native_ad_card.dart';
import '../widgets/section_header.dart';
import 'providers/matches_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);
    final customDate = ref.watch(selectedCustomDateProvider);
    final activeFilter = ref.watch(matchFilterProvider);
    final matchesAsync = ref.watch(filteredMatchesProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 70,
        titleSpacing: AppSpacing.lg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'شوت لايف',
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.darkTextPrimary,
                letterSpacing: 0.0,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'كرة القدم في متناول يدك',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextSecondary,
                    letterSpacing: 0.0,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceHigh,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: IconButton(
              icon: const Icon(Icons.search_rounded, color: AppColors.darkTextPrimary, size: 20),
              tooltip: 'البحث عن فريق',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/search');
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceHigh,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: IconButton(
              icon: const Icon(Icons.person_outline_rounded, color: AppColors.darkTextSecondary, size: 20),
              tooltip: 'الإعدادات',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.go('/settings');
              },
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Sticky Date Selector Bar with Animated Pill
            _buildDateHeader(context, ref, activeTab, customDate),

            // Modern Horizontal Filter Chips Row
            _buildFilterChipsRow(context, ref, activeFilter),

            // In-session Soft Update Notification Banner
            const SoftUpdateBanner(),

            // Matches Scrollable Content Area
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.darkSurface,
                onRefresh: () async {
                  HapticFeedback.lightImpact();
                  await ref.read(matchesProvider.notifier).refresh();
                },
                child: matchesAsync.when(
                  loading: () => const MatchesSkeleton(),
                  error: (error, stack) => _buildErrorView(context, ref, error),
                  data: (matches) {
                    if (matches.isEmpty) {
                      return _buildEmptyView(context, ref, activeFilter);
                    }
                    return _buildHomeContent(context, ref, matches);
                  },
                ),
              ),
            ),

            // Persistent Bottom Banner Ad (Home Placement)
            const BannerAdWidget(placement: BannerPlacement.home),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(
    BuildContext context,
    WidgetRef ref,
    HomeTab activeTab,
    DateTime? customDate,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: AppRadii.mdRadius,
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      _buildTabItem(
                        context,
                        ref,
                        label: 'أمس',
                        tab: HomeTab.yesterday,
                        isActive: activeTab == HomeTab.yesterday,
                      ),
                      _buildTabItem(
                        context,
                        ref,
                        label: 'اليوم',
                        tab: HomeTab.today,
                        isActive: activeTab == HomeTab.today,
                      ),
                      _buildTabItem(
                        context,
                        ref,
                        label: 'غداً',
                        tab: HomeTab.tomorrow,
                        isActive: activeTab == HomeTab.tomorrow,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              GestureDetector(
                onTap: () => _pickCustomDate(context, ref),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: activeTab == HomeTab.customDate
                        ? AppColors.primary
                        : AppColors.darkBackground,
                    borderRadius: AppRadii.mdRadius,
                    border: Border.all(
                      color: activeTab == HomeTab.customDate
                          ? AppColors.primary
                          : AppColors.darkBorder,
                    ),
                    boxShadow: activeTab == HomeTab.customDate
                        ? [
                            const BoxShadow(
                              color: AppColors.primaryGlow,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: activeTab == HomeTab.customDate
                        ? Colors.black
                        : AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          if (activeTab == HomeTab.customDate && customDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceHigh,
                borderRadius: AppRadii.fullRadius,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_note_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Text(
                    DateFormatter.formatDisplayDate(customDate),
                    style: const TextStyle(
                      color: AppColors.darkTextPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  InkWell(
                    borderRadius: AppRadii.fullRadius,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(selectedCustomDateProvider.notifier).setDate(null);
                      ref.read(activeTabProvider.notifier).setTab(HomeTab.today);
                      ref.read(matchesProvider.notifier).refresh();
                    },
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.darkTextMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChipsRow(
    BuildContext context,
    WidgetRef ref,
    MatchFilterType activeFilter,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.darkDivider, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            AppChip(
              label: 'الكل',
              isSelected: activeFilter == MatchFilterType.all,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(matchFilterProvider.notifier).setFilter(MatchFilterType.all);
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'مباشر',
              icon: Icons.fiber_manual_record_rounded,
              iconColor: AppColors.live,
              isSelected: activeFilter == MatchFilterType.live,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(matchFilterProvider.notifier).setFilter(MatchFilterType.live);
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'القادمة',
              isSelected: activeFilter == MatchFilterType.upcoming,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(matchFilterProvider.notifier).setFilter(MatchFilterType.upcoming);
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'المفضلة',
              icon: Icons.star_rounded,
              iconColor: AppColors.gold,
              isSelected: activeFilter == MatchFilterType.favorites,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(matchFilterProvider.notifier).setFilter(MatchFilterType.favorites);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required HomeTab tab,
    required bool isActive,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(selectedCustomDateProvider.notifier).setDate(null);
          ref.read(activeTabProvider.notifier).setTab(tab);
          ref.read(matchesProvider.notifier).refresh();
        },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standardCurve,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: AppRadii.smRadius,
            boxShadow: isActive
                ? [
                    const BoxShadow(
                      color: AppColors.primaryGlow,
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.black : AppColors.darkTextSecondary,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(selectedCustomDateProvider) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.darkSurface,
              onSurface: AppColors.darkTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(selectedCustomDateProvider.notifier).setDate(picked);
      ref.read(activeTabProvider.notifier).setTab(HomeTab.customDate);
      ref.read(matchesProvider.notifier).refresh();
    }
  }

  Widget _buildHomeContent(
    BuildContext context,
    WidgetRef ref,
    List<MatchModel> matches,
  ) {
    final liveMatches = matches.where((m) => m.isLive).toList();
    final featuredMatch = liveMatches.isNotEmpty
        ? liveMatches.first
        : (matches.isNotEmpty ? matches.first : null);

    final adConfig = ref.watch(currentAdConfigProvider);
    final nativeConfig = adConfig.nativeMatchList;
    final insertEvery = nativeConfig.insertEveryNItems;

    // Group matches by championship title
    final Map<String, List<MatchModel>> grouped = {};
    for (final match in matches) {
      final title = match.championship.title;
      grouped.putIfAbsent(title, () => []).add(match);
    }

    int matchCounter = 0;

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 120),
      children: [
        // 1. Featured / Hero Match Card
        if (featuredMatch != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, size: 18, color: AppColors.gold),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  'المباراة المميزة',
                  style: GoogleFonts.cairo(
                    color: AppColors.darkTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
            ),
          ),
          HeroMatchCard(match: featuredMatch),
          const SizedBox(height: AppSpacing.sm),
        ],

        // 2. Live Now Horizontal Section (if there are live matches)
        if (liveMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                const LiveBadge(minuteText: 'مباشر الآن', isLarge: true),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.live.withValues(alpha: 0.15),
                    borderRadius: AppRadii.fullRadius,
                    border: Border.all(color: AppColors.live.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    DateFormatter.toArabicNumerals(liveMatches.length.toString()),
                    style: const TextStyle(
                      color: AppColors.live,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...liveMatches.map((m) => MatchCard(match: m)),
          const SizedBox(height: AppSpacing.lg),
        ],

        // 3. All Grouped Matches with SectionHeader
        ...grouped.entries.map((entry) {
          final title = entry.key;
          final champMatches = entry.value;
          final champLogo = champMatches.first.championship.image;

          final List<Widget> items = [];

          // Competition Header with SectionHeader
          items.add(
            SectionHeader(
              title: title,
              logoUrl: champLogo,
              count: champMatches.length,
            ),
          );

          // Match Cards & Native Ad insertion
          for (final m in champMatches) {
            items.add(MatchCard(match: m));
            matchCounter++;

            if (nativeConfig.enabled &&
                insertEvery > 0 &&
                matchCounter % insertEvery == 0) {
              items.add(const NativeAdCard());
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          );
        }),
      ],
    );
  }

  Widget _buildEmptyView(BuildContext context, WidgetRef ref, MatchFilterType activeFilter) {
    if (activeFilter == MatchFilterType.favorites) {
      final onboardingState = ref.watch(onboardingProvider);
      final hasFavorites = onboardingState.selectedTeamIds.isNotEmpty;

      return AppEmptyState(
        type: EmptyStateType.star,
        title: hasFavorites
            ? 'لا توجد مباريات لفرقك المفضلة اليوم'
            : 'لم تختر أي فرق مفضلة بعد',
        subtitle: hasFavorites
            ? 'جرّب تفقّد جدول يوم آخر أو إضافة أندية مفضلة إضافية لتظهر هنا'
            : 'اختر فرقك وأنديتك المفضلة لتصلك مبارياتها وتنبيهاتها في قسم خاص',
        action: AppButton(
          label: hasFavorites ? 'إدارة الفرق المفضلة' : 'اختيار الفرق المفضلة',
          icon: Icons.star_rounded,
          onPressed: () => context.push('/favorites'),
        ),
      );
    }

    return const AppEmptyState(
      type: EmptyStateType.soccer,
      title: 'لا توجد مباريات متوفرة لهذا الفلتر',
      subtitle: 'يرجى اختيار فلتر آخر أو تفقّد جدول يوم مختلف',
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
    return AppEmptyState(
      type: EmptyStateType.error,
      title: 'عذراً، حدث خطأ أثناء جلب البيانات',
      subtitle: error.toString(),
      action: AppButton(
        label: 'إعادة المحاولة',
        icon: Icons.refresh_rounded,
        onPressed: () {
          ref.read(matchesProvider.notifier).refresh();
        },
      ),
    );
  }
}

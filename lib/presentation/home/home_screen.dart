import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/battery_optimization_service.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../update/widgets/soft_update_banner.dart';
import '../widgets/app_button.dart';
import '../widgets/app_chip.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/battery_guidance_dialog.dart';
import '../widgets/hero_match_card.dart';
import '../widgets/live_badge.dart';
import '../widgets/match_card.dart';
import '../widgets/matches_skeleton.dart';
import '../widgets/native_ad_card.dart';
import '../widgets/section_header.dart';
import 'providers/matches_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBatteryGuidance();
    });
  }

  Future<void> _checkBatteryGuidance() async {
    final service = ref.read(batteryOptimizationServiceProvider);
    final shouldShow = await service.shouldShowGuidance();
    if (shouldShow && mounted) {
      showBatteryOptimizationDialog(context, isManual: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(activeTabProvider);
    final customDate = ref.watch(selectedCustomDateProvider);
    final activeFilter = ref.watch(matchFilterProvider);
    final sectionDataAsync = ref.watch(homeSectionDataProvider);
    final bg = AppColors.backgroundOf(context);
    final surface = AppColors.surfaceOf(context);
    final surfaceHigh = AppColors.surfaceHighOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
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
                color: textPrimary,
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
                    color: textSecondary,
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
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: surfaceHigh,
              shape: BoxShape.circle,
              border: Border.all(color: border),
            ),
            child: IconButton(
              icon: Icon(Icons.search_rounded, color: textPrimary, size: 20),
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
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: surfaceHigh,
              shape: BoxShape.circle,
              border: Border.all(color: border),
            ),
            child: IconButton(
              icon: Icon(
                Icons.person_outline_rounded,
                color: textSecondary,
                size: 20,
              ),
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
            _buildDateHeader(context, activeTab, customDate),

            // Modern Horizontal Filter Chips Row
            _buildFilterChipsRow(context, activeFilter),

            // In-session Soft Update Notification Banner
            const SoftUpdateBanner(),

            // Matches Scrollable Content Area
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: surface,
                onRefresh: () async {
                  HapticFeedback.lightImpact();
                  await ref.read(matchesProvider.notifier).refresh();
                },
                child: sectionDataAsync.when(
                  loading: () => const MatchesSkeleton(),
                  error: (error, stack) => _buildErrorView(context, error),
                  data: (sectionData) {
                    if (sectionData.isEmpty) {
                      return _buildEmptyView(context, activeFilter);
                    }
                    return _buildHomeContent(context, sectionData, activeFilter);
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
    HomeTab activeTab,
    DateTime? customDate,
  ) {
    final bg = AppColors.backgroundOf(context);
    final surface = AppColors.surfaceOf(context);
    final surfaceHigh = AppColors.surfaceHighOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(color: surface),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: AppRadii.mdRadius,
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      _buildTabItem(
                        context,
                        label: 'أمس',
                        tab: HomeTab.yesterday,
                        isActive: activeTab == HomeTab.yesterday,
                      ),
                      _buildTabItem(
                        context,
                        label: 'اليوم',
                        tab: HomeTab.today,
                        isActive: activeTab == HomeTab.today,
                      ),
                      _buildTabItem(
                        context,
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
                onTap: () => _pickCustomDate(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: activeTab == HomeTab.customDate
                        ? AppColors.primary
                        : bg,
                    borderRadius: AppRadii.mdRadius,
                    border: Border.all(
                      color: activeTab == HomeTab.customDate
                          ? AppColors.primary
                          : border,
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: surfaceHigh,
                borderRadius: AppRadii.fullRadius,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_note_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Text(
                    DateFormatter.formatDisplayDate(customDate),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  InkWell(
                    borderRadius: AppRadii.fullRadius,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(selectedCustomDateProvider.notifier)
                          .setDate(null);
                      ref
                          .read(activeTabProvider.notifier)
                          .setTab(HomeTab.today);
                      ref.read(matchesProvider.notifier).refresh();
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: textMuted,
                    ),
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
    MatchFilterType activeFilter,
  ) {
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border, width: 1)),
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
                ref
                    .read(matchFilterProvider.notifier)
                    .setFilter(MatchFilterType.all);
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
                ref
                    .read(matchFilterProvider.notifier)
                    .setFilter(MatchFilterType.live);
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'القادمة',
              isSelected: activeFilter == MatchFilterType.upcoming,
              onTap: () {
                HapticFeedback.selectionClick();
                ref
                    .read(matchFilterProvider.notifier)
                    .setFilter(MatchFilterType.upcoming);
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
                ref
                    .read(matchFilterProvider.notifier)
                    .setFilter(MatchFilterType.favorites);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context, {
    required String label,
    required HomeTab tab,
    required bool isActive,
  }) {
    final textSecondary = AppColors.textSecondaryOf(context);

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
              color: isActive ? Colors.black : textSecondary,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomDate(BuildContext context) async {
    final now = DateTime.now();
    final isLight = AppColors.isLight(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(selectedCustomDateProvider) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: isLight
              ? ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.black,
                    surface: AppColors.lightSurface,
                    onSurface: AppColors.lightTextPrimary,
                  ),
                )
              : ThemeData.dark().copyWith(
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
    HomeSectionData sectionData,
    MatchFilterType activeFilter,
  ) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final featuredMatch = sectionData.heroMatch;
    final favoriteMatches = sectionData.favoriteMatches;
    final liveMatches = sectionData.liveMatches;
    final leagueGroups = sectionData.leagueGroups;

    final adConfig = ref.watch(currentAdConfigProvider);
    final nativeConfig = adConfig.nativeMatchList;
    final insertEvery = nativeConfig.insertEveryNItems;

    int matchCounter = 0;

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 120),
      children: [
        // 1. Featured / Hero Match Card with smooth entrance
        if (featuredMatch != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, size: 18, color: AppColors.gold),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  'المباراة المميزة',
                  style: GoogleFonts.cairo(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
            ),
          ),
          HeroMatchCard(match: featuredMatch)
              .animate()
              .fadeIn(duration: 280.ms)
              .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: AppSpacing.sm),
        ],

        // 2. FAVORITES SECTION ("مبارياتك") — Surfaced FIRST if user has favorite team matches
        if (favoriteMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'مبارياتك',
                  style: GoogleFonts.cairo(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.0,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: AppRadii.fullRadius,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${DateFormatter.toArabicNumerals(favoriteMatches.length.toString())} مباريات',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...favoriteMatches.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            final card = MatchCard(match: m)
                .animate()
                .fadeIn(
                  duration: 240.ms,
                  delay: (math.min(idx, 8) * 35).ms,
                )
                .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);

            matchCounter++;
            if (nativeConfig.enabled &&
                insertEvery > 0 &&
                matchCounter % insertEvery == 0) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [card, const NativeAdCard()],
              );
            }
            return card;
          }),
          const SizedBox(height: AppSpacing.md),
        ],

        // 3. Live Now Horizontal Section (if there are live matches and not filtered by live)
        if (liveMatches.isNotEmpty && activeFilter != MatchFilterType.live) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const LiveBadge(minuteText: 'مباشر الآن', isLarge: true),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.live.withValues(alpha: 0.15),
                    borderRadius: AppRadii.fullRadius,
                    border: Border.all(
                      color: AppColors.live.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    DateFormatter.toArabicNumerals(
                      liveMatches.length.toString(),
                    ),
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
          ...liveMatches.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            return MatchCard(match: m)
                .animate()
                .fadeIn(duration: 240.ms, delay: (math.min(idx, 10) * 40).ms)
                .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
          }),
          const SizedBox(height: AppSpacing.lg),
        ],

        // 4. League Sections (Pre-sorted: Followed Leagues FIRST!)
        ...leagueGroups.map((group) {
          final title = group.leagueTitle;
          final champMatches = group.matches;
          final champLogo = group.leagueLogo;
          final isFollowed = group.isFollowed;

          final List<Widget> items = [];

          // Competition Header with SectionHeader (includes isFollowed indicator)
          items.add(
            SectionHeader(
              title: title,
              logoUrl: champLogo,
              count: champMatches.length,
              isFollowed: isFollowed,
            ),
          );

          // Match Cards with Staggered Entrance & Native Ad insertion
          for (final m in champMatches) {
            final itemIndex = matchCounter;
            items.add(
              MatchCard(match: m)
                  .animate()
                  .fadeIn(
                    duration: 240.ms,
                    delay: (math.min(itemIndex, 12) * 40).ms,
                  )
                  .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
            );
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

  Widget _buildEmptyView(BuildContext context, MatchFilterType activeFilter) {
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

  Widget _buildErrorView(BuildContext context, Object error) {
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

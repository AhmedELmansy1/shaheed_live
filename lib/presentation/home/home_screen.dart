import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_constants.dart';
import '../../core/network/app_exception.dart';
import '../../core/services/battery_optimization_service.dart';
import '../../core/services/league_resolver_service.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../../data/models/sponsorship_model.dart';
import '../update/widgets/soft_update_banner.dart';
import '../widgets/app_button.dart';
import '../widgets/app_chip.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_state.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/battery_guidance_dialog.dart';
import '../widgets/day_selector.dart';
import '../widgets/hero_match_card.dart';
import '../widgets/live_badge.dart';
import '../widgets/match_card.dart';
import '../widgets/matches_skeleton.dart';
import '../widgets/native_ad_card.dart';
import '../widgets/sponsorship_banner_widget.dart';
import 'widgets/breaking_news_ticker.dart';
import '../widgets/section_header.dart';
import 'providers/matches_provider.dart';

/// Premium Home Screen in the "Paper × Ink × Vermilion" design system.
///
/// Editorial, tactile sports feed:
/// - Quick DaySelector (Yesterday, Today, Tomorrow, Calendar)
/// - League grouping with tactile SectionHeaders
/// - High-contrast MatchCards and lightweight HeroMatchCard
/// - Restyled offline cache banner and robust error/empty states
/// - Staggered entrance respecting reduced-motion accessibility
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
    final isOffline = ref.watch(offlineFallbackProvider);

    final bg = AppColors.backgroundOf(context);
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final vermilion = AppColors.primaryOf(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 68,
        titleSpacing: AppSpacing.lg,
        shape: Border(bottom: BorderSide(color: border, width: 1.0)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConstants.appName,
              style: AppTypography.displayMedium(color: textPrimary).copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: vermilion,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'كل نتيجة، لحظة بلحظة',
                  style: AppTypography.labelSmall(color: textSecondary).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Semantics(
            button: true,
            label: 'البحث عن الفرق والمباريات',
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: 1.0),
              ),
              child: IconButton(
                icon: Icon(Icons.search_rounded, color: textPrimary, size: 20),
                tooltip: 'البحث عن فريق',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/search');
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            button: true,
            label: 'إعدادات التطبيق',
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: 1.0),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.person_outline_rounded,
                  color: textSecondary,
                  size: 20,
                ),
                tooltip: 'الإعدادات',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.go('/settings');
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Day Selector (Yesterday / Today / Tomorrow / Calendar)
            DaySelector(
              activeTab: activeTab,
              customDate: customDate,
              onTabSelected: (tab) {
                ref.read(selectedCustomDateProvider.notifier).setDate(null);
                ref.read(activeTabProvider.notifier).setTab(tab);
                ref.read(matchesProvider.notifier).refresh();
              },
              onCustomDateSelected: (date) {
                ref.read(selectedCustomDateProvider.notifier).setDate(date);
                ref.read(activeTabProvider.notifier).setTab(HomeTab.customDate);
                ref.read(matchesProvider.notifier).refresh();
              },
            ),

            // 2. Filter Chips Row (All, Live, Upcoming, Favorites)
            _buildFilterChipsRow(context, activeFilter),

            // 3. In-session Soft Update Notification Banner
            const SoftUpdateBanner(),

            // 4. Restyled Offline Cache Fallback Banner
            if (isOffline) _buildOfflineBanner(context),

            // Breaking News Ticker (driven by config/app_settings.ticker_config)
            const BreakingNewsTicker(),

            // Direct Sponsorship (Home Top Placement)
            const SponsorshipBannerWidget(
              placement: SponsorshipPlacement.homeTopBanner,
            ),

            // 5. Matches Scrollable Content Area with Pull-to-Refresh
            Expanded(
              child: RefreshIndicator(
                color: vermilion,
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

            // 6. Persistent Bottom Banner Ad (Home Placement)
            const BannerAdWidget(placement: BannerPlacement.home),
          ],
        ),
      ),
    );
  }

  /// Restyled Offline Cache Banner in Paper × Ink style
  Widget _buildOfflineBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amberColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309);
    final bgColor = isDark
        ? const Color(0xFF262016)
        : const Color(0xFFFEF3C7);
    final borderColor = isDark
        ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
        : const Color(0xFFF59E0B).withValues(alpha: 0.4);
    final textColor = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: amberColor),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              'أنت تشاهد بيانات محفوظة (غير متصل بالإنترنت)',
              style: AppTypography.labelMedium(color: textColor).copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
    final liveColor = AppColors.primaryOf(context);
    final scope = ref.watch(homeFeedScopeProvider);
    final onboarding = ref.watch(onboardingProvider);
    final hasSelections = onboarding.selectedLeagueIds.isNotEmpty ||
        onboarding.selectedTeamIds.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border, width: 1.0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            if (hasSelections) ...[
              AppChip(
                label: 'مبارياتي',
                icon: Icons.bookmark_rounded,
                isSelected: scope == HomeFeedScope.myMatches,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(homeFeedScopeProvider.notifier)
                      .setScope(HomeFeedScope.myMatches);
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              AppChip(
                label: 'كل المباريات',
                icon: Icons.sports_soccer_rounded,
                isSelected: scope == HomeFeedScope.allMatches,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(homeFeedScopeProvider.notifier)
                      .setScope(HomeFeedScope.allMatches);
                },
              ),
              Container(
                height: 20,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                color: border,
              ),
            ],
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
              iconColor: liveColor,
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
    final onboardingState = ref.watch(onboardingProvider);
    final isReducedMotion = AppMotion.isReducedMotion(context);

    final adConfig = ref.watch(currentAdConfigProvider);
    final nativeConfig = adConfig.nativeMatchList;
    final insertEvery = nativeConfig.insertEveryNItems;

    int matchCounter = 0;

    Widget animateItem(Widget child, int index) {
      if (isReducedMotion) return child;
      return child
          .animate()
          .fadeIn(
            duration: 180.ms,
            delay: (math.min(index, 6) * 30).ms,
          )
          .slideY(
            begin: 0.04,
            end: 0,
            curve: Curves.easeOutCubic,
          );
    }

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 120),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        // 1. Featured / Hero Match Card
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
                  style: AppTypography.titleSmall(color: textPrimary).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          animateItem(HeroMatchCard(match: featuredMatch), 0),
          const SizedBox(height: AppSpacing.sm),
        ],

        // 2. Favorites Section ("مبارياتك")
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
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'مبارياتك',
                  style: AppTypography.titleMedium(color: textPrimary).copyWith(
                    fontWeight: FontWeight.w800,
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
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '${DateFormatter.toArabicNumerals(favoriteMatches.length.toString())} مباريات',
                    style: AppTypography.labelSmall(color: AppColors.gold).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...favoriteMatches.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            final card = animateItem(MatchCard(match: m), idx);

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

        // 3. Live Now Section (if there are live matches and not filtered by live)
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
                    color: AppColors.primaryOf(context).withValues(alpha: 0.12),
                    borderRadius: AppRadii.fullRadius,
                    border: Border.all(
                      color: AppColors.primaryOf(context).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    DateFormatter.toArabicNumerals(
                      liveMatches.length.toString(),
                    ),
                    style: AppTypography.labelSmall(
                      color: AppColors.vermilionTextOf(context),
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...liveMatches.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            return animateItem(MatchCard(match: m), idx);
          }),
          const SizedBox(height: AppSpacing.md),
        ],

        // 4. League Sections (Pre-sorted: Followed Leagues FIRST!)
        ...leagueGroups.map((group) {
          final title = group.leagueTitle;
          final champMatches = group.matches;
          final champLogo = group.leagueLogo;
          final isFollowed = group.isFollowed;

          final List<Widget> items = [];

          final resolvedLeagueId = LeagueResolverService.resolveToOnboardingLeagueId(
            champTitle: title,
            allLeagues: onboardingState.leagues,
          );

          // Competition Header with SectionHeader
          items.add(
            SectionHeader(
              title: title,
              logoUrl: champLogo,
              count: champMatches.length,
              isFollowed: isFollowed,
              onTap: resolvedLeagueId != null
                  ? () {
                      HapticFeedback.lightImpact();
                      context.push('/league/$resolvedLeagueId');
                    }
                  : null,
            ),
          );

          // Match Cards with Staggered Entrance & Native Ad insertion
          for (final m in champMatches) {
            final itemIndex = matchCounter;
            items.add(animateItem(MatchCard(match: m), itemIndex));
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
    final onboardingState = ref.watch(onboardingProvider);

    if (activeFilter == MatchFilterType.favorites) {
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

    final hasSelectedLeagues = onboardingState.selectedLeagueIds.isNotEmpty;
    if (hasSelectedLeagues) {
      return AppEmptyState(
        type: EmptyStateType.soccer,
        title: 'لا توجد مباريات في دورياتك اليوم',
        subtitle:
            'يمكنك تعديل قائمة الدوريات التي تتابعها لعرض المزيد من المباريات',
        action: AppButton(
          label: 'إدارة الدوريات',
          icon: Icons.sports_soccer,
          onPressed: () => context.push('/settings/leagues'),
        ),
      );
    }

    return AppEmptyState(
      type: EmptyStateType.soccer,
      title: 'لا توجد مباريات متوفرة لهذا الفلتر',
      subtitle: 'يرجى اختيار فلتر آخر أو تفقّد جدول يوم مختلف.',
      action: AppButton(
        label: 'تحديث الجدول',
        icon: Icons.refresh_rounded,
        onPressed: () {
          ref.read(matchesProvider.notifier).refresh();
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, Object error) {
    String title = 'عذراً، تعذر تحميل المباريات';
    String subtitle = 'يرجى التحقق من الاتصال وإعادة المحاولة.';

    if (error is NetworkException) {
      title = 'لا يوجد اتصال بالإنترنت';
      subtitle = 'يرجى التحقق من شبكة الواي فاي أو بيانات الهاتف والمحاولة مجدداً.';
    } else if (error is TimeoutException) {
      title = 'انتهت مهلة الاتصال بالخادم';
      subtitle = 'استغرق الخادم وقتاً أطول من المعتاد للاستجابة. يرجى إعادة المحاولة.';
    } else if (error is ServerException) {
      if (error.statusCode == 404) {
        title = 'لم يتم العثور على المباريات';
        subtitle = 'لم يتم العثور على جدول مباريات للتاريخ المحدد (رمز 404).';
      } else {
        title = 'خطأ في خادم المباريات';
        subtitle = error.message;
      }
    } else if (error is ParseException) {
      title = 'خطأ في معالجة البيانات';
      subtitle = 'حدث خطأ أثناء قراءة بيانات المباريات. يرجى إعادة المحاولة.';
    } else if (error is AppException) {
      subtitle = error.message;
    }

    return AppErrorState(
      title: title,
      subtitle: subtitle,
      onRetry: () {
        ref.read(matchesProvider.notifier).refresh();
      },
    );
  }
}


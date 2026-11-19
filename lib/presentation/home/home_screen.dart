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
import '../../core/utils/app_number_format.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../../data/models/sponsorship_model.dart';
import '../update/widgets/app_update_dialog.dart';
import '../update/widgets/soft_update_banner.dart';
import '../widgets/app_button.dart';
import '../widgets/app_chip.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_state.dart';
import '../widgets/app_logo.dart';
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
import 'widgets/instant_notification_banner.dart';
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
      AppUpdateDialog.checkAndShow(context, ref);
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 38, showSubtitle: false),
            const SizedBox(width: 10),
            Column(
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
                        color: AppColors.liveOf(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'مباشر · أهداف · نتائج',
                      style: AppTypography.labelSmall(color: textSecondary).copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
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

            // Instant Push Notification In-App Banner (driven by config/app_settings.latest_notification)
            const InstantNotificationBanner(),

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
    final border = AppColors.borderOf(context);
    final liveColor = AppColors.primaryOf(context);
    final scope = ref.watch(homeFeedScopeProvider);
    final onboarding = ref.watch(onboardingProvider);
    final hasSelections = onboarding.selectedLeagueIds.isNotEmpty ||
        onboarding.selectedTeamIds.isNotEmpty;
    final isMyMatchesActive = scope == HomeFeedScope.myMatches;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceOf(context),
            AppColors.backgroundOf(context),
          ],
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // 1. All (Default view: all matches across all leagues)
            AppChip(
              label: 'الكل',
              isSelected: activeFilter == MatchFilterType.all && !isMyMatchesActive,
              onTap: () {
                HapticFeedback.selectionClick();
                ref
                    .read(matchFilterProvider.notifier)
                    .setFilter(MatchFilterType.all);
                if (isMyMatchesActive) {
                  ref
                      .read(homeFeedScopeProvider.notifier)
                      .setScope(HomeFeedScope.allMatches);
                }
              },
            ),
            const SizedBox(width: AppSpacing.xs),

            // 2. Optional "مبارياتي" filter chip (OFF by default)
            if (hasSelections) ...[
              AppChip(
                label: 'مبارياتي',
                icon: Icons.bookmark_rounded,
                isSelected: isMyMatchesActive,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(homeFeedScopeProvider.notifier).toggleMyMatches();
                },
              ),
              const SizedBox(width: AppSpacing.xs),
            ],

            // 3. Live filter
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
            const SizedBox(width: AppSpacing.xs),

            // 4. Upcoming filter
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
            const SizedBox(width: AppSpacing.xs),

            // 5. Finished filter
            AppChip(
              label: 'المنتهية',
              isSelected: activeFilter == MatchFilterType.finished,
              onTap: () {
                HapticFeedback.selectionClick();
                ref
                    .read(matchFilterProvider.notifier)
                    .setFilter(MatchFilterType.finished);
              },
            ),
            const SizedBox(width: AppSpacing.sm),

            // Vertical divider separating status from broadcast filters
            Container(
              height: 20,
              width: 1,
              color: border,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            ),
            const SizedBox(width: AppSpacing.xs),

            // 6. Broadcast Channel Filter
            Consumer(
              builder: (context, ref, _) {
                final selectedChannel = ref.watch(selectedChannelFilterProvider);
                final isChannelActive = selectedChannel != null && selectedChannel.isNotEmpty;
                return AppChip(
                  label: isChannelActive ? selectedChannel : '📺 القناة',
                  icon: isChannelActive ? Icons.check_circle_rounded : Icons.tv_rounded,
                  iconColor: isChannelActive ? AppColors.primary : null,
                  isSelected: isChannelActive,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showChannelFilterModal(context);
                  },
                );
              },
            ),
            const SizedBox(width: AppSpacing.xs),

            // 7. Commentator Filter
            Consumer(
              builder: (context, ref, _) {
                final selectedCommentator = ref.watch(selectedCommentatorFilterProvider);
                final isCommActive = selectedCommentator != null && selectedCommentator.isNotEmpty;
                return AppChip(
                  label: isCommActive ? selectedCommentator : '🎙️ المعلق',
                  icon: isCommActive ? Icons.check_circle_rounded : Icons.record_voice_over_rounded,
                  iconColor: isCommActive ? AppColors.primary : null,
                  isSelected: isCommActive,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showCommentatorFilterModal(context);
                  },
                );
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
                    '${AppNumberFormat.formatCount(favoriteMatches.length)} مباريات',
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
                    AppNumberFormat.formatCount(liveMatches.length),
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

  void _showChannelFilterModal(BuildContext context) {
    final channels = ref.read(availableChannelsProvider);
    final selected = ref.read(selectedChannelFilterProvider);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.tv_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'تصفية المباريات حسب القناة الناقلة',
                      style: AppTypography.titleMedium(color: textPrimary).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Reset option (All channels)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    selected == null
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected == null ? AppColors.primary : textSecondary,
                    size: 20,
                  ),
                  title: Text(
                    'جميع القنوات (الكل)',
                    style: AppTypography.bodyMedium(
                      color: selected == null ? AppColors.primary : textPrimary,
                    ).copyWith(
                      fontWeight: selected == null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(selectedChannelFilterProvider.notifier).setChannel(null);
                    Navigator.of(ctx).pop();
                  },
                ),
                Divider(color: border, height: 1),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: channels.length,
                    separatorBuilder: (context, index) => Divider(color: border, height: 1),
                    itemBuilder: (c, idx) {
                      final ch = channels[idx];
                      final isCurrent = selected == ch;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isCurrent
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isCurrent ? AppColors.primary : textSecondary,
                          size: 20,
                        ),
                        title: Text(
                          ch,
                          style: AppTypography.bodyMedium(
                            color: isCurrent ? AppColors.primary : textPrimary,
                          ).copyWith(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(selectedChannelFilterProvider.notifier).setChannel(ch);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCommentatorFilterModal(BuildContext context) {
    final commentators = ref.read(availableCommentatorsProvider);
    final selected = ref.read(selectedCommentatorFilterProvider);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.record_voice_over_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'تصفية المباريات حسب المعلق الكروي',
                      style: AppTypography.titleMedium(color: textPrimary).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Reset option (All commentators)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    selected == null
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected == null ? AppColors.primary : textSecondary,
                    size: 20,
                  ),
                  title: Text(
                    'جميع المعلقين (الكل)',
                    style: AppTypography.bodyMedium(
                      color: selected == null ? AppColors.primary : textPrimary,
                    ).copyWith(
                      fontWeight: selected == null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(selectedCommentatorFilterProvider.notifier).setCommentator(null);
                    Navigator.of(ctx).pop();
                  },
                ),
                Divider(color: border, height: 1),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: commentators.length,
                    separatorBuilder: (context, index) => Divider(color: border, height: 1),
                    itemBuilder: (c, idx) {
                      final comm = commentators[idx];
                      final isCurrent = selected == comm;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isCurrent
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isCurrent ? AppColors.primary : textSecondary,
                          size: 20,
                        ),
                        title: Text(
                          comm,
                          style: AppTypography.bodyMedium(
                            color: isCurrent ? AppColors.primary : textPrimary,
                          ).copyWith(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(selectedCommentatorFilterProvider.notifier).setCommentator(comm);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


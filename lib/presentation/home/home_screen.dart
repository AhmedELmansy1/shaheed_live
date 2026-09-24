import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/match_model.dart';
import '../update/widgets/soft_update_banner.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/hero_match_card.dart';
import '../widgets/match_card.dart';
import '../widgets/matches_skeleton.dart';
import '../widgets/native_ad_card.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'شوت لايف',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
            Text(
              'كرة القدم في متناول يدك',
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.liveIndicator,
                height: 1.1,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 24),
            tooltip: 'البحث عن فريق',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 24),
            tooltip: 'الإعدادات',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Date Tabs / Custom Date Selector Bar
            _buildDateHeader(context, ref, activeTab, customDate),

            // Filter Chips Row (sitting directly below Date Tabs)
            _buildFilterChipsRow(context, ref, activeFilter),

            // In-session Soft Update Notification Banner
            const SoftUpdateBanner(),

            // Matches List Area
            Expanded(
              child: RefreshIndicator(
                color: AppColors.liveIndicator,
                backgroundColor: AppColors.surface,
                onRefresh: () async {
                  await ref.read(matchesProvider.notifier).refresh();
                },
                child: matchesAsync.when(
                  loading: () => const MatchesSkeleton(),
                  error: (error, stack) => _buildErrorView(context, ref, error),
                  data: (matches) {
                    if (matches.isEmpty) {
                      return _buildEmptyView();
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _pickCustomDate(context, ref),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: activeTab == HomeTab.customDate
                        ? AppColors.liveIndicator
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: activeTab == HomeTab.customDate
                          ? AppColors.liveIndicator
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: activeTab == HomeTab.customDate
                        ? Colors.black
                        : AppColors.liveIndicator,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          if (activeTab == HomeTab.customDate && customDate != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_note, size: 16, color: AppColors.liveIndicator),
                  const SizedBox(width: 6),
                  Text(
                    DateFormatter.formatDisplayDate(customDate),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      ref.read(selectedCustomDateProvider.notifier).setDate(null);
                      ref.read(activeTabProvider.notifier).setTab(HomeTab.today);
                      ref.read(matchesProvider.notifier).refresh();
                    },
                    child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(
              label: 'الكل',
              isActive: activeFilter == MatchFilterType.all,
              onTap: () => ref.read(matchFilterProvider.notifier).setFilter(MatchFilterType.all),
            ),
            const SizedBox(width: 8),
            _buildChip(
              label: 'مباشر',
              icon: Icons.fiber_manual_record,
              iconColor: AppColors.livePulse,
              isActive: activeFilter == MatchFilterType.live,
              onTap: () => ref.read(matchFilterProvider.notifier).setFilter(MatchFilterType.live),
            ),
            const SizedBox(width: 8),
            _buildChip(
              label: 'القادمة',
              isActive: activeFilter == MatchFilterType.upcoming,
              onTap: () => ref.read(matchFilterProvider.notifier).setFilter(MatchFilterType.upcoming),
            ),
            const SizedBox(width: 8),
            _buildChip(
              label: 'المفضلة',
              icon: Icons.star_rounded,
              iconColor: Colors.amber,
              isActive: activeFilter == MatchFilterType.favorites,
              onTap: () => ref.read(matchFilterProvider.notifier).setFilter(MatchFilterType.favorites),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    IconData? icon,
    Color? iconColor,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.liveIndicator : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.liveIndicator : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: isActive ? Colors.black : (iconColor ?? AppColors.textSecondary),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
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
          ref.read(selectedCustomDateProvider.notifier).setDate(null);
          ref.read(activeTabProvider.notifier).setTab(tab);
          ref.read(matchesProvider.notifier).refresh();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? AppColors.liveIndicator : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.black : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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
              primary: AppColors.liveIndicator,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
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
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        // 1. Featured / Hero Match Card
        if (featuredMatch != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: const [
                Icon(Icons.star_rounded, size: 18, color: AppColors.liveIndicator),
                SizedBox(width: 6),
                Text(
                  'المباراة المميزة',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          HeroMatchCard(match: featuredMatch),
          const SizedBox(height: 12),
        ],

        // 2. Live Now Section (if there are live matches)
        if (liveMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.livePulse,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'مباشر الآن',
                  style: TextStyle(
                    color: AppColors.livePulse,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.livePulse.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.livePulse.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    DateFormatter.toArabicNumerals(liveMatches.length.toString()),
                    style: const TextStyle(
                      color: AppColors.livePulse,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...liveMatches.map((m) => MatchCard(match: m)),
          const SizedBox(height: 16),
        ],

        // 3. All Grouped Matches
        ...grouped.entries.map((entry) {
          final title = entry.key;
          final champMatches = entry.value;
          final champLogo = champMatches.first.championship.image;

          final List<Widget> items = [];

          // Competition Header
          items.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  if (champLogo != null && champLogo.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: champLogo,
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.emoji_events_outlined,
                        size: 18,
                        color: AppColors.liveIndicator,
                      ),
                    )
                  else
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 18,
                      color: AppColors.liveIndicator,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      DateFormatter.toArabicNumerals(champMatches.length.toString()),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
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

  Widget _buildEmptyView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 400,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.sports_soccer, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text(
              'لا توجد مباريات متوفرة لهذا الفلتر',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'يرجى اختيار فلتر آخر أو تفقّد جدول يوم مختلف',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 400,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.livePulse),
            const SizedBox(height: 16),
            const Text(
              'عذراً، حدث خطأ أثناء جلب البيانات',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(matchesProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.liveIndicator,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/services/user_sync_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/match_model.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../update/widgets/soft_update_banner.dart';
import '../widgets/app_logo.dart';
import '../widgets/banner_ad_widget.dart';
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
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const AppLogo(size: 34, showSubtitle: true, isHorizontal: true),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () => _showSettingsModal(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Date Tabs / Custom Date Selector Bar
            _buildDateHeader(context, ref, activeTab, customDate),

            // In-session Soft Update Notification Banner (collapses if dismissed or not applicable)
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
                    return _buildGroupedMatchesList(context, ref, matches);
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
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
                  width: 42,
                  height: 42,
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
                    size: 22,
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

  Widget _buildGroupedMatchesList(
    BuildContext context,
    WidgetRef ref,
    List<MatchModel> matches,
  ) {
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

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final title = grouped.keys.elementAt(index);
        final champMatches = grouped[title]!;
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
      },
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
              'لا توجد مباريات متوفرة لهذا اليوم',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'يرجى تفقّد جدول يوم آخر أو تحديث القائمة',
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

  void _showSettingsModal(BuildContext context, WidgetRef ref) {
    final uid = ref.read(currentUidProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'إعدادات التطبيق والمزامنة',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Firebase Anonymous UID Info Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'معرف الجلسة السحابية (Firebase UID):',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      uid ?? 'غير متصل (يعمل محلياً)',
                      style: TextStyle(
                        color: uid != null ? AppColors.liveIndicator : AppColors.textSecondary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Manual Cloud Sync Button
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_sync_outlined, color: AppColors.liveIndicator),
                title: const Text(
                  'مزامنة الآن مع السحابة',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'رفع التفضيلات والأندية المختارة إلى Firestore',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.of(bottomSheetContext).pop();
                  try {
                    await ref.read(userSyncServiceProvider).pushLocalToFirestore();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تمت المزامنة بنجاح مع السحابة'),
                          backgroundColor: AppColors.surface,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('فشلت المزامنة: $e'),
                          backgroundColor: AppColors.livePulse,
                        ),
                      );
                    }
                  }
                },
              ),
              const Divider(color: AppColors.divider),

              // Reset Onboarding Debug Option
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restart_alt, color: AppColors.livePulse),
                title: const Text(
                  'إعادة ضبط التهيئة والتهيئة الأولية',
                  style: TextStyle(color: AppColors.livePulse, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'تفريغ البيانات واختبار شاشة الترحيب والإشعارات مجدداً',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.of(bottomSheetContext).pop();
                  await ref.read(onboardingProvider.notifier).resetOnboarding();
                  if (context.mounted) {
                    context.go('/onboarding/notifications');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/localization/app_strings.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/fcm_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/user_sync_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/date_formatter.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/battery_guidance_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Controls visibility of the About Developer entry card in settings.
  static const bool _showAboutDeveloper = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(currentUidProvider);
    final themeMode = ref.watch(themeModeProvider);
    final onboardingState = ref.watch(onboardingProvider);
    final favoriteCount = onboardingState.selectedTeamIds.length;
    final leagueCount = onboardingState.selectedLeagueIds.length;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final textPrimary = isLight
        ? AppColors.lightTextPrimary
        : AppColors.darkTextPrimary;
    final textSecondary = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;
    final textMuted = isLight
        ? AppColors.lightTextMuted
        : AppColors.darkTextMuted;
    final borderColor = isLight
        ? AppColors.lightBorder
        : AppColors.darkBorder;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'إعدادات التطبيق',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          120,
        ),
        children: [
          // 1. Theme / Appearance Section
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                      child: const Icon(
                        Icons.palette_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'المظهر العام',
                      style: AppTypography.titleSmall(color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _buildThemeOption(
                      context,
                      ref,
                      label: 'داكن',
                      icon: Icons.dark_mode_rounded,
                      mode: ThemeMode.dark,
                      isSelected: themeMode == ThemeMode.dark,
                      isLight: isLight,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildThemeOption(
                      context,
                      ref,
                      label: 'فاتح',
                      icon: Icons.light_mode_rounded,
                      mode: ThemeMode.light,
                      isSelected: themeMode == ThemeMode.light,
                      isLight: isLight,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildThemeOption(
                      context,
                      ref,
                      label: 'تلقائي',
                      icon: Icons.settings_brightness_rounded,
                      mode: ThemeMode.system,
                      isSelected: themeMode == ThemeMode.system,
                      isLight: isLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Followed Leagues Management Section
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/settings/leagues');
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إدارة البطولات والفرق المفضلة',
                        style: AppTypography.titleSmall(color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'تحديد وتعديل البطولات والأندية التي تتابعها (${DateFormatter.toArabicNumerals('$leagueCount')} بطولات، ${DateFormatter.toArabicNumerals('$favoriteCount')} أندية)',
                        style: AppTypography.caption(color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Favorite Teams Management Section
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/favorites');
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.gold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إدارة الأندية المفضلة',
                        style: AppTypography.titleSmall(color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'تحديد وتعديل الفرق التي تتابعها (${DateFormatter.toArabicNumerals('$favoriteCount')} محددة)',
                        style: AppTypography.caption(color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Battery & Notification Optimization Guidance
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: () {
              HapticFeedback.lightImpact();
              showBatteryOptimizationDialog(context, isManual: true);
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: const Icon(
                    Icons.battery_charging_full_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعدادات الإشعارات والبطارية',
                        style: AppTypography.titleSmall(color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'إرشادات تحسين وصول التنبيهات في الخلفية لهواتف أندرويد',
                        style: AppTypography.caption(color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // About Developer Section (Premium Featured Card) - Hidden for now
          if (_showAboutDeveloper) ...[
            AppCard(
              isFeatured: true,
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(AppRadii.md),
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/about-developer');
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.xs),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppStrings.aboutDeveloper,
                              style: AppTypography.titleSmall(color: textPrimary)
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: AppRadii.fullRadius,
                              ),
                              child: Text(
                                'Ahmed Elmansy',
                                style:
                                    AppTypography.caption(
                                      color: AppColors.primary,
                                    ).copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.aboutDeveloperSubtitle,
                          style: AppTypography.caption(color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: textMuted,
                    size: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // 4. Cloud Session (UID) Section
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معرف الجلسة السحابية (Firebase UID):',
                  style: AppTypography.caption(color: textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  currentUid ?? 'غير متصل (يعمل محلياً)',
                  style: AppTypography.bodyMedium(
                    color: currentUid != null
                        ? AppColors.primary
                        : textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 5. Cloud Sync Action
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: () async {
              HapticFeedback.lightImpact();
              try {
                await ref.read(userSyncServiceProvider).pushLocalToFirestore();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تمت المزامنة بنجاح'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشلت المزامنة: $e'),
                      backgroundColor: AppColors.live,
                    ),
                  );
                }
              }
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: const Icon(
                    Icons.cloud_sync_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مزامنة الآن مع السحابة',
                        style: AppTypography.titleSmall(color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'رفع التفضيلات والأندية المختارة إلى Firestore',
                        style: AppTypography.caption(color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 6. Reset Onboarding Action
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: () async {
              HapticFeedback.lightImpact();
              await ref.read(onboardingProvider.notifier).resetOnboarding();
              if (context.mounted) {
                context.go('/onboarding/notifications');
              }
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.live.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: const Icon(
                    Icons.restart_alt_rounded,
                    color: AppColors.live,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعادة ضبط التهيئة والتهيئة الأولية',
                        style: AppTypography.titleSmall(color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'تفريغ التفضيلات واختبار شاشات الإشعارات واختيار الدوريات مجدداً',
                        style: AppTypography.caption(color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 7. Fast Test Scheduled Notification Action (Debug Tool)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: () async {
              HapticFeedback.lightImpact();
              await ref
                  .read(notificationServiceProvider)
                  .scheduleTestNotification(seconds: 60);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تمت جدولة إشعار الاختبار بنجاح بعد 60 ثانية',
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختبار تذكير مجدول (بعد دقيقة واحدة)',
                        style: AppTypography.titleSmall(color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'جدولة إشعار بعد 60 ثانية باستخدام مسار Alarms لاختبار ظهور التنبيهات المجدولة',
                        style: AppTypography.caption(color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 8. Safe FCM Test Mode (Phase 2.5 Diagnostic Verification)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: () async {
              HapticFeedback.lightImpact();
              final fcm = ref.read(fcmServiceProvider);
              final isCurrentlyEnabled = await fcm.isTestNotificationTopicEnabled();

              if (!context.mounted) return;

              showModalBottomSheet(
                context: context,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
                ),
                builder: (ctx) {
                  bool isEnabled = isCurrentlyEnabled;
                  bool isLoading = false;
                  String? lastTokenPreview;

                  return StatefulBuilder(
                    builder: (modalCtx, setModalState) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('🧪', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'فحص إشعارات FCM الحقيقية (Test Mode)',
                                    style: AppTypography.titleMedium(color: textPrimary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'للاختبار الآمن دون إزعاج المستخدمين الحقيقيين، يتم توجيه رسائل الاختبار حصرياً إلى قناة مخصصة:',
                              style: AppTypography.caption(color: textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: isLight ? AppColors.lightSurfaceHigh : AppColors.darkSurfaceHigh,
                                borderRadius: BorderRadius.circular(AppRadii.xs),
                                border: Border.all(color: borderColor),
                              ),
                              child: const SelectableText(
                                FcmService.testNotificationTopic,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isEnabled ? 'حالة الاشتراك: مفعل ✅' : 'حالة الاشتراك: غير مفعل 🛑',
                                  style: AppTypography.bodySmall(
                                    color: isEnabled ? AppColors.live : textSecondary,
                                  ),
                                ),
                                if (isLoading)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else
                                  Switch(
                                    value: isEnabled,
                                    activeTrackColor: AppColors.primary,
                                    onChanged: (val) async {
                                      setModalState(() => isLoading = true);
                                      if (val) {
                                        final token = await fcm.enableTestNotificationTopic();
                                        setModalState(() {
                                          isEnabled = true;
                                          isLoading = false;
                                          if (token != null && token.length > 16) {
                                            lastTokenPreview = '${token.substring(0, 8)}...${token.substring(token.length - 8)}';
                                          }
                                        });
                                      } else {
                                        await fcm.disableTestNotificationTopic();
                                        setModalState(() {
                                          isEnabled = false;
                                          isLoading = false;
                                          lastTokenPreview = null;
                                        });
                                      }
                                    },
                                  ),
                              ],
                            ),
                            if (lastTokenPreview != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'رمز التسجيل (FCM Token جزئي للتشخيص): $lastTokenPreview',
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'خطوات التحقق:\n1. قم بتفعيل الخيار أعلاه للاشتراك.\n2. شغّل أمر الإرسال من مجلد Watcher:\n   npm run test:push\n3. سيصلك إشعار فوري حقيقي لتأكيد المسار.',
                              style: AppTypography.caption(color: textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: const Icon(
                    Icons.cell_tower_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'فحص إشعارات FCM الحقيقية (Test Mode)',
                        style: AppTypography.titleSmall(color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'الاشتراك في قناة الاختبار الآمنة لاستقبال إشعارات تجريبية دون التأثير على المستخدمين',
                        style: AppTypography.caption(color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 9. App Version Footer
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Center(
                  child: Text(
                    'الإصدار ${DateFormatter.toArabicNumerals(snapshot.data!.version)} (${DateFormatter.toArabicNumerals(snapshot.data!.buildNumber)})',
                    style: AppTypography.caption(color: textMuted),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
    required bool isLight,
  }) {
    final unselectedBg = isLight
        ? AppColors.lightSurfaceHigh
        : AppColors.darkSurfaceHigh;
    final unselectedBorder = isLight
        ? AppColors.lightBorder
        : AppColors.darkBorder;
    final unselectedColor = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(themeModeProvider.notifier).setThemeMode(mode);
        },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : unselectedBg,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
              color: isSelected ? AppColors.primary : unselectedBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : unselectedColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption(
                  color: isSelected ? AppColors.primary : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

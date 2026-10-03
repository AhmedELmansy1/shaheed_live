import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/services/auth_service.dart';
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

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(currentUidProvider);
    final themeMode = ref.watch(themeModeProvider);
    final onboardingState = ref.watch(onboardingProvider);
    final favoriteCount = onboardingState.selectedTeamIds.length;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('إعدادات التطبيق'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
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
                      style: AppTypography.titleSmall(color: AppColors.darkTextPrimary),
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
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildThemeOption(
                      context,
                      ref,
                      label: 'فاتح',
                      icon: Icons.light_mode_rounded,
                      mode: ThemeMode.light,
                      isSelected: themeMode == ThemeMode.light,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildThemeOption(
                      context,
                      ref,
                      label: 'تلقائي',
                      icon: Icons.settings_brightness_rounded,
                      mode: ThemeMode.system,
                      isSelected: themeMode == ThemeMode.system,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Favorite Teams Management Section
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
                        style: AppTypography.titleSmall(color: AppColors.darkTextPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'تحديد وتعديل الفرق التي تتابعها (${DateFormatter.toArabicNumerals('$favoriteCount')} محددة)',
                        style: AppTypography.caption(
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.darkTextMuted,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Cloud Session (UID) Section
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معرف الجلسة السحابية (Firebase UID):',
                  style: AppTypography.caption(
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  currentUid ?? 'غير متصل (يعمل محلياً)',
                  style: AppTypography.bodyMedium(
                    color: currentUid != null ? AppColors.primary : AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 4. Cloud Sync Action
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
                        style: AppTypography.titleSmall(color: AppColors.darkTextPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'رفع التفضيلات والأندية المختارة إلى Firestore',
                        style: AppTypography.caption(
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.darkTextMuted,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 5. Reset Onboarding Action
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
                        style: AppTypography.titleSmall(color: AppColors.darkTextPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'تفريغ التفضيلات واختبار شاشات الإشعارات واختيار الدوريات مجدداً',
                        style: AppTypography.caption(
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.darkTextMuted,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 6. Fast Test Scheduled Notification Action (Debug Tool)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: () async {
              HapticFeedback.lightImpact();
              await ref.read(notificationServiceProvider).scheduleTestNotification(seconds: 60);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تمت جدولة إشعار الاختبار بنجاح بعد 60 ثانية'),
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
                        style: AppTypography.titleSmall(color: AppColors.darkTextPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'جدولة إشعار بعد 60 ثانية باستخدام مسار Alarms لاختبار ظهور التنبيهات المجدولة',
                        style: AppTypography.caption(
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.darkTextMuted,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 7. App Version Footer
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Center(
                  child: Text(
                    'الإصدار ${DateFormatter.toArabicNumerals(snapshot.data!.version)} (${DateFormatter.toArabicNumerals(snapshot.data!.buildNumber)})',
                    style: AppTypography.caption(
                      color: AppColors.darkTextMuted,
                    ),
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
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(themeModeProvider.notifier).setThemeMode(mode);
        },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.darkSurfaceHigh,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.darkBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.darkTextSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption(
                  color: isSelected ? AppColors.primary : AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_sync_service.dart';
import '../../core/theme/app_colors.dart';
import '../onboarding/providers/onboarding_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Widget _buildSectionCard({required Widget child}) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(currentUidProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('إعدادات التطبيق'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'معرف الجلسة السحابية (Firebase UID):',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentUid ?? 'غير متصل (يعمل محلياً)',
                  style: TextStyle(
                    color: currentUid != null ? AppColors.liveIndicator : AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cloud_sync_outlined, color: AppColors.liveIndicator),
              title: const Text(
                'مزامنة الآن مع السحابة',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'رفع التفضيلات والأندية المختارة إلى Firestore',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              onTap: () async {
                try {
                  await ref.read(userSyncServiceProvider).pushLocalToFirestore();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تمت المزامنة بنجاح'),
                        backgroundColor: AppColors.liveIndicator,
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
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restart_alt, color: AppColors.livePulse),
              title: const Text(
                'إعادة ضبط التهيئة والتهيئة الأولية',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'تفريغ البيانات واختبار شاشة الترحيب والإشعارات مجدداً',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              onTap: () async {
                await ref.read(onboardingProvider.notifier).resetOnboarding();
                if (context.mounted) {
                  context.go('/onboarding/notifications');
                }
              },
            ),
          ),
          const SizedBox(height: 32),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Center(
                  child: Text(
                    'الإصدار ${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
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
}

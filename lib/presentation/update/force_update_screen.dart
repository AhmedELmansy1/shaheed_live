import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/update_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../widgets/app_logo.dart';

/// Full-screen, non-dismissible Hard Block screen displayed when the current app
/// version is below minimum supported version or when a force update is active.
class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});

  Future<void> _launchUpdateUrl(BuildContext context, String url) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رابط التحديث غير متوفر حالياً، يرجى مراجعة متجر التطبيقات'),
          backgroundColor: AppColors.livePulse,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح رابط التحديث، يرجى المحاولة لاحقاً'),
            backgroundColor: AppColors.livePulse,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء فتح الرابط: $e'),
            backgroundColor: AppColors.livePulse,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateInfo = ref.watch(appUpdateInfoProvider);

    return PopScope(
      // Strictly prevent user from dismissing or bypassing via hardware/gesture back
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Intercept back gesture — do nothing to keep user on force update screen
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // App Logo
                const Center(
                  child: AppLogo(size: 48, showSubtitle: true),
                ),
                const SizedBox(height: 36),

                // Update Icon Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.liveIndicator.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.liveIndicator.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 56,
                      color: AppColors.liveIndicator,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Title
                const Text(
                  'تحديث مهم متوفر للتطبيق',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle / Description
                const Text(
                  'تم إطلاق إصدار جديد من "شوت لايف" يتضمن تحسينات وميزات مهمة. يرجى التحديث للمتابعة والاستمتاع بجميع خدمات التطبيق.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                // Version comparison badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'الإصدار الحالي',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormatter.toArabicNumerals('v${updateInfo.currentVersion}'),
                            style: const TextStyle(
                              color: AppColors.livePulse,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 28, color: AppColors.cardBorder),
                      Column(
                        children: [
                          const Text(
                            'الإصدار المطلوب',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormatter.toArabicNumerals('v${updateInfo.latestVersion}'),
                            style: const TextStyle(
                              color: AppColors.liveIndicator,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Update Now Action Button
                ElevatedButton.icon(
                  onPressed: () => _launchUpdateUrl(context, updateInfo.updateDownloadUrl),
                  icon: const Icon(Icons.download_rounded, color: Colors.black),
                  label: const Text(
                    'تحديث الآن',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.liveIndicator,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

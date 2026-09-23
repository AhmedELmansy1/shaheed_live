import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/update_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';

/// Dismissible in-session banner displayed when an optional (soft) app update is available.
class SoftUpdateBanner extends ConsumerWidget {
  const SoftUpdateBanner({super.key});

  Future<void> _launchUpdateUrl(BuildContext context, String url) async {
    if (url.trim().isEmpty) return;
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateInfo = ref.watch(appUpdateInfoProvider);
    final isDismissed = ref.watch(softPromptDismissedProvider);

    // Only display if soft prompt is active and not yet dismissed in current session
    if (!updateInfo.isSoftPrompt || isDismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.liveIndicator.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.liveIndicator.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.new_releases_outlined,
              size: 18,
              color: AppColors.liveIndicator,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'يتوفر تحديث جديد للتطبيق',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'الإصدار الجديد: ${DateFormatter.toArabicNumerals("v${updateInfo.latestVersion}")}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Update action button
          InkWell(
            onTap: () => _launchUpdateUrl(context, updateInfo.updateDownloadUrl),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.liveIndicator,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'تحديث',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Dismiss (X) button
          InkWell(
            onTap: () {
              ref.read(softPromptDismissedProvider.notifier).dismiss();
            },
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.close,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

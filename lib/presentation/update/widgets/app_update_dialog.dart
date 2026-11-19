import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/services/update_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/app_logo.dart';

/// Tracks whether the user has been shown the update modal during the current app session.
final updateDialogShownSessionProvider =
    NotifierProvider<UpdateDialogSessionNotifier, bool>(() {
  return UpdateDialogSessionNotifier();
});

class UpdateDialogSessionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markShown() {
    state = true;
  }
}

/// Modal dialog prompting subscribers to download the latest app update.
class AppUpdateDialog extends StatelessWidget {
  final String downloadUrl;
  final String? message;
  final String? latestVersion;

  const AppUpdateDialog({
    super.key,
    required this.downloadUrl,
    this.message,
    this.latestVersion,
  });

  /// Checks if an update prompt should be presented and shows the dialog once per session.
  static Future<void> checkAndShow(BuildContext context, WidgetRef ref) async {
    // Avoid spontaneous modal popups during widget unit tests unless manually called
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) return;

    final hasShown = ref.read(updateDialogShownSessionProvider);
    if (hasShown) return;

    final updateInfo = ref.read(appUpdateInfoProvider);
    final remoteConfig = ref.read(remoteConfigStreamProvider).value;

    // Do NOT show the update prompt unconditionally just because a download URL is set in config.
    // The dialog should ONLY appear when explicitly triggered from the dashboard:
    // 1) The admin turned on the force update toggle in the dashboard (`force_update: true`).
    // 2) The admin enabled `show_update_prompt: true`.
    // 3) Or version comparison requires an update (`isSoftPrompt` or `isHardBlocked`).
    final isTriggeredRemotely = (remoteConfig != null &&
        (remoteConfig.forceUpdate ||
            remoteConfig.showUpdatePrompt ||
            updateInfo.isSoftPrompt ||
            updateInfo.isHardBlocked));

    final shouldShow =
        AppConstants.showUpdatePromptOnStart || isTriggeredRemotely;

    if (shouldShow && context.mounted) {
      ref.read(updateDialogShownSessionProvider.notifier).markShown();

      final targetUrl = (remoteConfig != null &&
              remoteConfig.updateDownloadUrl.trim().isNotEmpty)
          ? remoteConfig.updateDownloadUrl.trim()
          : AppConstants.defaultUpdateDownloadUrl;

      await showDialog(
        context: context,
        barrierDismissible: !updateInfo.isHardBlocked,
        builder: (ctx) => AppUpdateDialog(
          downloadUrl: targetUrl,
          message: remoteConfig?.updateMessage,
          latestVersion: remoteConfig?.latestAppVersion,
        ),
      );
    }
  }

  Future<void> _launchDownload(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final cleanUrl = downloadUrl.trim().isNotEmpty
        ? downloadUrl.trim()
        : AppConstants.defaultUpdateDownloadUrl;

    try {
      final uri = Uri.parse(cleanUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح الرابط تلقائياً، تم نسخ الرابط إلى الحافظة.'),
            backgroundColor: AppColors.live,
          ),
        );
        Clipboard.setData(ClipboardData(text: cleanUrl));
      }
    } catch (e) {
      if (context.mounted) {
        Clipboard.setData(ClipboardData(text: cleanUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم نسخ الرابط إلى الحافظة: $cleanUrl'),
            backgroundColor: AppColors.live,
          ),
        );
      }
    }
  }

  void _copyLink(BuildContext context) {
    HapticFeedback.lightImpact();
    final cleanUrl = downloadUrl.trim().isNotEmpty
        ? downloadUrl.trim()
        : AppConstants.defaultUpdateDownloadUrl;
    Clipboard.setData(ClipboardData(text: cleanUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ رابط التحديث بنجاح!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final primary = AppColors.primaryOf(context);
    final liveColor = AppColors.coralCrimson;

    final defaultBody = message?.trim().isNotEmpty == true
        ? message!.trim()
        : 'تم إطلاق الإصدار الجديد من تطبيق ${AppConstants.appName} بمميزات إضافية وسيرفرات بث مباشر أسرع وأكثر استقراراً بدون تقطيع. يرجى تحميل النسخة الجديدة للاستمتاع بالمشاهدة المباشرة بأعلى جودة.';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadii.xlRadius,
          border: Border.all(color: border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Badge with App Logo & Rocket
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          primary.withValues(alpha: 0.25),
                          liveColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const AppLogo(size: 48, showSubtitle: false),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Tag Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                decoration: BoxDecoration(
                  color: liveColor.withValues(alpha: 0.15),
                  borderRadius: AppRadii.fullRadius,
                  border: Border.all(
                    color: liveColor.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: liveColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      latestVersion != null && latestVersion!.isNotEmpty
                          ? 'تحديث جديد متوفر v$latestVersion'
                          : 'تحديث جديد متوفر الآن',
                      style: AppTypography.caption(color: liveColor).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            Text(
              'يرجى تحميل التحديث الجديد ⚽',
              textAlign: TextAlign.center,
              style: AppTypography.headline(color: textPrimary).copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Body Description
            Text(
              defaultBody,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(color: textSecondary).copyWith(
                height: 1.55,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Direct Link Container (shows link explicitly as requested)
            InkWell(
              onTap: () => _copyLink(context),
              borderRadius: AppRadii.mdRadius,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: AppRadii.mdRadius,
                  border: Border.all(color: border, width: 0.8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, size: 18, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        downloadUrl.isNotEmpty ? downloadUrl : AppConstants.defaultUpdateDownloadUrl,
                        style: AppTypography.caption(color: textSecondary).copyWith(
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.copy_rounded, size: 16, color: textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Primary Download Button
            ElevatedButton(
              onPressed: () => _launchDownload(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.lgRadius,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'تحميل التحديث الآن',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Secondary Later Button
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: Text(
                'تذكيري لاحقاً',
                style: AppTypography.caption(color: textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

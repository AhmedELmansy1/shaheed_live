import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/update_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
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
          backgroundColor: AppColors.live,
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
            backgroundColor: AppColors.live,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء فتح الرابط: $e'),
            backgroundColor: AppColors.live,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateInfo = ref.watch(appUpdateInfoProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // App Logo with Hero tag
                const Center(
                  child: Hero(
                    tag: 'app_brand_logo',
                    child: AppLogo(size: 64, showSubtitle: true),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Update Icon Badge with glow
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.primaryGlow,
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 52,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Title
                Text(
                  'تحديث مهم متوفر للتطبيق',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: AppColors.darkTextPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Subtitle
                Text(
                  'تم إطلاق إصدار جديد من "شوت لايف" يتضمن تحسينات وميزات مهمة. يرجى التحديث للمتابعة والاستمتاع بجميع خدمات التطبيق.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Version comparison badge
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  margin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'الإصدار الحالي',
                            style: AppTypography.caption(color: AppColors.darkTextMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormatter.toArabicNumerals('v${updateInfo.currentVersion}'),
                            style: const TextStyle(
                              color: AppColors.live,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 32, color: AppColors.darkDivider),
                      Column(
                        children: [
                          Text(
                            'الإصدار المطلوب',
                            style: AppTypography.caption(color: AppColors.darkTextMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormatter.toArabicNumerals('v${updateInfo.latestVersion}'),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Update Now Action Button with brand gradient
                AppButton(
                  label: 'تحديث الآن',
                  icon: Icons.download_rounded,
                  onPressed: () => _launchUpdateUrl(context, updateInfo.updateDownloadUrl),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/battery_optimization_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

/// Shows the aggressive OEM battery optimization guidance dialog.
Future<void> showBatteryOptimizationDialog(
  BuildContext context, {
  bool isManual = false,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => Consumer(
      builder: (context, ref, child) {
        final batteryService = ref.read(batteryOptimizationServiceProvider);
        final isLight = Theme.of(context).brightness == Brightness.light;

        final dialogBg = isLight
            ? AppColors.lightSurface
            : AppColors.darkSurface;
        final titleColor = isLight
            ? AppColors.lightTextPrimary
            : AppColors.darkTextPrimary;
        final bodyColor = isLight
            ? AppColors.lightTextSecondary
            : AppColors.darkTextSecondary;
        final borderColor = isLight
            ? AppColors.lightBorder
            : AppColors.darkBorder;
        final boxColor = isLight
            ? AppColors.lightSurfaceHigh
            : AppColors.darkSurfaceHigh;

        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            side: BorderSide(color: borderColor, width: 1),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.battery_charging_full_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'تحسين وصول الإشعارات والتنبيهات',
                  style: GoogleFonts.cairo(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لضمان وصول إشعارات الأهداف وتنبيهات المباريات لحظياً ودون تأخير من نظام توفير الطاقة عند إغلاق الشاشة، يُنصح بضبط استثناء البطارية.',
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: bodyColor,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'تنبيه لمستخدمي شاومي / هواوي / أوبو:',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isLight
                                  ? AppColors.lightTextPrimary
                                  : AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'قد تحتاج أيضاً لتفعيل خيار "التشغيل التلقائي" (Autostart) واختيار "لا توجد قيود" في توفير الطاقة من إعدادات التطبيق لضمان التنبيهات أثناء النوم العميق للجهاز.',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: bodyColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            if (!isManual)
              TextButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await batteryService.markNeverShowAgain();
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: Text(
                  'لا تذكرني مرة أخرى',
                  style: GoogleFonts.cairo(
                    color: AppColors.textMutedOf(dialogContext),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'إغلاق',
                  style: GoogleFonts.cairo(
                    color: AppColors.textMutedOf(dialogContext),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await batteryService.openAppSystemSettings();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                  child: Text(
                    'إعدادات التطبيق',
                    style: GoogleFonts.cairo(
                      color: titleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await batteryService.requestIgnoreBatteryOptimizations();
                    await batteryService.markSeen();
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                  child: Text(
                    'استثناء البطارية',
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

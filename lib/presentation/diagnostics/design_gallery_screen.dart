import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_extensions.dart';

/// Design Gallery screen — previews all design tokens, typography, motion,
/// and interactive components in Midnight Stadium.
/// Only reachable under diagnostics (`kEnableDiagnostics`).
class DesignGalleryScreen extends StatelessWidget {
  const DesignGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('معرض عناصر التصميم (Design Gallery)', style: AppTypography.title(color: colors.textPrimary)),
        backgroundColor: colors.background,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Theme Mode Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: AppRadii.mdRadius,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isDark ? 'الوضع الليلي: ستاد منتصف الليل (Midnight Stadium)' : 'الوضع النهاري: ستاد مشرق',
                    style: AppTypography.body(color: colors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 1. Color Palette
            Text('1. لوحة الألوان الأساسية', style: AppTypography.headline(color: colors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ColorChip('خلفية', colors.background, colors.textPrimary, border: colors.border),
                _ColorChip('سطح', colors.surface, colors.textPrimary, border: colors.border),
                _ColorChip('مرتفع', colors.surfaceElevated, colors.textPrimary, border: colors.border),
                _ColorChip('رئيسي أزرق', colors.primary, Colors.white),
                _ColorChip('مباشر برتقالي', colors.live, Colors.white),
                _ColorChip('تحذير', colors.warning, Colors.white),
                _ColorChip('معلومات', colors.info, Colors.white),
                _ColorChip('فوز (أزرق)', colors.winBg, colors.winText, border: colors.winText),
                _ColorChip('تعادل', colors.drawBg, colors.drawText, border: colors.border),
                _ColorChip('خسارة', colors.lossBg, colors.lossText, border: colors.lossText),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // 2. Typography Scale
            Text('2. تدرج الخطوط (Cairo)', style: AppTypography.headline(color: colors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadii.mdRadius,
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('عرض كبير Display 34', style: AppTypography.display(color: colors.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('عنوان رئيسي Headline 24', style: AppTypography.headline(color: colors.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('عنوان فرعي Title 18', style: AppTypography.title(color: colors.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('نص عادي Body 15 — تجربة قراءة مريحة مع دعم كامل للأرقام واللغة العربية',
                      style: AppTypography.body(color: colors.textSecondary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('شارة وتسمية Label 13', style: AppTypography.label(color: colors.primary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('توضيح دقيق Caption 12 · 02:30 م', style: AppTypography.caption(color: colors.textMuted)),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text('أرقام النتائج: ', style: AppTypography.body(color: colors.textSecondary)),
                      Text('٣ : ١', style: AppTypography.score(color: colors.primary)),
                      const SizedBox(width: AppSpacing.md),
                      Text('(3 : 1)', style: AppTypography.score(color: colors.textPrimary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 3. Buttons & Interaction States
            Text('3. الأزرار وحالات التفاعل', style: AppTypography.headline(color: colors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: AppRadii.mdRadius),
                  ),
                  onPressed: () {},
                  child: Text('زر رئيسي CTA', style: AppTypography.label(color: colors.onPrimary)),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: AppRadii.mdRadius),
                  ),
                  onPressed: () {},
                  child: Text('زر إطار Outlined', style: AppTypography.label(color: colors.textPrimary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.live.withValues(alpha: 0.15),
                    borderRadius: AppRadii.fullRadius,
                    border: Border.all(color: colors.live),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: colors.live, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('مباشر الآن', style: AppTypography.label(color: colors.live)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // 4. Motion tokens
            Text('4. مدة الحركة (Motion Tokens)', style: AppTypography.headline(color: colors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadii.mdRadius,
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• instant: ${AppMotion.instant.inMilliseconds}ms (حالات فورية/أيقونات)', style: AppTypography.body(color: colors.textSecondary)),
                  Text('• fast: ${AppMotion.fast.inMilliseconds}ms (ظهور شارة)', style: AppTypography.body(color: colors.textSecondary)),
                  Text('• base: ${AppMotion.base.inMilliseconds}ms (تحديد التبويب)', style: AppTypography.body(color: colors.textSecondary)),
                  Text('• page: ${AppMotion.page.inMilliseconds}ms (انتقال الشاشات)', style: AppTypography.body(color: colors.textSecondary)),
                  Text('• slow: ${AppMotion.slow.inMilliseconds}ms (توسع الكارت)', style: AppTypography.body(color: colors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip(this.label, this.bg, this.fg, {this.border});

  final String label;
  final Color bg;
  final Color fg;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.smRadius,
        border: border != null ? Border.all(color: border!) : null,
      ),
      child: Center(
        child: Text(
          label,
          style: AppTypography.caption(color: fg),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

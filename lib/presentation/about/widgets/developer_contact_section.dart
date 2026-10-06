import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/developer_profile.dart';
import '../../widgets/app_card.dart';

class DeveloperContactSection extends StatelessWidget {
  final SocialLinks social;

  const DeveloperContactSection({super.key, required this.social});

  Future<void> _launch(BuildContext context, String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح الرابط، يرجى المحاولة مرة أخرى'),
            backgroundColor: AppColors.live,
          ),
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label إلى الحافظة: $text'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(
                  Icons.connect_without_contact_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تواصل معي | Let’s Connect',
                      style: AppTypography.titleMedium(color: textPrimary)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'هل لديك فكرة أو مشروع برمجيات؟ دعنا نتحدث!',
                      style: AppTypography.caption(color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Featured WhatsApp Hero Action
        AppCard(
          isFeatured: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          onTap: () {
            HapticFeedback.lightImpact();
            _launch(context, social.whatsappUrl);
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF25D366).withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  color: Color(0xFF25D366),
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تواصل عبر واتساب | Contact Me',
                      style: AppTypography.titleSmall(color: textPrimary)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'محادثة مباشرة لمناقشة المشاريع والأفكار البرمجية',
                      style: AppTypography.caption(color: textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF25D366),
                size: 16,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // GitHub Card
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          onTap: () => _launch(context, social.githubUrl),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighOf(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Icon(Icons.code_rounded, color: textPrimary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GitHub Profile',
                      style: AppTypography.titleSmall(color: textPrimary)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      social.githubUsername,
                      style: AppTypography.caption(color: AppColors.primary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                color: textSecondary,
                tooltip: 'نسخ رابط GitHub',
                onPressed: () =>
                    _copyToClipboard(context, social.githubUrl, 'رابط GitHub'),
              ),
              Icon(Icons.open_in_new_rounded, color: textSecondary, size: 18),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // LinkedIn Card
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          onTap: () => _launch(context, social.linkedinUrl),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFF0077B5).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0077B5).withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.work_rounded,
                  color: Color(0xFF0077B5),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LinkedIn Profile',
                      style: AppTypography.titleSmall(color: textPrimary)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      social.linkedinUsername,
                      style: AppTypography.caption(
                        color: const Color(0xFF0077B5),
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                color: textSecondary,
                tooltip: 'نسخ رابط LinkedIn',
                onPressed: () => _copyToClipboard(
                  context,
                  social.linkedinUrl,
                  'رابط LinkedIn',
                ),
              ),
              Icon(Icons.open_in_new_rounded, color: textSecondary, size: 18),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Email Card
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          onTap: () => _launch(context, 'mailto:${social.email}'),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.alternate_email_rounded,
                  color: AppColors.accentCyan,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'البريد الإلكتروني | Email',
                      style: AppTypography.titleSmall(color: textPrimary)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      social.email,
                      style: AppTypography.caption(color: textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                color: textSecondary,
                tooltip: 'نسخ البريد الإلكتروني',
                onPressed: () => _copyToClipboard(
                  context,
                  social.email,
                  'البريد الإلكتروني',
                ),
              ),
              Icon(Icons.open_in_new_rounded, color: textSecondary, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

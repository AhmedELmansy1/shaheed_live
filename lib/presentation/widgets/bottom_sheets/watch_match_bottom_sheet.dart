import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../app_card.dart';

class WatchMatchBottomSheet extends StatelessWidget {
  const WatchMatchBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (context) => const WatchMatchBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: AppRadii.fullRadius,
                  ),
                ),
              ),

              Text(
                'اختر موقع المشاهدة',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge(color: textPrimary),
              ),
              const SizedBox(height: AppSpacing.xl),

              _buildSourceCard(
                context: context,
                title: 'LiveHDTV25',
                icon: Icons.sports_soccer_rounded,
                url: 'https://www.livehdtv25.com/',
              ),
              const SizedBox(height: AppSpacing.md),

              _buildSourceCard(
                context: context,
                title: 'Koora TV',
                icon: Icons.tv_rounded,
                url: 'https://kooratv.club/',
              ),
              const SizedBox(height: AppSpacing.md),

              _buildSourceCard(
                context: context,
                title: 'Fel3arda',
                icon: Icons.play_circle_filled_rounded,
                url: 'https://fel3arda.pics/',
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String url,
  }) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      onTap: () => _launchURL(context, url),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium(color: textPrimary)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'فتح موقع المشاهدة',
                  style: AppTypography.caption(color: textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: textSecondary, size: 16),
        ],
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح الموقع، حاول مرة أخرى.'),
            backgroundColor: AppColors.live,
          ),
        );
      }
    }
  }
}

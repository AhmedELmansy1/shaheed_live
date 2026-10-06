import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/developer_profile.dart';
import '../../widgets/app_card.dart';

class DeveloperBioCard extends StatefulWidget {
  final DeveloperProfile profile;

  const DeveloperBioCard({super.key, required this.profile});

  @override
  State<DeveloperBioCard> createState() => _DeveloperBioCardState();
}

class _DeveloperBioCardState extends State<DeveloperBioCard> {
  bool _isArabic = true;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(
                  Icons.person_pin_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'نبذة مهنية | Professional Bio',
                  style: AppTypography.titleSmall(color: textPrimary)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              // Language switch pills
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighOf(context),
                  borderRadius: AppRadii.fullRadius,
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLangButton('عربي', _isArabic),
                    _buildLangButton('EN', !_isArabic),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: AppMotion.standard,
            child: Text(
              _isArabic ? widget.profile.bioAr : widget.profile.bioEn,
              key: ValueKey<bool>(_isArabic),
              textAlign: _isArabic ? TextAlign.right : TextAlign.left,
              style: AppTypography.bodyLarge(color: textSecondary)
                  .copyWith(height: 1.6, letterSpacing: _isArabic ? 0.0 : 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangButton(String text, bool active) {
    return GestureDetector(
      onTap: () {
        if (!active) {
          HapticFeedback.selectionClick();
          setState(() {
            _isArabic = !_isArabic;
          });
        }
      },
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadii.fullRadius,
        ),
        child: Text(
          text,
          style: AppTypography.caption(
            color: active ? Colors.black : AppColors.textSecondaryOf(context),
          ).copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

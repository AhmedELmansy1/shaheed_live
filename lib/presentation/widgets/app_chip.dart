import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

/// Design system animated filter chip / pill with subtle hierarchy.
class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;
  final Widget? trailing;

  const AppChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.iconColor,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight(context);
    final unselectedBg = isLight
        ? AppColors.lightSurfaceHigh
        : AppColors.darkSurfaceHigh;
    final unselectedBorder = isLight
        ? AppColors.lightBorder
        : AppColors.darkBorder;
    final unselectedText = isLight
        ? AppColors.lightTextPrimary
        : AppColors.darkTextPrimary;
    final unselectedIcon = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standardCurve,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : unselectedBg,
          borderRadius: AppRadii.fullRadius,
          border: Border.all(
            color: isSelected ? AppColors.primary : unselectedBorder,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: 6,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.xs),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: isSelected
                    ? Colors.black
                    : (iconColor ?? unselectedIcon),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: GoogleFonts.cairo(
                color: isSelected ? Colors.black : unselectedText,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.0,
                height: 1.15,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.xs),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_typography.dart';

/// Design system filter chip / pill in "Paper × Ink × Vermilion".
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = isDark
        ? AppColors.darkSurfaceElevated
        : const Color(0xFF14161C);
    final selectedFg = isDark
        ? AppColors.darkTextPrimary
        : Colors.white;

    final unselectedBg = AppColors.surfaceOf(context);
    final unselectedBorder = AppColors.borderOf(context);
    final unselectedFg = AppColors.textSecondaryOf(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'فلتر $label',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : unselectedBg,
            borderRadius: AppRadii.fullRadius,
            border: Border.all(
              color: isSelected ? selectedBg : unselectedBorder,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? selectedFg : (iconColor ?? unselectedFg),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTypography.labelLarge(
                  color: isSelected ? selectedFg : unselectedFg,
                ).copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

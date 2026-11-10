import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Clean, editorial Bottom Navigation Dock in "Paper × Ink × Vermilion".
///
/// Features:
/// - Tactile surface boundary with crisp 1px border (NO neon glows, NO heavy blur).
/// - Distinct active state in vermilion accent with subtle capsule indicator.
/// - Minimum 48dp touch targets per tab.
/// - Full RTL layout support.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _onTap(int index) {
    if (index != navigationShell.currentIndex) {
      HapticFeedback.lightImpact();
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final bg = AppColors.backgroundOf(context);
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final primary = AppColors.primaryOf(context);

    return Scaffold(
      backgroundColor: bg,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            border: Border(top: BorderSide(color: border, width: 1.0)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  currentIndex: currentIndex,
                  label: 'الرئيسية',
                  activeIcon: Icons.sports_soccer_rounded,
                  inactiveIcon: Icons.sports_soccer_outlined,
                  primaryColor: primary,
                  inactiveColor: textSecondary,
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  currentIndex: currentIndex,
                  label: 'الدوريات',
                  activeIcon: Icons.emoji_events_rounded,
                  inactiveIcon: Icons.emoji_events_outlined,
                  primaryColor: primary,
                  inactiveColor: textSecondary,
                ),
                _buildNavItem(
                  context,
                  index: 2,
                  currentIndex: currentIndex,
                  label: 'القنوات',
                  activeIcon: Icons.live_tv_rounded,
                  inactiveIcon: Icons.live_tv_outlined,
                  primaryColor: primary,
                  inactiveColor: textSecondary,
                ),
                _buildNavItem(
                  context,
                  index: 3,
                  currentIndex: currentIndex,
                  label: 'الإعدادات',
                  activeIcon: Icons.settings_rounded,
                  inactiveIcon: Icons.settings_outlined,
                  primaryColor: primary,
                  inactiveColor: textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required Color primaryColor,
    required Color inactiveColor,
  }) {
    final isSelected = index == currentIndex;
    final iconColor = isSelected ? primaryColor : inactiveColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.mdRadius,
          onTap: () => _onTap(index),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    color: iconColor,
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: AppTypography.labelSmall(color: iconColor).copyWith(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

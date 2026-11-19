import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

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
    final primary = AppColors.primaryOf(context);
    final surface = AppColors.surfaceOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: bottomPad + 16,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: surface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: primary.withValues(alpha: 0.18),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: isSelected
                ? Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 1.0,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  key: ValueKey(isSelected),
                  color: isSelected ? primaryColor : inactiveColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.labelSmall(
                  color: isSelected ? primaryColor : inactiveColor,
                ).copyWith(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

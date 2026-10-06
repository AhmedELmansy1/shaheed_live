import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

/// Floating Glassmorphic Bottom Navigation Dock with luminous glow and smooth sliding tab indicator.
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
    final isLight = AppColors.isLight(context);
    final bg = AppColors.backgroundOf(context);
    final dockBg = isLight
        ? AppColors.lightSurface.withValues(alpha: 0.92)
        : AppColors.darkSurface.withValues(alpha: 0.90);
    final dockBorder = isLight ? AppColors.lightBorder : AppColors.darkBorder;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: bg,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: ClipRRect(
            borderRadius: AppRadii.xxlRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: dockBg,
                  borderRadius: AppRadii.xxlRadius,
                  border: Border.all(color: dockBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: isLight
                          ? Colors.black.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.50),
                      blurRadius: isLight ? 16 : 20,
                      offset: const Offset(0, 8),
                    ),
                    if (!isLight)
                      const BoxShadow(
                        color: AppColors.primaryGlow,
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / 3;
                    final highlightLeft = isRtl
                        ? (2 - currentIndex) * itemWidth + 4
                        : currentIndex * itemWidth + 4;

                    return Stack(
                      children: [
                        // Sliding highlight capsule indicator
                        AnimatedPositioned(
                          duration: AppMotion.standard,
                          curve: Curves.easeOutCubic,
                          left: highlightLeft,
                          top: 2,
                          bottom: 2,
                          width: itemWidth - 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(
                                alpha: isLight ? 0.16 : 0.18,
                              ),
                              borderRadius: AppRadii.xlRadius,
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: isLight ? 0.45 : 0.40,
                                ),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGlow,
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Interactive Tab Items with Animated Transitions
                        Row(
                          children: [
                            _buildNavItem(
                              context: context,
                              index: 0,
                              icon: Icons.home_outlined,
                              activeIcon: Icons.home_rounded,
                              label: 'الرئيسية',
                              isSelected: currentIndex == 0,
                            ),
                            _buildNavItem(
                              context: context,
                              index: 1,
                              icon: Icons.emoji_events_outlined,
                              activeIcon: Icons.emoji_events_rounded,
                              label: 'الدوريات',
                              isSelected: currentIndex == 1,
                            ),
                            _buildNavItem(
                              context: context,
                              index: 2,
                              icon: Icons.settings_outlined,
                              activeIcon: Icons.settings_rounded,
                              label: 'الإعدادات',
                              isSelected: currentIndex == 2,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
  }) {
    final isLight = AppColors.isLight(context);
    final unselectedColor = isLight
        ? AppColors.lightTextMuted
        : AppColors.darkTextMuted;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.12 : 1.0,
              duration: AppMotion.fast,
              curve: Curves.easeOutBack,
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey('${index}_$isSelected'),
                  size: 21,
                  color: isSelected ? AppColors.primary : unselectedColor,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: AppMotion.fast,
              style: GoogleFonts.cairo(
                color: isSelected ? AppColors.primary : unselectedColor,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: 0.0,
                height: 1.1,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

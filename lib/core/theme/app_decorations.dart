import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';

/// Design Token Decorations for the "Paper × Ink × Vermilion" design system.
///
/// Editorial, tactile, and restrained:
/// - Crisp 1px borders (#E6E1D8 in light, #2A2F3A in dark).
/// - Clean paper surfaces without heavy glassmorphism or neon glows.
/// - Live accent via a crisp vermilion edge or subtle stroke.
class AppDecorations {
  /// Primary card decoration in the Paper × Ink aesthetic.
  static BoxDecoration card({
    required BuildContext context,
    bool isLive = false,
    bool isFeatured = false,
    Color? customBorderColor,
    BorderRadius? borderRadius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadii.mdRadius;
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = isLive
        ? AppColors.primaryOf(context)
        : (customBorderColor ?? AppColors.borderOf(context));

    return BoxDecoration(
      color: surfaceColor,
      borderRadius: radius,
      border: Border.all(
        color: borderColor,
        width: isLive ? 1.5 : 1.0,
      ),
      boxShadow: [
        if (!isDark)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
      ],
    );
  }

  /// Elevated card for featured matches or modals.
  static BoxDecoration elevatedCard({
    required BuildContext context,
    BorderRadius? borderRadius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadii.mdRadius;
    return BoxDecoration(
      color: AppColors.surfaceElevatedOf(context),
      borderRadius: radius,
      border: Border.all(
        color: AppColors.borderOf(context),
        width: 1.0,
      ),
      boxShadow: [
        if (!isDark)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
      ],
    );
  }

  /// Backward-compatibility alias for previous glassCard callers.
  static BoxDecoration glassCard({
    BuildContext? context,
    bool isLive = false,
    bool isFeatured = false,
    Color? customBorderColor,
    BorderRadius? borderRadius,
  }) {
    if (context == null) {
      return BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: borderRadius ?? AppRadii.mdRadius,
        border: Border.all(
          color: customBorderColor ?? AppColors.darkBorder,
          width: isLive ? 1.5 : 1.0,
        ),
      );
    }
    return card(
      context: context,
      isLive: isLive,
      isFeatured: isFeatured,
      customBorderColor: customBorderColor,
      borderRadius: borderRadius,
    );
  }
}

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';

/// Design Token Decorations for the "Dark Sports Broadcast" design system.
///
/// High-craft, broadcast-grade cards:
/// - Elevated multi-layered surfaces with top-edge specular highlights.
/// - Stadium spotlight atmosphere for featured hero cards.
/// - Crisp, subtle borders with active indicators.
class AppDecorations {
  /// Primary broadcast card decoration.
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
        ? AppColors.primaryOf(context).withValues(alpha: 0.8)
        : (customBorderColor ?? AppColors.borderOf(context));

    return BoxDecoration(
      color: surfaceColor,
      borderRadius: radius,
      border: Border.all(
        color: borderColor,
        width: isLive ? 1.5 : 1.0,
      ),
      boxShadow: [
        if (isDark) ...[
          // Subtle ambient depth and top-edge specular reflection
          BoxShadow(
            color: isLive
                ? AppColors.primaryOf(context).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ] else ...[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ],
    );
  }

  /// Broadcast Hero Stadium Card Decoration with atmospheric spotlight gradient
  static BoxDecoration heroStadiumCard({
    required BuildContext context,
    bool isLive = false,
    BorderRadius? borderRadius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadii.lgRadius;

    if (!isDark) {
      return BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: AppColors.lightBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }

    return BoxDecoration(
      borderRadius: radius,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF132244),
          Color(0xFF0F1A33),
          Color(0xFF0A1224),
        ],
        stops: [0.0, 0.45, 1.0],
      ),
      border: Border.all(
        color: isLive ? AppColors.neonEmerald.withValues(alpha: 0.5) : const Color(0xFF263A64),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: isLive
              ? AppColors.neonEmerald.withValues(alpha: 0.12)
              : const Color(0xFF1E3A8A).withValues(alpha: 0.16),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 6),
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
        if (isDark)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        else
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

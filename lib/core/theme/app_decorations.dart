import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';

/// Design Token Decorations for Shoot Live ("Midnight Pitch").
/// Subtle glass, luminous borders, restrained glows, stadium night aesthetics.
class AppDecorations {
  // Glassmorphic Card Decoration (Supports Dark & Light Modes)
  static BoxDecoration glassCard({
    BuildContext? context,
    bool isLive = false,
    bool isFeatured = false,
    Color? customBorderColor,
    BorderRadius? borderRadius,
  }) {
    final isLight =
        context != null && Theme.of(context).brightness == Brightness.light;
    final radius = borderRadius ?? AppRadii.lgRadius;

    if (isLight) {
      if (isLive) {
        return BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: radius,
          border: Border.all(
            color: customBorderColor ?? AppColors.live.withValues(alpha: 0.7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.live.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        );
      }

      if (isFeatured) {
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x1FD4AF37), Color(0x0F2563EB), Color(0xFFFFFFFF)],
            stops: [0.0, 0.45, 1.0],
          ),
          borderRadius: radius,
          border: Border.all(
            color:
                customBorderColor ?? AppColors.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            const BoxShadow(
              color: AppColors.primaryGlow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        );
      }

      return BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: radius,
        border: Border.all(
          color: customBorderColor ?? AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }

    if (isLive) {
      return BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.92),
        borderRadius: radius,
        border: Border.all(
          color: customBorderColor ?? AppColors.live.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          const BoxShadow(
            color: AppColors.liveGlowColor,
            blurRadius: 14,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );
    }

    if (isFeatured) {
      return BoxDecoration(
        gradient: AppColors.heroCardGradient,
        borderRadius: radius,
        border: Border.all(
          color: customBorderColor ?? AppColors.primary.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          const BoxShadow(
            color: AppColors.primaryGlow,
            blurRadius: 16,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );
    }

    return BoxDecoration(
      color: AppColors.darkSurface,
      borderRadius: radius,
      border: Border.all(
        color: customBorderColor ?? AppColors.darkBorder,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Stadium Light Background Radial Gradient
  static const RadialGradient stadiumGlow = RadialGradient(
    center: Alignment(0.0, -0.4),
    radius: 1.2,
    colors: [
      Color(0xFF0F1B22), // Subtle night pitch mist
      AppColors.darkBackground,
    ],
    stops: [0.0, 1.0],
  );

  // Live Pulse Glow
  static List<BoxShadow> liveGlow({
    Color color = AppColors.live,
    double alpha = 0.25,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: 10,
        spreadRadius: 1,
      ),
    ];
  }
}

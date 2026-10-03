import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radii.dart';

/// Design Token Decorations for Shoot Live ("Midnight Pitch").
/// Subtle glass, luminous borders, restrained glows, stadium night aesthetics.
class AppDecorations {
  // Glassmorphic Card Decoration (Dark Mode)
  static BoxDecoration glassCard({
    bool isLive = false,
    bool isFeatured = false,
    Color? customBorderColor,
    BorderRadius? borderRadius,
  }) {
    final radius = borderRadius ?? AppRadii.lgRadius;

    if (isLive) {
      return BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.92),
        borderRadius: radius,
        border: Border.all(
          color: customBorderColor ?? AppColors.live.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.liveGlowColor,
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkSurfaceHigh,
            AppColors.darkSurface,
          ],
        ),
        borderRadius: radius,
        border: Border.all(
          color: customBorderColor ?? AppColors.gold.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldGlow,
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
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
  static List<BoxShadow> liveGlow({Color color = AppColors.live, double alpha = 0.25}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: 10,
        spreadRadius: 1,
      ),
    ];
  }
}

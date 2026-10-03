import 'package:flutter/widgets.dart';

/// Design Token Motion, Durations, and Curves for Shoot Live.
class AppMotion {
  // Durations: 150 / 250 / 400ms
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration emphasized = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration splash = Duration(milliseconds: 1200);
  static const Duration pulse = Duration(milliseconds: 1400);

  // Curves: easeOutCubic and easeInOutCubic (Emphasized)
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInOutCubicEmphasized = Curves.easeInOutCubic;
  static const Curve springCurve = Curves.elasticOut;
  static const Curve decelerateCurve = Curves.decelerate;
  static const Curve bounceCurve = Curves.easeOutBack;

  /// Helper to check if animations should be skipped or shortened
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  /// Returns 0ms duration if user has reduced motion preference enabled
  static Duration responsiveDuration(BuildContext context, Duration duration) {
    return isReducedMotion(context) ? Duration.zero : duration;
  }
}

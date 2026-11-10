import 'dart:io';
import 'package:flutter/widgets.dart';

/// Design Token Motion — "Midnight Stadium".
///
/// Premium, purposeful, never gimmicky.
/// Rule: respect MediaQuery.disableAnimations and FLUTTER_TEST env.
class AppMotion {
  // ─── Durations ────────────────────────────────────────────────────────────

  /// 90ms — State pops, toggles, icon swaps.
  static const Duration instant = Duration(milliseconds: 90);

  /// 140ms — Badge in/out, quick indicator snaps.
  static const Duration fast = Duration(milliseconds: 140);

  /// 240ms — Chip select, fade transitions, most UI changes.
  static const Duration base = Duration(milliseconds: 240);

  /// 320ms — Page / screen transitions.
  static const Duration page = Duration(milliseconds: 320);

  /// 380ms — Card expand, sheet open, slow reveals.
  static const Duration slow = Duration(milliseconds: 380);

  // Legacy names kept for backward-compat widgets.
  static const Duration standard = base;
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration emphasized = slow;
  static const Duration splash = Duration(milliseconds: 1200);

  /// 1400ms — Live dot breathing pulse. Loops.
  static const Duration pulse = Duration(milliseconds: 1400);

  // ─── Curves ───────────────────────────────────────────────────────────────

  /// Standard — easeOutCubic: used for most transitions.
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve easeOutCubic = Curves.easeOutCubic;

  /// Emphasized — Material 3 emphasized easing (Cubic 0.2,0,0,1).
  /// Used for elements that need extra authority (page enters, hero reveals).
  static const Curve emphasizedCurve = Cubic(0.2, 0, 0, 1);
  static const Curve easeInOutCubicEmphasized = Cubic(0.2, 0, 0, 1);

  /// Spring — easeOutBack, max 4% overshoot — selection pops only.
  static const Curve springCurve = Curves.easeOutBack;
  static const Curve bounceCurve = Curves.easeOutBack;
  static const Curve decelerateCurve = Curves.decelerate;

  // ─── Reduced Motion ───────────────────────────────────────────────────────

  /// True when running under `flutter test` (FLUTTER_TEST env var) or when
  /// the user has enabled the OS-level reduced-motion accessibility setting.
  static bool isReducedMotion(BuildContext context) {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  /// Returns [Duration.zero] when reduced motion is active, otherwise [duration].
  static Duration responsiveDuration(BuildContext context, Duration duration) {
    return isReducedMotion(context) ? Duration.zero : duration;
  }
}

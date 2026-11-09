import 'package:flutter/widgets.dart';

/// Design Token Corner Radii for Live Pulse: 12, 20, 28 (plus 6/8, 32, and full 999).
class AppRadii {
  static const double xs = 6.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 20.0;
  static const double xl = 28.0;
  static const double xxl = 32.0;
  static const double full = 999.0;

  // BorderRadius helpers
  static final BorderRadius xsRadius = BorderRadius.circular(xs);
  static final BorderRadius smRadius = BorderRadius.circular(sm);
  static final BorderRadius mdRadius = BorderRadius.circular(md);
  static final BorderRadius lgRadius = BorderRadius.circular(lg);
  static final BorderRadius xlRadius = BorderRadius.circular(xl);
  static final BorderRadius xxlRadius = BorderRadius.circular(xxl);
  static final BorderRadius fullRadius = BorderRadius.circular(full);
}

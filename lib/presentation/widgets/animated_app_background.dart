import 'package:flutter/material.dart';

/// Clean background wrapper for the "Paper × Ink × Vermilion" design system.
///
/// Ensures solid, tactile paper or ink tone without continuous CPU/GPU ticker drain.
class AnimatedAppBackground extends StatelessWidget {
  final Widget child;

  const AnimatedAppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}

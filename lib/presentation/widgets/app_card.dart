import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

/// Clean, tactile Card component in the "Paper × Ink × Vermilion" design system.
///
/// Features:
/// - Crisp 1px border (#E6E1D8 in light, #2A2F3A in dark).
/// - Gentle, tactile press-down feedback.
/// - Restrained styling without neon glows or heavy drop shadows.
class AppCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isLive;
  final bool isFeatured;
  final BorderRadius? borderRadius;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.isLive = false,
    this.isFeatured = false,
    this.borderRadius,
    this.borderColor,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.985).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null && !AppMotion.isReducedMotion(context)) {
      _pressController.forward();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      _pressController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? AppRadii.mdRadius;

    final cardWidget = Container(
      margin: widget.margin ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs + 1,
          ),
      decoration: AppDecorations.card(
        context: context,
        isLive: widget.isLive,
        isFeatured: widget.isFeatured,
        customBorderColor: widget.borderColor,
        borderRadius: effectiveRadius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: widget.onTap,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          splashColor: AppColors.primaryOf(context).withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: widget.padding ?? AppSpacing.cardPadding,
            child: widget.child,
          ),
        ),
      ),
    );

    if (AppMotion.isReducedMotion(context)) {
      return cardWidget;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: cardWidget,
    );
  }
}

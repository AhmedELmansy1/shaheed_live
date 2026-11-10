import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

/// Design system button in "Paper × Ink × Vermilion" with tactile feedback.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.padding,
    this.gradient,
    this.boxShadow,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed != null &&
        !widget.isLoading &&
        !AppMotion.isReducedMotion(context)) {
      _pressController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color? borderColor;

    final vermilion = AppColors.primaryOf(context);

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = vermilion;
        fg = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bg = AppColors.surfaceElevatedOf(context);
        fg = AppColors.textPrimaryOf(context);
        borderColor = AppColors.borderOf(context);
        break;
      case AppButtonVariant.danger:
        bg = vermilion;
        fg = Colors.white;
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = vermilion;
        break;
    }

    final buttonWidget = Container(
      width: widget.width,
      height: 48,
      decoration: BoxDecoration(
        color: widget.gradient != null
            ? null
            : (widget.onPressed != null ? bg : bg.withValues(alpha: 0.4)),
        gradient: widget.onPressed != null ? widget.gradient : null,
        borderRadius: AppRadii.fullRadius,
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.0)
            : null,
        boxShadow: widget.onPressed != null ? widget.boxShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadii.fullRadius,
        child: InkWell(
          borderRadius: AppRadii.fullRadius,
          onTap: widget.isLoading ? null : widget.onPressed,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: Padding(
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 18, color: fg),
                          const SizedBox(width: AppSpacing.xs + 2),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLarge(color: fg).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    if (AppMotion.isReducedMotion(context)) {
      return buttonWidget;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: buttonWidget,
    );
  }
}

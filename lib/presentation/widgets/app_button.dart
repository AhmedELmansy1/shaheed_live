import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

/// Design system button with tactile haptics, brand gradient, glow, and press-scale animation.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.width,
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: AppMotion.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
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
    Color? bg;
    Gradient? gradient;
    Color fg;
    Color? borderColor;
    List<BoxShadow>? shadows;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        gradient = AppColors.brandGradient;
        fg = const Color(0xFF070B10); // Deep dark contrast on neon gradient
        shadows = [
          const BoxShadow(
            color: AppColors.primaryGlow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ];
        break;
      case AppButtonVariant.secondary:
        bg = AppColors.darkSurfaceHigh;
        fg = AppColors.darkTextPrimary;
        borderColor = AppColors.darkBorder;
        break;
      case AppButtonVariant.danger:
        bg = AppColors.live;
        fg = Colors.white;
        shadows = [
          const BoxShadow(
            color: AppColors.liveGlowColor,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ];
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.primary;
        break;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: bg,
          gradient: gradient,
          borderRadius: AppRadii.mdRadius,
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadii.mdRadius,
          child: InkWell(
            borderRadius: AppRadii.mdRadius,
            onTap: widget.isLoading ? null : widget.onPressed,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: fg,
                      ),
                    )
                  else ...[
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: fg),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          style: TextStyle(
                            color: fg,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

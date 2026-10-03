import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';

/// Pulsing Coral Red LIVE status badge with smooth radar ring and elapsed minute display.
class LiveBadge extends StatefulWidget {
  final String? minuteText;
  final bool isLarge;

  const LiveBadge({
    super.key,
    this.minuteText,
    this.isLarge = false,
  });

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _alphaAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppMotion.pulse,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _alphaAnimation = Tween<double>(begin: 0.8, end: 0.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Only start repeating if not in reduced motion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !AppMotion.isReducedMotion(context)) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.minuteText != null && widget.minuteText!.isNotEmpty
        ? DateFormatter.toArabicNumerals(widget.minuteText!)
        : 'مباشر';

    final dotSize = widget.isLarge ? 8.0 : 6.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isLarge ? AppSpacing.md : AppSpacing.sm,
        vertical: widget.isLarge ? AppSpacing.xs + 1 : AppSpacing.xxs + 1,
      ),
      decoration: BoxDecoration(
        color: AppColors.live.withValues(alpha: 0.15),
        borderRadius: AppRadii.fullRadius,
        border: Border.all(
          color: AppColors.live.withValues(alpha: 0.8),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.liveGlowColor,
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer expanding radar halo
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: dotSize + 6,
                        height: dotSize + 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.live.withValues(alpha: _alphaAnimation.value),
                        ),
                      ),
                    ),
                    // Solid central coral core
                    Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: const BoxDecoration(
                        color: AppColors.live,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(width: widget.isLarge ? AppSpacing.xs + 2 : AppSpacing.xs),
          Text(
            text,
            style: TextStyle(
              color: AppColors.live,
              fontSize: widget.isLarge ? 12.0 : 11.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.0,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

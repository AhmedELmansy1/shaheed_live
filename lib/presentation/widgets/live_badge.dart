import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_number_format.dart';

/// Refined, editorial Live Status Badge in the "Paper × Ink × Vermilion" design system.
///
/// Features:
/// - Striking vermilion hue (#E5482D light, #FF5A3C dark) without garish neon glow.
/// - Calm, rhythmic pulse dot (disabled gracefully under reduced-motion settings).
/// - Tabular Arabic numerals for live elapsed minute.
/// - Screen-reader accessibility semantics.
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

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _opacityAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

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
    final liveColor = AppColors.liveOf(context);
    final isReducedMotion = AppMotion.isReducedMotion(context);

    final rawMinute = widget.minuteText?.trim();
    final hasMinute = rawMinute != null &&
        rawMinute.isNotEmpty &&
        rawMinute != 'لم تبدأ' &&
        rawMinute != 'انتهت';

    final displayText =
        hasMinute ? AppNumberFormat.formatMinute(rawMinute) : 'مباشر';

    final fontSize = widget.isLarge ? 12.0 : 10.5;
    final dotSize = widget.isLarge ? 7.0 : 5.5;

    final badgeContent = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isLarge ? AppSpacing.sm : AppSpacing.xs + 2,
        vertical: widget.isLarge ? AppSpacing.xs : AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: liveColor.withValues(alpha: 0.14),
        borderRadius: AppRadii.fullRadius,
        border: Border.all(
          color: liveColor.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pulse dot
          if (isReducedMotion)
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: liveColor,
                shape: BoxShape.circle,
              ),
            )
          else
            AnimatedBuilder(
              animation: _opacityAnimation,
              builder: (context, child) {
                return Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: liveColor.withValues(
                      alpha: _opacityAnimation.value,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: liveColor.withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            displayText,
            style: AppTypography.labelSmall(color: liveColor).copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: 'مباراة جارية الآن: $displayText',
      child: badgeContent,
    );
  }
}

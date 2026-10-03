import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/utils/date_formatter.dart';

/// Animated high-contrast score widget rendering bold Eastern Arabic numerals with scale & glow animation on update.
class ScoreText extends StatefulWidget {
  final dynamic homeScore;
  final dynamic awayScore;
  final bool isLive;
  final double fontSize;

  const ScoreText({
    super.key,
    required this.homeScore,
    required this.awayScore,
    this.isLive = false,
    this.fontSize = 26,
  });

  @override
  State<ScoreText> createState() => _ScoreTextState();
}

class _ScoreTextState extends State<ScoreText> with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _scaleAnimation;
  String _previousScore = '';

  @override
  void initState() {
    super.initState();
    _previousScore = '${widget.homeScore}-${widget.awayScore}';
    _glowController = AnimationController(vsync: this, duration: AppMotion.standard);
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 50),
    ]).animate(_glowController);
  }

  @override
  void didUpdateWidget(covariant ScoreText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentScore = '${widget.homeScore}-${widget.awayScore}';
    if (currentScore != _previousScore) {
      _previousScore = currentScore;
      if (!AppMotion.isReducedMotion(context)) {
        _glowController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawHome = widget.homeScore != null ? widget.homeScore.toString() : '0';
    final rawAway = widget.awayScore != null ? widget.awayScore.toString() : '0';

    final hScore = DateFormatter.toArabicNumerals(rawHome);
    final aScore = DateFormatter.toArabicNumerals(rawAway);

    final color = widget.isLive ? AppColors.primary : AppColors.darkTextPrimary;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: _glowController.isAnimating
                ? BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Home score (right in RTL)
                Text(
                  hScore,
                  style: GoogleFonts.cairo(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.0,
                    height: 1.15,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '-',
                    style: GoogleFonts.cairo(
                      fontSize: widget.fontSize * 0.75,
                      fontWeight: FontWeight.w700,
                      color: color.withValues(alpha: 0.6),
                      letterSpacing: 0.0,
                      height: 1.15,
                    ),
                  ),
                ),
                // Away score (left in RTL)
                Text(
                  aScore,
                  style: GoogleFonts.cairo(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.0,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

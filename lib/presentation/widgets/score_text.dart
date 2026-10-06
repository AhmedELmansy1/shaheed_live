import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';

/// Animated high-contrast score widget rendering bold Eastern Arabic numerals.
/// Independently tracks home and away scores to aggressively punch the changing number,
/// giving incredible kinetic weight to a goal moment.
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

class _ScoreTextState extends State<ScoreText> {
  @override
  Widget build(BuildContext context) {
    final rawHome = widget.homeScore != null
        ? widget.homeScore.toString()
        : '0';
    final rawAway = widget.awayScore != null
        ? widget.awayScore.toString()
        : '0';

    final hScore = DateFormatter.toArabicNumerals(rawHome);
    final aScore = DateFormatter.toArabicNumerals(rawAway);

    final isLight = Theme.of(context).brightness == Brightness.light;
    final color = widget.isLive
        ? AppColors.primary
        : (isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: RepaintBoundary(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Home score (right in RTL)
            _buildScoreNumber(hScore, color),
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
            _buildScoreNumber(aScore, color),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreNumber(String score, Color color) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.elasticOut, // Springy punch forward
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        // When a goal happens, the new number bursts in from 1.6x scale down to 1.0x
        final scale = Tween<double>(begin: 1.6, end: 1.0).animate(animation);

        // Add a slight color flash (white/primary) during the scale down
        final isNewChild = child.key == ValueKey(score);

        return ScaleTransition(
          scale: isNewChild ? scale : const AlwaysStoppedAnimation(1.0),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(
        score,
        key: ValueKey(
          score,
        ), // Key ensures AnimatedSwitcher triggers when string changes
        style: GoogleFonts.cairo(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.0,
          height: 1.15,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Reusable application logo for Shoot Live (شوت لايف).
///
/// Features a custom painted football emblem with a live indicator ring,
/// paired with the Arabic wordmark and optional English subtitle.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showSubtitle;
  final bool isHorizontal;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showSubtitle = true,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final emblem = CustomPaint(
      size: Size(size, size),
      painter: _AppLogoPainter(),
    );

    final typography = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isHorizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          'شوت لايف',
          style: GoogleFonts.cairo(
            fontSize: size * 0.32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.liveIndicator,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'SHOOT LIVE',
                style: GoogleFonts.poppins(
                  fontSize: size * 0.13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  color: AppColors.liveIndicator,
                ),
              ),
            ],
          ),
        ],
      ],
    );

    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          emblem,
          SizedBox(width: size * 0.2),
          typography,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        emblem,
        SizedBox(height: size * 0.15),
        typography,
      ],
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Live signal pulse outer halo
    final haloPaint = Paint()
      ..color = AppColors.liveIndicator.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035;
    canvas.drawCircle(center, radius * 0.95, haloPaint);

    // 2. Main ball background sphere with subtle gradient
    final ballPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.surfaceLight,
          AppColors.surface,
        ],
        center: const Alignment(-0.2, -0.2),
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.82))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.82, ballPaint);

    // 3. Football live accent border
    final borderPaint = Paint()
      ..color = AppColors.liveIndicator
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05;
    canvas.drawCircle(center, radius * 0.82, borderPaint);

    // 4. Seam lines across the ball
    final seamPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025;

    // Subtle football curved seams
    final seamRadius = radius * 0.82;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center.dx - seamRadius * 0.7, center.dy), radius: seamRadius * 0.7),
      -0.8,
      1.6,
      false,
      seamPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center.dx + seamRadius * 0.7, center.dy), radius: seamRadius * 0.7),
      2.34,
      1.6,
      false,
      seamPaint,
    );

    // 5. Central live indicator core
    final coreGlowPaint = Paint()
      ..color = AppColors.liveIndicator.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.42, coreGlowPaint);

    final corePaint = Paint()
      ..color = AppColors.liveIndicator
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.28, corePaint);

    // 6. Center pitch dot
    final centerDotPaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.12, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

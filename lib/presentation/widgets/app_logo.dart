import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Reusable application logo for Match Score (ماتش سكور).
///
/// Features a futuristic football stadium crest emblem with neon live accents
/// and crisp typography with an active live dot indicator.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showSubtitle;
  final bool isHorizontal;
  final double progress;
  final bool showBadgeImage;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showSubtitle = true,
    this.isHorizontal = false,
    this.progress = 1.0,
    this.showBadgeImage = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(size * 0.24);

    final emblem = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35 * progress),
            blurRadius: size * 0.28,
            spreadRadius: size * 0.04,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.live.withValues(alpha: 0.2 * progress),
            blurRadius: size * 0.2,
            spreadRadius: -size * 0.02,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background fallback vector painter
            CustomPaint(
              size: Size(size, size),
              painter: FootballShieldLogoPainter(
                progress: progress,
                primaryColor: AppColors.primary,
                liveColor: AppColors.live,
                isDark: isDark,
              ),
            ),
            // High-res badge image asset with smooth fade
            if (showBadgeImage)
              Image.asset(
                'assets/images/app_icon.png',
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to CustomPaint silently if asset is unavailable
                  return const SizedBox();
                },
              ),
          ],
        ),
      ),
    );

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final typography = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isHorizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConstants.appName,
              style: GoogleFonts.cairo(
                fontSize: size * 0.30,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                height: 1.15,
                letterSpacing: 0.0,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: size * 0.09,
              height: size * 0.09,
              decoration: const BoxDecoration(
                color: AppColors.live,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.live,
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 3),
          Text(
            'MATCH SCORE',
            style: GoogleFonts.poppins(
              fontSize: size * 0.12,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.0,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );

    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          emblem,
          SizedBox(width: size * 0.22),
          typography,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        emblem,
        SizedBox(height: size * 0.16),
        typography,
      ],
    );
  }
}

/// Fallback vector painter rendering an iconic football stadium shield with dual neon accents
class FootballShieldLogoPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color liveColor;
  final bool isDark;

  FootballShieldLogoPainter({
    required this.progress,
    required this.primaryColor,
    required this.liveColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    // 1. Dark Shield Base
    final shieldPath = Path();
    shieldPath.moveTo(w * 0.15, h * 0.12);
    shieldPath.quadraticBezierTo(w * 0.5, h * 0.04, w * 0.85, h * 0.12);
    shieldPath.quadraticBezierTo(w * 0.90, h * 0.55, w * 0.5, h * 0.94);
    shieldPath.quadraticBezierTo(w * 0.10, h * 0.55, w * 0.15, h * 0.12);
    shieldPath.close();

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF161E2E), const Color(0xFF090D16)]
            : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(shieldPath, bgPaint);

    // 2. Dual Neon Rim (Green on left, Coral on right)
    final rimPaintGreen = Paint()
      ..color = liveColor.withValues(alpha: 0.85 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04;

    final rimPaintCoral = Paint()
      ..color = primaryColor.withValues(alpha: 0.85 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: w * 0.36),
      3.14159 * 0.5,
      3.14159,
      false,
      rimPaintGreen,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: w * 0.36),
      -3.14159 * 0.5,
      3.14159,
      false,
      rimPaintCoral,
    );

    // 3. Football Core Geometry
    final ballRadius = w * 0.22;
    final ballPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035;

    canvas.drawCircle(center, ballRadius, ballPaint);

    // Center pentagon
    final pentagonPath = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72.0 - 90.0) * (3.14159 / 180.0);
      final px = center.dx + (ballRadius * 0.45) * (i == 0 ? 0 : (angle > 0 ? 0.95 : -0.95));
      final py = center.dy + (ballRadius * 0.45) * (i == 0 ? -1 : 0.4);
      if (i == 0) {
        pentagonPath.moveTo(px, py);
      } else {
        pentagonPath.lineTo(px, py);
      }
    }
    pentagonPath.close();

    final pentagonPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(pentagonPath, pentagonPaint);
  }

  @override
  bool shouldRepaint(covariant FootballShieldLogoPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.liveColor != liveColor ||
        oldDelegate.isDark != isDark;
  }
}

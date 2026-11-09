import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Professional, geometric application emblem and logo for "مدرّج" (Modarraj).
///
/// Concept: "Stands + Live Signal"
/// - Concentric rising stadium tiers / grandstand arcs opening upward.
/// - Vibrant live red-orange dot (#FF4D3D) at the focal bottom center.
/// - Deep midnight backdrop (#0B1020 -> #16213E).
/// - 100% vector-rendered via [ModarrajLogoPainter] without external bitmap dependencies.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showSubtitle;
  final bool isHorizontal;
  final double progress;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showSubtitle = true,
    this.isHorizontal = false,
    this.progress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(size * 0.22);

    final emblem = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D3D).withValues(alpha: 0.25 * progress),
            blurRadius: size * 0.24,
            spreadRadius: -size * 0.02,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF0B1020).withValues(alpha: 0.40 * progress),
            blurRadius: size * 0.20,
            spreadRadius: size * 0.02,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CustomPaint(
          size: Size(size, size),
          painter: ModarrajLogoPainter(progress: progress),
        ),
      ),
    );

    if (!showSubtitle) {
      return emblem;
    }

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

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
                fontSize: size * 0.32,
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
                color: Color(0xFFFF4D3D),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF4D3D),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        Text(
          AppConstants.appTitle,
          style: GoogleFonts.cairo(
            fontSize: size * 0.16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            letterSpacing: 1.5,
            height: 1.1,
          ),
        ),
      ],
    );

    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          emblem,
          const SizedBox(width: 14),
          typography,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        emblem,
        const SizedBox(height: 14),
        typography,
      ],
    );
  }
}

/// Custom painter rendering the geometric "Stands + Live Signal" logo.
class ModarrajLogoPainter extends CustomPainter {
  final double progress;

  const ModarrajLogoPainter({this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 512.0;

    // 1. Draw Deep Midnight Background Gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0B1020), Color(0xFF16213E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final cx = size.width / 2.0;
    final cy = 330.0 * scale;

    // 2. Draw Stadium Grandstand Tiers (rising concentric arcs opening upward)
    final tiers = [
      _TierConfig(r: 216.0 * scale, stroke: math.max(1.0, 14.0 * scale), alpha: 0.50, halfAngleDeg: 68.0),
      _TierConfig(r: 168.0 * scale, stroke: math.max(1.5, 17.0 * scale), alpha: 0.75, halfAngleDeg: 70.0),
      _TierConfig(r: 118.0 * scale, stroke: math.max(1.5, 16.0 * scale), alpha: 0.90, halfAngleDeg: 66.0),
      _TierConfig(r: 68.0 * scale, stroke: math.max(1.5, 14.0 * scale), alpha: 1.00, halfAngleDeg: 60.0),
    ];

    for (final tier in tiers) {
      final arcPaint = Paint()
        ..color = Colors.white.withValues(alpha: tier.alpha * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = tier.stroke
        ..strokeCap = StrokeCap.round;

      final startAngleRad = (180.0 + (90.0 - tier.halfAngleDeg)) * math.pi / 180.0;
      final sweepAngleRad = (tier.halfAngleDeg * 2.0) * math.pi / 180.0;

      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: tier.r);
      canvas.drawArc(rect, startAngleRad, sweepAngleRad, false, arcPaint);
    }

    // 3. Draw Pitch / Live Dot at (cx, cy)
    final dotRadius = math.max(2.5, 23.0 * scale);

    // Subtle glow behind dot
    final glowPaint = Paint()
      ..color = const Color(0xFFFF4D3D).withValues(alpha: 0.40 * progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 * scale);
    canvas.drawCircle(Offset(cx, cy), dotRadius * 1.3, glowPaint);

    // Core solid red-orange dot
    final dotPaint = Paint()
      ..color = const Color(0xFFFF4D3D).withValues(alpha: progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant ModarrajLogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _TierConfig {
  final double r;
  final double stroke;
  final double alpha;
  final double halfAngleDeg;

  const _TierConfig({
    required this.r,
    required this.stroke,
    required this.alpha,
    required this.halfAngleDeg,
  });
}

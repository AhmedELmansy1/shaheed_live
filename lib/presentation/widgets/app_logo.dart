import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Professional, high-octane football application emblem and logo for "شوت لايف" (Shoot Live).
///
/// Concept: "High-Velocity Rocket Football × Electric Live Pulse"
/// - Bold modern squircle badge with electric flame-to-gold border.
/// - Dynamic 3D shaded football captured in rocket flight ("شوت").
/// - Triple speed comet trails and kinetic acceleration lines.
/// - Pulsing live broadcast orbit ring and live beacon ("لايف").
/// - Crisp, high-contrast, scalable vector rendering via [ShootLiveLogoPainter] / [ModarrajLogoPainter].
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

    final emblem = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A623).withValues(alpha: 0.22),
            blurRadius: size * 0.25,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/branding/shoot_live_premium_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              size: Size(size, size),
              painter: ShootLiveLogoPainter(progress: progress),
            ),
          ),
        ),
      ),
    );

    if (!showSubtitle) {
      return emblem;
    }

    final typography = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isHorizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: isDark
                    ? [Colors.white, const Color(0xFFE2E8F0)]
                    : [AppColors.lightTextPrimary, const Color(0xFF1E293B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                AppConstants.appName,
                style: GoogleFonts.cairo(
                  fontSize: size * 0.34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: size * 0.08,
                vertical: size * 0.02,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3B30), Color(0xFFFF2D55)],
                ),
                borderRadius: BorderRadius.circular(size * 0.06),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: size * 0.05,
                    height: size * 0.05,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          AppConstants.appTitle.toUpperCase(),
          style: GoogleFonts.cairo(
            fontSize: size * 0.14,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.electricCyan : AppColors.primary,
            letterSpacing: 2.2,
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
        const SizedBox(height: 12),
        typography,
      ],
    );
  }
}

/// Backwards compatibility alias for [ShootLiveLogoPainter].
typedef ModarrajLogoPainter = ShootLiveLogoPainter;

/// Custom painter rendering the explosive "Shoot Live" football emblem.
class ShootLiveLogoPainter extends CustomPainter {
  final double progress;

  const ShootLiveLogoPainter({this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 512.0;

    // 1. Draw Squircle Drop Shadow
    final badgeRect = Rect.fromLTWH(16 * scale, 16 * scale, 480 * scale, 480 * scale);
    final badgeRRect = RRect.fromRectAndRadius(badgeRect, Radius.circular(116 * scale));

    canvas.drawRRect(
      badgeRRect.shift(Offset(0, 8 * scale)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45 * progress)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12.0 * scale),
    );

    // 2. Draw Squircle Body with Deep Obsidian Gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0B0F19),
          Color(0xFF111827),
          Color(0xFF070A10),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(badgeRect);
    canvas.drawRRect(badgeRRect, bgPaint);

    // 3. Draw Outer Neon Rim Border (Flame Vermilion to Amber Gold)
    final rimPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF3B30),
          Color(0xFFFF8A00),
          Color(0xFFFFB800),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(badgeRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, 7.0 * scale);
    canvas.drawRRect(badgeRRect, rimPaint);

    // 4. Subtle Ambient Orbit Rings
    final ringPaint1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.05 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, 2.0 * scale);
    canvas.drawCircle(Offset(260 * scale, 245 * scale), 175 * scale, ringPaint1);

    // 5. Speed Comet Flame Trails ("SHOOT / شوت")
    _drawSpeedTrails(canvas, scale);

    // 6. The 3D Football (Soccer Ball)
    _drawFootball(canvas, scale);

    // 7. Live Pulse Orbit Ring & Beacon ("LIVE / لايف")
    _drawLivePulse(canvas, scale);
  }

  void _drawSpeedTrails(Canvas canvas, double scale) {
    // Dynamic Speed Lines behind the ball
    final linePaint1 = Paint()
      ..color = const Color(0xFFFF3B30).withValues(alpha: 0.7 * progress)
      ..strokeWidth = math.max(1.0, 4.0 * scale)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(90 * scale, 360 * scale),
      Offset(160 * scale, 290 * scale),
      linePaint1,
    );

    final linePaint2 = Paint()
      ..color = const Color(0xFFFF9500).withValues(alpha: 0.85 * progress)
      ..strokeWidth = math.max(1.2, 5.0 * scale)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(120 * scale, 390 * scale),
      Offset(195 * scale, 315 * scale),
      linePaint2,
    );

    final linePaint3 = Paint()
      ..color = const Color(0xFFFFB800).withValues(alpha: 0.7 * progress)
      ..strokeWidth = math.max(1.0, 4.0 * scale)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(150 * scale, 420 * scale),
      Offset(225 * scale, 345 * scale),
      linePaint3,
    );

    // Outer Speed Flame Trail
    final flamePath1 = Path();
    flamePath1.moveTo(80 * scale, 410 * scale);
    flamePath1.cubicTo(130 * scale, 395 * scale, 170 * scale, 350 * scale, 205 * scale, 315 * scale);
    flamePath1.cubicTo(220 * scale, 300 * scale, 235 * scale, 285 * scale, 250 * scale, 270 * scale);
    flamePath1.cubicTo(225 * scale, 295 * scale, 195 * scale, 340 * scale, 145 * scale, 385 * scale);
    flamePath1.cubicTo(120 * scale, 405 * scale, 95 * scale, 412 * scale, 80 * scale, 410 * scale);
    flamePath1.close();

    final flamePaint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          const Color(0x00FF3B30),
          const Color(0xDDFF3B30).withValues(alpha: 0.85 * progress),
          const Color(0xFFFF9500).withValues(alpha: progress),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(80 * scale, 270 * scale, 170 * scale, 140 * scale))
      ..style = PaintingStyle.fill;
    canvas.drawPath(flamePath1, flamePaint1);

    // Core White-Hot Acceleration Streak
    final flamePath2 = Path();
    flamePath2.moveTo(140 * scale, 415 * scale);
    flamePath2.cubicTo(185 * scale, 390 * scale, 230 * scale, 340 * scale, 265 * scale, 285 * scale);
    flamePath2.cubicTo(280 * scale, 260 * scale, 290 * scale, 245 * scale, 295 * scale, 235 * scale);
    flamePath2.cubicTo(280 * scale, 255 * scale, 250 * scale, 310 * scale, 205 * scale, 365 * scale);
    flamePath2.cubicTo(175 * scale, 400 * scale, 150 * scale, 415 * scale, 140 * scale, 415 * scale);
    flamePath2.close();

    final flamePaint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          const Color(0x00FF9500),
          const Color(0xEEFFB800).withValues(alpha: 0.9 * progress),
          Colors.white.withValues(alpha: progress),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(140 * scale, 235 * scale, 155 * scale, 180 * scale))
      ..style = PaintingStyle.fill;
    canvas.drawPath(flamePath2, flamePaint2);
  }

  void _drawFootball(Canvas canvas, double scale) {
    final ballCenter = Offset(270 * scale, 235 * scale);
    final ballRadius = 88.0 * scale;

    // 1. Ball Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.60 * progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0 * scale);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(260 * scale, 340 * scale),
        width: 160 * scale,
        height: 32 * scale,
      ),
      shadowPaint,
    );

    // 2. 3D Shaded Leather Sphere
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.28, -0.36),
        radius: 0.72,
        colors: const [
          Colors.white,
          Color(0xFFF1F5F9),
          Color(0xFFCBD5E1),
          Color(0xFF64748B),
        ],
        stops: const [0.0, 0.55, 0.82, 1.0],
      ).createShader(Rect.fromCircle(center: ballCenter, radius: ballRadius));

    canvas.drawCircle(ballCenter, ballRadius, spherePaint);

    // 3. Draw Pentagons and Seams clipped inside the sphere
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: ballCenter, radius: ballRadius)));

    final patchPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: progress)
      ..style = PaintingStyle.fill;

    final seamPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, 3.5 * scale)
      ..strokeCap = StrokeCap.round;

    // Center Pentagon
    final centerPentagon = Path();
    final cpVertices = <Offset>[];
    for (int i = 0; i < 5; i++) {
      final a = -math.pi / 2 + (i * 2 * math.pi / 5);
      final pt = Offset(
        ballCenter.dx + 28.0 * scale * math.cos(a),
        ballCenter.dy + 28.0 * scale * math.sin(a),
      );
      cpVertices.add(pt);
      if (i == 0) {
        centerPentagon.moveTo(pt.dx, pt.dy);
      } else {
        centerPentagon.lineTo(pt.dx, pt.dy);
      }
    }
    centerPentagon.close();
    canvas.drawPath(centerPentagon, patchPaint);

    // Outer Edge Patches
    final edgeAngles = [
      -math.pi / 2,
      -math.pi / 2 + (2 * math.pi / 5),
      -math.pi / 2 + (4 * math.pi / 5),
      -math.pi / 2 + (6 * math.pi / 5),
      -math.pi / 2 + (8 * math.pi / 5),
    ];

    for (int i = 0; i < 5; i++) {
      final a = edgeAngles[i];
      final edgePt = Offset(
        ballCenter.dx + ballRadius * math.cos(a),
        ballCenter.dy + ballRadius * math.sin(a),
      );
      // Radiating seam
      canvas.drawLine(cpVertices[i], edgePt, seamPaint);

      // Edge patch polygon
      final edgePatch = Path();
      for (int k = 0; k < 5; k++) {
        final ea = a + (k * 2 * math.pi / 5) - math.pi / 5;
        final p = Offset(
          edgePt.dx + 22.0 * scale * math.cos(ea),
          edgePt.dy + 22.0 * scale * math.sin(ea),
        );
        if (k == 0) {
          edgePatch.moveTo(p.dx, p.dy);
        } else {
          edgePatch.lineTo(p.dx, p.dy);
        }
      }
      edgePatch.close();
      canvas.drawPath(edgePatch, patchPaint);
    }

    // 3D Specular Highlight Gloss
    canvas.save();
    canvas.translate(240 * scale, 195 * scale);
    canvas.rotate(-30 * math.pi / 180);
    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.50 * progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 * scale);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 72 * scale,
        height: 36 * scale,
      ),
      glossPaint,
    );
    canvas.restore();

    // Bottom Ambient Occlusion Shadow
    final bottomShadow = Paint()
      ..color = const Color(0xFF0A0F1D).withValues(alpha: 0.25 * progress);
    canvas.drawArc(
      Rect.fromCircle(center: ballCenter, radius: ballRadius),
      0,
      math.pi,
      true,
      bottomShadow,
    );

    canvas.restore();

    // Sphere crisp perimeter border
    final sphereBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.40 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, 2.0 * scale);
    canvas.drawCircle(ballCenter, ballRadius, sphereBorder);
  }

  void _drawLivePulse(Canvas canvas, double scale) {
    // 1. Live Orbit Arc
    final orbitPath = Path();
    orbitPath.moveTo(190 * scale, 190 * scale);
    orbitPath.cubicTo(220 * scale, 150 * scale, 280 * scale, 140 * scale, 330 * scale, 160 * scale);
    orbitPath.cubicTo(375 * scale, 178 * scale, 400 * scale, 220 * scale, 395 * scale, 265 * scale);
    orbitPath.cubicTo(390 * scale, 310 * scale, 355 * scale, 350 * scale, 310 * scale, 365 * scale);
    orbitPath.cubicTo(265 * scale, 380 * scale, 215 * scale, 365 * scale, 185 * scale, 335 * scale);

    final orbitPaint = Paint()
      ..color = const Color(0xFFFF3B30).withValues(alpha: 0.85 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, 4.5 * scale)
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(orbitPath, orbitPaint);

    // 2. Live Pulse Beacon at Orbit Top-Right
    final beaconCenter = Offset(365 * scale, 190 * scale);

    // Outer halo glow
    final haloPaint = Paint()
      ..color = const Color(0xFFFF3B30).withValues(alpha: 0.35 * progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 * scale);
    canvas.drawCircle(beaconCenter, 16.0 * scale, haloPaint);

    // Core red dot
    final beaconCore = Paint()
      ..color = const Color(0xFFFF3B30).withValues(alpha: progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(beaconCenter, 9.0 * scale, beaconCore);

    // Center white dot
    final beaconWhite = Paint()
      ..color = Colors.white.withValues(alpha: progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(beaconCenter, 4.5 * scale, beaconWhite);

    // 3. Mini Red "LIVE" Pill Badge at Bottom Center
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(256 * scale, 438 * scale),
        width: 130 * scale,
        height: 34 * scale,
      ),
      Radius.circular(17 * scale),
    );

    final pillPaint = Paint()
      ..color = const Color(0xFFFF3B30).withValues(alpha: progress)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(pillRect, pillPaint);

    // Live White Indicator Dot inside pill
    canvas.drawCircle(Offset(210 * scale, 438 * scale), 4.5 * scale, beaconWhite);

    // Live Text inside pill
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'LIVE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 15 * scale,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        256 * scale - (textPainter.width / 2) + (10 * scale),
        438 * scale - (textPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant ShootLiveLogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

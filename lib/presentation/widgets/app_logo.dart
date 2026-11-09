import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Professional, energetic football heraldic emblem and logo for "مدرّج" (Modarraj).
///
/// Concept: "Crest × 3D Football × Stadium Grandstand Tiers"
/// - Powerful geometric football club shield badge with gold-vermilion outer rim.
/// - 3D shaded football (soccer ball) with classic geometric pentagons, seams, and specular shine.
/// - Dynamic curved stadium grandstand tiers ("مدرج") sweeping across the lower base.
/// - Championship gold star at the crest apex.
/// - Dynamic velocity swoosh with live pulse beacon.
/// - 100% vector-rendered via [ModarrajLogoPainter], crisp at any density.
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

    final emblem = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: ModarrajLogoPainter(progress: progress),
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
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: size * 0.09,
              height: size * 0.09,
              decoration: const BoxDecoration(
                color: Color(0xFFFF4528),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF4528),
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
            letterSpacing: 1.2,
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

/// Custom painter rendering the premium "Crest × 3D Football × Stadium Tiers" logo.
class ModarrajLogoPainter extends CustomPainter {
  final double progress;

  const ModarrajLogoPainter({this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 512.0;

    // 1. Draw Outer Shield Drop Shadow
    final shadowShield = _createShieldPath(scale, dy: 6.0 * scale);
    canvas.drawPath(
      shadowShield,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.40 * progress)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0 * scale),
    );

    // 2. Draw Shield Body with Deep Obsidian Gradient
    final shieldPath = _createShieldPath(scale);
    final shieldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0E1626),
          Color(0xFF0A0F1D),
          Color(0xFF050811),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(shieldPath, shieldPaint);

    // 3. Draw Shield Golden-Vermilion Rim Border
    final rimPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFB800),
          Color(0xFFFF5A36),
          Color(0xFFE52D19),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, 8.0 * scale)
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(shieldPath, rimPaint);

    // Inner subtle precision border line
    final innerShield = _createShieldPath(scale * 0.94, dy: 14.0 * scale, dx: 15.0 * scale);
    final innerRimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, 2.0 * scale);
    canvas.drawPath(innerShield, innerRimPaint);

    // 4. Draw Apex Championship Star
    _drawApexStar(canvas, scale);

    // 5. Draw Stadium Grandstand ("مدرج") Tiers at Lower Shield
    _drawStadiumTiers(canvas, scale);

    // 6. Draw The Football (Soccer Ball)
    _drawFootball(canvas, scale);

    // 7. Draw Velocity Swoosh and Live Pulse Beacon
    _drawVelocitySwoosh(canvas, scale);
  }

  Path _createShieldPath(double scale, {double dx = 0.0, double dy = 0.0}) {
    final path = Path();
    final topApex = Offset(256 * scale + dx, 34 * scale + dy);
    final topRight = Offset(434 * scale + dx, 70 * scale + dy);
    final rightMid = Offset(434 * scale + dx, 270 * scale + dy);
    final bottomTip = Offset(256 * scale + dx, 478 * scale + dy);
    final leftMid = Offset(78 * scale + dx, 270 * scale + dy);
    final topLeft = Offset(78 * scale + dx, 70 * scale + dy);

    path.moveTo(topApex.dx, topApex.dy);
    path.lineTo(topRight.dx, topRight.dy);
    path.lineTo(rightMid.dx, rightMid.dy);
    path.cubicTo(
      434 * scale + dx,
      380 * scale + dy,
      348 * scale + dx,
      452 * scale + dy,
      bottomTip.dx,
      bottomTip.dy,
    );
    path.cubicTo(
      164 * scale + dx,
      452 * scale + dy,
      78 * scale + dx,
      380 * scale + dy,
      leftMid.dx,
      leftMid.dy,
    );
    path.lineTo(topLeft.dx, topLeft.dy);
    path.close();
    return path;
  }

  void _drawApexStar(Canvas canvas, double scale) {
    final starCenter = Offset(256 * scale, 82 * scale);
    final starPath = Path();
    final outerR = 14.0 * scale;
    final innerR = 6.0 * scale;

    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = -math.pi / 2 + (i * math.pi / 5);
      final x = starCenter.dx + r * math.cos(angle);
      final y = starCenter.dy + r * math.sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();

    final starPaint = Paint()
      ..color = const Color(0xFFFFB800).withValues(alpha: progress)
      ..style = PaintingStyle.fill;
    canvas.drawPath(starPath, starPaint);

    // Flanking gold accent dots
    final dotPaint = Paint()
      ..color = const Color(0xFFFFB800).withValues(alpha: 0.8 * progress);
    canvas.drawCircle(Offset(224 * scale, 84 * scale), 2.5 * scale, dotPaint);
    canvas.drawCircle(Offset(288 * scale, 84 * scale), 2.5 * scale, dotPaint);
  }

  void _drawStadiumTiers(Canvas canvas, double scale) {
    final arcCenter = Offset(256 * scale, 240 * scale);

    // Tier 3: Upper Terrace Arc (White glow)
    final tier3Paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, 7.0 * scale)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: arcCenter, radius: 176 * scale),
      35 * math.pi / 180,
      110 * math.pi / 180,
      false,
      tier3Paint,
    );

    // Tier 2: Middle Terrace Arc (Radiant Gold)
    final tier2Paint = Paint()
      ..color = const Color(0xFFFFB800).withValues(alpha: 0.95 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, 9.0 * scale)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: arcCenter, radius: 142 * scale),
      37 * math.pi / 180,
      106 * math.pi / 180,
      false,
      tier2Paint,
    );

    // Tier 1: Lower Terrace Arc (Electric Vermilion)
    final tier1Paint = Paint()
      ..color = const Color(0xFFFF4528).withValues(alpha: progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, 11.0 * scale)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: arcCenter, radius: 108 * scale),
      40 * math.pi / 180,
      100 * math.pi / 180,
      false,
      tier1Paint,
    );

    // Terrace Vertical Radial Aisles
    final aislePaint = Paint()
      ..color = const Color(0xFF0E1626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, 3.0 * scale)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(216 * scale, 360 * scale),
      Offset(204 * scale, 416 * scale),
      aislePaint,
    );
    canvas.drawLine(
      Offset(256 * scale, 364 * scale),
      Offset(256 * scale, 422 * scale),
      aislePaint,
    );
    canvas.drawLine(
      Offset(296 * scale, 360 * scale),
      Offset(308 * scale, 416 * scale),
      aislePaint,
    );
  }

  void _drawFootball(Canvas canvas, double scale) {
    final ballCenter = Offset(256 * scale, 210 * scale);
    final ballRadius = 84.0 * scale;

    // 1. Ball Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.50 * progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 * scale);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(256 * scale, 306 * scale),
        width: 144 * scale,
        height: 28 * scale,
      ),
      shadowPaint,
    );

    // 2. Spherical Ball Base with 3D Lighting
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.24, -0.36),
        radius: 0.75,
        colors: const [
          Colors.white,
          Color(0xFFE2E8F0),
          Color(0xFFCBD5E1),
          Color(0xFF94A3B8),
        ],
        stops: const [0.0, 0.55, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: ballCenter, radius: ballRadius));

    canvas.drawCircle(ballCenter, ballRadius, spherePaint);

    // 3. Draw Pentagons and Seams clipped inside the sphere
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: ballCenter, radius: ballRadius)));

    final patchPaint = Paint()
      ..color = const Color(0xFF111827).withValues(alpha: progress)
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
        ballCenter.dx + 27.0 * scale * math.cos(a),
        ballCenter.dy + 27.0 * scale * math.sin(a),
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
      // Draw radiating seam line from central pentagon vertex to outer edge
      canvas.drawLine(cpVertices[i], edgePt, seamPaint);

      // Draw small outer edge pentagonal polygon patch
      final edgePatch = Path();
      for (int k = 0; k < 5; k++) {
        final ea = a + (k * 2 * math.pi / 5) - math.pi / 5;
        final p = Offset(
          edgePt.dx + 20.0 * scale * math.cos(ea),
          edgePt.dy + 20.0 * scale * math.sin(ea),
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
    canvas.translate(228 * scale, 172 * scale);
    canvas.rotate(-25 * math.pi / 180);
    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.40 * progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 * scale);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 68 * scale,
        height: 34 * scale,
      ),
      glossPaint,
    );
    canvas.restore();

    canvas.restore();

    // Subtle crisp sphere boundary stroke
    final sphereBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.35 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, 2.0 * scale);
    canvas.drawCircle(ballCenter, ballRadius, sphereBorder);
  }

  void _drawVelocitySwoosh(Canvas canvas, double scale) {
    final swooshPath = Path();
    swooshPath.moveTo(160 * scale, 252 * scale);
    swooshPath.cubicTo(
      180 * scale, 300 * scale,
      240 * scale, 316 * scale,
      294 * scale, 292 * scale,
    );
    swooshPath.cubicTo(
      330 * scale, 276 * scale,
      358 * scale, 244 * scale,
      366 * scale, 216 * scale,
    );
    swooshPath.cubicTo(
      362 * scale, 234 * scale,
      340 * scale, 262 * scale,
      308 * scale, 274 * scale,
    );
    swooshPath.cubicTo(
      264 * scale, 290 * scale,
      206 * scale, 280 * scale,
      180 * scale, 246 * scale,
    );
    swooshPath.close();

    final swooshPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Color(0x00FF4528),
          Color(0xCCFF4528),
          Color(0xFFFFB800),
          Colors.white,
        ],
        stops: [0.0, 0.4, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(160 * scale, 210 * scale, 210 * scale, 110 * scale))
      ..style = PaintingStyle.fill;

    canvas.drawPath(swooshPath, swooshPaint);

    // Live Pulse Core Dot at Swoosh Apex
    final pulseOffset = Offset(366 * scale, 214 * scale);
    final haloPaint = Paint()
      ..color = const Color(0xFFFF4528).withValues(alpha: 0.6 * progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0 * scale);
    canvas.drawCircle(pulseOffset, 8.0 * scale, haloPaint);

    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pulseOffset, 4.0 * scale, corePaint);
  }

  @override
  bool shouldRepaint(covariant ModarrajLogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

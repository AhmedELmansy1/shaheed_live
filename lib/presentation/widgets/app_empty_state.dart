import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

enum EmptyStateType { soccer, star, error, calendar, leagues }

/// Premium empty and error states with custom vector art and action buttons.
class AppEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final EmptyStateType type;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.type = EmptyStateType.soccer,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl, vertical: AppSpacing.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom Line Art Graphic
            CustomPaint(
              size: const Size(96, 96),
              painter: _EmptyStateIllustrationPainter(type: type),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyStateIllustrationPainter extends CustomPainter {
  final EmptyStateType type;

  _EmptyStateIllustrationPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Glowing atmospheric background circle
    final bgGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (type == EmptyStateType.error
                  ? AppColors.livePulse
                  : (type == EmptyStateType.star ? AppColors.gold : AppColors.liveIndicator))
              .withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.45));
    canvas.drawCircle(center, size.width * 0.45, bgGlowPaint);

    final strokePaint = Paint()
      ..color = (type == EmptyStateType.error
              ? AppColors.livePulse
              : (type == EmptyStateType.star ? AppColors.gold : AppColors.liveIndicator))
          .withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final ringPaint = Paint()
      ..color = AppColors.darkCardBorder
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, size.width * 0.38, ringPaint);

    switch (type) {
      case EmptyStateType.soccer:
        // Soccer ball geometry
        canvas.drawCircle(center, 24, strokePaint);
        final innerPath = Path();
        innerPath.moveTo(center.dx, center.dy - 10);
        innerPath.lineTo(center.dx + 9.5, center.dy - 3);
        innerPath.lineTo(center.dx + 6, center.dy + 9);
        innerPath.lineTo(center.dx - 6, center.dy + 9);
        innerPath.lineTo(center.dx - 9.5, center.dy - 3);
        innerPath.close();
        canvas.drawPath(innerPath, strokePaint);
        break;

      case EmptyStateType.star:
        // Star outline
        final starPath = Path();
        const points = 5;
        const outerRadius = 22.0;
        const innerRadius = 10.0;
        for (int i = 0; i < points * 2; i++) {
          final r = (i.isEven) ? outerRadius : innerRadius;
          final angle = (i * 3.14159 / points) - 1.57079;
          final x = center.dx + r * (angle.isNegative ? -1 : 1) * (1 - (angle * angle) / 10);
          final y = center.dy + r * (angle);
          if (i == 0) {
            starPath.moveTo(center.dx, center.dy - outerRadius);
          } else {
            starPath.lineTo(x, y);
          }
        }
        starPath.close();
        canvas.drawCircle(center, 20, strokePaint);
        break;

      case EmptyStateType.error:
        // Cloud & cross
        canvas.drawCircle(center, 20, strokePaint);
        canvas.drawLine(
          Offset(center.dx - 8, center.dy - 8),
          Offset(center.dx + 8, center.dy + 8),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx + 8, center.dy - 8),
          Offset(center.dx - 8, center.dy + 8),
          strokePaint,
        );
        break;

      case EmptyStateType.calendar:
      case EmptyStateType.leagues:
        final rrect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 44, height: 38),
          AppRadii.smRadius.topLeft,
        );
        canvas.drawRRect(rrect, strokePaint);
        canvas.drawLine(
          Offset(center.dx - 22, center.dy - 6),
          Offset(center.dx + 22, center.dy - 6),
          strokePaint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

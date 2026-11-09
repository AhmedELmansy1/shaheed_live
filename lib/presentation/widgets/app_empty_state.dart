import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum EmptyStateType { soccer, star, error, calendar, leagues }

/// Premium empty and error states in the "Paper × Ink × Vermilion" design system.
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
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);
    final accent = (type == EmptyStateType.error)
        ? AppColors.primaryOf(context)
        : (type == EmptyStateType.star
            ? AppColors.gold
            : AppColors.primaryOf(context));

    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxxl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Custom Line Art Graphic
              CustomPaint(
                size: const Size(96, 96),
                painter: _EmptyStateIllustrationPainter(
                  type: type,
                  accentColor: accent,
                  ringColor: border,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium(color: textPrimary).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(color: textSecondary),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateIllustrationPainter extends CustomPainter {
  final EmptyStateType type;
  final Color accentColor;
  final Color ringColor;

  _EmptyStateIllustrationPainter({
    required this.type,
    required this.accentColor,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final bgSoftPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.45, bgSoftPaint);

    final strokePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final ringPaint = Paint()
      ..color = ringColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, size.width * 0.38, ringPaint);

    switch (type) {
      case EmptyStateType.soccer:
        canvas.drawCircle(center, 22, strokePaint);
        final innerPath = Path();
        innerPath.moveTo(center.dx, center.dy - 9);
        innerPath.lineTo(center.dx + 8.5, center.dy - 3);
        innerPath.lineTo(center.dx + 5.5, center.dy + 8);
        innerPath.lineTo(center.dx - 5.5, center.dy + 8);
        innerPath.lineTo(center.dx - 8.5, center.dy - 3);
        innerPath.close();
        canvas.drawPath(innerPath, strokePaint);
        break;

      case EmptyStateType.star:
        final starPath = Path();
        const points = 5;
        const outerRadius = 20.0;
        const innerRadius = 9.0;
        for (int i = 0; i < points * 2; i++) {
          final isEven = i % 2 == 0;
          final r = isEven ? outerRadius : innerRadius;
          final angle = (i * 3.14159 / points) - (3.14159 / 2);
          final x = center.dx + r * (angle < 0 ? -1 : 1) * (angle.abs() > 1.57 ? -1 : 1) * 0.8;
          final y = center.dy + r * 0.8;
          if (i == 0) {
            starPath.moveTo(x, y);
          } else {
            starPath.lineTo(x, y);
          }
        }
        starPath.close();
        canvas.drawCircle(center, 18, strokePaint);
        break;

      case EmptyStateType.calendar:
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 34, height: 32),
          const Radius.circular(6),
        );
        canvas.drawRRect(rect, strokePaint);
        canvas.drawLine(
          Offset(center.dx - 17, center.dy - 5),
          Offset(center.dx + 17, center.dy - 5),
          strokePaint,
        );
        break;

      case EmptyStateType.leagues:
        canvas.drawCircle(center, 20, strokePaint);
        break;

      case EmptyStateType.error:
        canvas.drawCircle(center, 22, strokePaint);
        canvas.drawLine(
          Offset(center.dx, center.dy - 10),
          Offset(center.dx, center.dy + 2),
          strokePaint..strokeWidth = 2.5,
        );
        canvas.drawCircle(
          Offset(center.dx, center.dy + 8),
          1.8,
          Paint()..color = accentColor,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _EmptyStateIllustrationPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.ringColor != ringColor;
  }
}

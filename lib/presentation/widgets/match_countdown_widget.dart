import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';

/// Lightweight, self-contained live countdown widget scoped strictly to the visible widget lifecycle.
///
/// Ticks every second and disposes cleanly to ensure zero unnecessary battery drain.
class MatchCountdownWidget extends StatefulWidget {
  final DateTime? targetDateTime;
  final String fallbackFormattedTime;
  final bool isHero;
  final VoidCallback? onReachedZero;

  const MatchCountdownWidget({
    super.key,
    required this.targetDateTime,
    required this.fallbackFormattedTime,
    this.isHero = false,
    this.onReachedZero,
  });

  @override
  State<MatchCountdownWidget> createState() => _MatchCountdownWidgetState();
}

class _MatchCountdownWidgetState extends State<MatchCountdownWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _hasReachedZero = false;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    if (!_hasReachedZero && widget.targetDateTime != null) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant MatchCountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetDateTime != widget.targetDateTime) {
      _calculateRemaining();
      _restartTimer();
    }
  }

  void _calculateRemaining() {
    if (widget.targetDateTime == null) {
      _remaining = Duration.zero;
      _hasReachedZero = true;
      return;
    }

    final diff = widget.targetDateTime!.difference(DateTime.now());
    if (diff.isNegative || diff == Duration.zero) {
      _remaining = Duration.zero;
      _hasReachedZero = true;
      _timer?.cancel();
      _timer = null;
    } else {
      _remaining = diff;
      _hasReachedZero = false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final diff =
          widget.targetDateTime?.difference(DateTime.now()) ?? Duration.zero;
      if (diff.isNegative || diff == Duration.zero) {
        timer.cancel();
        _timer = null;
        setState(() {
          _remaining = Duration.zero;
          _hasReachedZero = true;
        });
        widget.onReachedZero?.call();
      } else {
        setState(() {
          _remaining = diff;
          _hasReachedZero = false;
        });
      }
    });
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;
    if (!_hasReachedZero && widget.targetDateTime != null) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  String _formatCountdown() {
    if (_hasReachedZero || widget.targetDateTime == null) {
      return 'تبدأ الآن';
    }

    final totalHours = _remaining.inHours;
    final totalMinutes = _remaining.inMinutes;
    final minutesInHour = _remaining.inMinutes.remainder(60);
    final secondsInMinute = _remaining.inSeconds.remainder(60);

    if (totalHours >= 24) {
      final days = _remaining.inDays;
      final remainingHours = totalHours.remainder(24);
      return DateFormatter.toArabicNumerals(
        'تبدأ خلال $days يوم و $remainingHours س',
      );
    }

    if (totalHours > 0) {
      final h = totalHours.toString().padLeft(2, '0');
      final m = minutesInHour.toString().padLeft(2, '0');
      final s = secondsInMinute.toString().padLeft(2, '0');
      return DateFormatter.toArabicNumerals('تبدأ خلال $h:$m:$s');
    }

    // Less than 1 hour away: MM:SS
    final m = totalMinutes.toString().padLeft(2, '0');
    final s = secondsInMinute.toString().padLeft(2, '0');
    return DateFormatter.toArabicNumerals('تبدأ خلال $m:$s');
  }

  @override
  Widget build(BuildContext context) {
    final text = _formatCountdown();

    if (widget.isHero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceHigh,
          borderRadius: AppRadii.mdRadius,
          border: Border.all(
            color: _hasReachedZero
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _hasReachedZero ? Icons.play_arrow_rounded : Icons.timer_outlined,
              size: 13,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              text,
              style: GoogleFonts.cairo(
                color: AppColors.primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.0,
                height: 1.2,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceHigh,
        borderRadius: AppRadii.smRadius,
        border: Border.all(
          color: _hasReachedZero ? AppColors.primary : AppColors.darkBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _hasReachedZero ? Icons.play_arrow_rounded : Icons.timer_outlined,
            size: 10.5,
            color: _hasReachedZero
                ? AppColors.primary
                : AppColors.darkTextSecondary,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.cairo(
              color: _hasReachedZero
                  ? AppColors.primary
                  : AppColors.darkTextSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.0,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/match_model.dart';
import '../../presentation/match_details/match_details_screen.dart';
import '../../presentation/widgets/team_logo.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';
import '../utils/app_number_format.dart';

/// Global Manager for the in-app Floating Live Score Bubble.
/// Displays an elevated, draggable pill displaying the pinned match score across screens.
class FloatingScoreManager {
  FloatingScoreManager._();
  static final FloatingScoreManager instance = FloatingScoreManager._();

  OverlayEntry? _entry;
  MatchModel? _pinnedMatch;
  Offset _position = const Offset(16, 120);

  bool get isPinned => _entry != null;
  String? get pinnedMatchId => _pinnedMatch?.id;

  void toggle(BuildContext context, MatchModel match) {
    if (isPinned && pinnedMatchId == match.id) {
      dismiss();
    } else {
      show(context, match);
    }
  }

  void show(BuildContext context, MatchModel match) {
    HapticFeedback.mediumImpact();
    dismiss();

    _pinnedMatch = match;
    final overlay = Overlay.of(context, rootOverlay: true);

    _entry = OverlayEntry(
      builder: (ctx) => _DraggableScoreBubble(
        match: _pinnedMatch!,
        initialPosition: _position,
        onPositionChanged: (newPos) => _position = newPos,
        onDismiss: dismiss,
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => MatchDetailsScreen(
                matchId: match.id,
                initialMatch: match,
              ),
            ),
          );
        },
      ),
    );

    overlay.insert(_entry!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم تثبيت نتيجة مباراة ${match.homeTeamName} × ${match.awayTeamName} عائماً 📌',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void updateMatch(MatchModel updated) {
    if (_pinnedMatch?.id == updated.id) {
      _pinnedMatch = updated;
      _entry?.markNeedsBuild();
    }
  }

  void dismiss() {
    _entry?.remove();
    _entry = null;
    _pinnedMatch = null;
  }
}

class _DraggableScoreBubble extends StatefulWidget {
  final MatchModel match;
  final Offset initialPosition;
  final ValueChanged<Offset> onPositionChanged;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _DraggableScoreBubble({
    required this.match,
    required this.initialPosition,
    required this.onPositionChanged,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_DraggableScoreBubble> createState() => _DraggableScoreBubbleState();
}

class _DraggableScoreBubbleState extends State<_DraggableScoreBubble> {
  late Offset _offset;

  @override
  void initState() {
    super.initState();
    _offset = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeScore = widget.match.homeScore ?? '0';
    final awayScore = widget.match.awayScore ?? '0';
    final minute = widget.match.currentMinute ?? (widget.match.isLive ? 'مباشر' : widget.match.formattedLocalTime);

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final nextX = (_offset.dx + details.delta.dx).clamp(8.0, screenSize.width - 210.0);
            final nextY = (_offset.dy + details.delta.dy).clamp(40.0, screenSize.height - 80.0);
            _offset = Offset(nextX, nextY);
          });
          widget.onPositionChanged(_offset);
        },
        onTap: widget.onTap,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(
                color: widget.match.isLive
                    ? AppColors.neonEmerald
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                if (widget.match.isLive)
                  BoxShadow(
                    color: AppColors.neonEmerald.withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Row(
              children: [
                // Live Dot or Clock
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.match.isLive ? AppColors.neonEmerald : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),

                // Home Logo
                TeamLogo(
                  logoUrl: widget.match.homeTeamLogo,
                  teamName: widget.match.homeTeamName,
                  size: 20,
                ),
                const SizedBox(width: 4),

                // Scores
                Text(
                  AppNumberFormat.toLatinNumerals('$homeScore : $awayScore'),
                  style: AppTypography.scoreHeadline(
                    color: isDark ? Colors.white : Colors.black87,
                  ).copyWith(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 4),

                // Away Logo
                TeamLogo(
                  logoUrl: widget.match.awayTeamLogo,
                  teamName: widget.match.awayTeamName,
                  size: 20,
                ),
                const Spacer(),

                // Minute Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: widget.match.isLive
                        ? AppColors.neonEmerald.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    minute,
                    style: TextStyle(
                      color: widget.match.isLive ? AppColors.neonEmerald : Colors.grey.shade400,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Dismiss Button (X)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onDismiss();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

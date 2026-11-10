import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_number_format.dart';

/// Single reaction item model.
class _ReactionItem {
  final String key;
  final String emoji;
  final String label;
  int count;

  _ReactionItem({
    required this.key,
    required this.emoji,
    required this.label,
    required this.count,
  });
}

/// Particle instance for flying emoji animation.
class _FlyingParticle {
  final Key key;
  final String emoji;
  final double startX;
  final double wobble;

  _FlyingParticle({
    required this.key,
    required this.emoji,
    required this.startX,
    required this.wobble,
  });
}

/// Interactive Live Match Reactions Bar with flying particle animations.
class LiveMatchReactionsBar extends StatefulWidget {
  final String matchId;

  const LiveMatchReactionsBar({
    super.key,
    required this.matchId,
  });

  @override
  State<LiveMatchReactionsBar> createState() => _LiveMatchReactionsBarState();
}

class _LiveMatchReactionsBarState extends State<LiveMatchReactionsBar>
    with TickerProviderStateMixin {
  late List<_ReactionItem> _reactions;
  final List<_FlyingParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _reactions = [
      _ReactionItem(key: 'fire', emoji: '🔥', label: 'حماس', count: 124),
      _ReactionItem(key: 'goal', emoji: '⚽', label: 'هدف', count: 87),
      _ReactionItem(key: 'clap', emoji: '👏', label: 'تصفيق', count: 56),
      _ReactionItem(key: 'heartbreak', emoji: '💔', label: 'حسرة', count: 19),
      _ReactionItem(key: 'target', emoji: '🎯', label: 'خطيرة', count: 43),
    ];
    _loadStoredCounts();
  }

  Future<void> _loadStoredCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final r in _reactions) {
        final saved = prefs.getInt('reaction_${widget.matchId}_${r.key}');
        if (saved != null) {
          r.count += saved;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _onReact(_ReactionItem reaction, TapDownDetails details) async {
    HapticFeedback.lightImpact();

    setState(() {
      reaction.count++;
      // Spawn 3 flying particles with slight random offsets
      final box = context.findRenderObject() as RenderBox?;
      final localX = details.localPosition.dx;
      final width = box?.size.width ?? 300.0;
      final relativeX = (localX / width).clamp(0.1, 0.9);

      for (int i = 0; i < 3; i++) {
        _particles.add(
          _FlyingParticle(
            key: UniqueKey(),
            emoji: reaction.emoji,
            startX: relativeX + (_random.nextDouble() * 0.1 - 0.05),
            wobble: (_random.nextDouble() - 0.5) * 60,
          ),
        );
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt('reaction_${widget.matchId}_${reaction.key}') ?? 0;
      await prefs.setInt('reaction_${widget.matchId}_${reaction.key}', current + 1);
    } catch (_) {}
  }

  void _removeParticle(Key key) {
    if (mounted) {
      setState(() {
        _particles.removeWhere((p) => p.key == key);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Particle layer flying upward
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final p in _particles)
                  _AnimatedParticle(
                    key: p.key,
                    particle: p,
                    onComplete: () => _removeParticle(p.key),
                  ),
              ],
            ),
          ),
        ),

        // Reactions Pill Bar
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadii.full),
            border: Border.all(color: border, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final reaction in _reactions)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) => _onReact(reaction, details),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reaction.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppNumberFormat.toLatinNumerals('${reaction.count}'),
                          style: AppTypography.caption(color: textSecondary).copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedParticle extends StatefulWidget {
  final _FlyingParticle particle;
  final VoidCallback onComplete;

  const _AnimatedParticle({
    super.key,
    required this.particle,
    required this.onComplete,
  });

  @override
  State<_AnimatedParticle> createState() => _AnimatedParticleState();
}

class _AnimatedParticleState extends State<_AnimatedParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _yAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _yAnim = Tween<double>(begin: 0.0, end: -120.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_ctrl);

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 40),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * widget.particle.startX +
              (math.sin(_ctrl.value * math.pi * 2) * widget.particle.wobble),
          bottom: 10 - _yAnim.value,
          child: Opacity(
            opacity: _opacityAnim.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Text(
                widget.particle.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        );
      },
    );
  }
}

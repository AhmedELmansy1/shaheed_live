import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/ad_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/app_logo.dart';
import 'splash_controller.dart';

/// Animated "Royal Stadium" Splash Screen with deep navy atmosphere,
/// subtle golden light sweep, expanding gold pulse rings, and staggered wordmark.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _runSplashSequence();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  Future<void> _runSplashSequence() async {
    final startTime = DateTime.now();

    // Preload App Open Ad in background
    try {
      ref.read(adServiceProvider).loadAppOpenAd();
    } catch (_) {}

    // Perform background initialization checks
    final targetRoute = await ref
        .read(splashControllerProvider)
        .initializeApp();

    // Ensure minimum splash duration of 2.0s for smooth visual handoff
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    const minDuration = 2000;
    if (elapsed < minDuration) {
      await Future.delayed(Duration(milliseconds: minDuration - elapsed));
    }

    if (mounted) {
      context.go(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.15),
            radius: 1.3,
            colors: [
              Color(0xFF162038), // Royal Stadium Deep Navy Core
              Color(0xFF10172A), // Midnight Navy
              AppColors.darkBackground, // #0A0E1A Outer Depth
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Subtle Golden Spotlight Sweep
            AnimatedBuilder(
              animation: _sweepController,
              builder: (context, child) {
                final progress = _sweepController.value;
                return Transform.translate(
                  offset: Offset((progress - 0.5) * 400, (progress - 0.5) * 200),
                  child: Transform.rotate(
                    angle: -0.45,
                    child: Container(
                      width: 140,
                      height: 800,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.primary.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // 2. Outer Expanding Gold Pulse Ring
            RepaintBoundary(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                ),
              )
                  .animate(
                    onPlay: (controller) {
                      if (!AppMotion.isReducedMotion(context)) {
                        controller.repeat(reverse: true);
                      }
                    },
                  )
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1.15, 1.15),
                    duration: 2400.ms,
                    curve: Curves.easeInOut,
                  ),
            ),

            // 3. Inner Atmospheric Gold Halo
            RepaintBoundary(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              )
                  .animate(
                    onPlay: (controller) {
                      if (!AppMotion.isReducedMotion(context)) {
                        controller.repeat(reverse: true);
                      }
                    },
                  )
                  .scale(
                    begin: const Offset(0.88, 0.88),
                    end: const Offset(1.22, 1.22),
                    duration: 1800.ms,
                    curve: Curves.easeInOut,
                  ),
            ),

            // 4. Centered Brand Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with Hero / 0-500ms entrance
                const Hero(tag: 'app_brand_logo', child: AppLogo(size: 114))
                    .animate()
                    .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1.0, 1.0),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: AppSpacing.xl),

                // App Arabic Name Wordmark (200-700ms with subtle upward slide)
                Text(
                  'شوت لايف',
                  style: GoogleFonts.cairo(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkTextPrimary, // #F5F0E8 warm off-white
                    letterSpacing: 0.0,
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: 200.ms,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .moveY(
                      begin: 12,
                      end: 0,
                      delay: 200.ms,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    ),

                const SizedBox(height: AppSpacing.xxs),

                // Subtitle: SHOOT LIVE
                Text(
                  'SHOOT LIVE',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.5,
                    color: AppColors.primaryLight.withValues(alpha: 0.75),
                  ),
                ).animate().fadeIn(
                  delay: 300.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),

                const SizedBox(height: AppSpacing.xs),

                // Tagline
                Text(
                  'كرة القدم في متناول يدك',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 0.0,
                  ),
                ).animate().fadeIn(
                  delay: 400.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),

                const SizedBox(height: AppSpacing.xxxl + AppSpacing.md),

                // Refined Slim Gold Progress Line
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: AppRadii.fullRadius,
                    child: const LinearProgressIndicator(
                      minHeight: 2.5,
                      backgroundColor: Color(0x2BD4AF37),
                      color: AppColors.primary,
                    ),
                  ),
                ).animate().fadeIn(
                  delay: 450.ms,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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

/// Animated "Midnight Pitch" stadium-light splash screen with glowing pulse rings and staggered wordmark.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _runSplashSequence();
  }

  Future<void> _runSplashSequence() async {
    final startTime = DateTime.now();

    // Preload App Open Ad in background
    try {
      ref.read(adServiceProvider).loadAppOpenAd();
    } catch (_) {}

    // Perform background initialization checks
    final targetRoute = await ref.read(splashControllerProvider).initializeApp();

    // Ensure minimum splash duration of 2.0s for smooth visual transition
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
            center: Alignment(0.0, -0.2),
            radius: 1.2,
            colors: [
              Color(0xFF0F1E19), // Stadium emerald night mist
              Color(0xFF0C141D), // Deep midnight pitch glow
              AppColors.darkBackground, // #070B10 base
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Pulsing Stadium Ring
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
                  .animate(onPlay: (controller) {
                    if (!AppMotion.isReducedMotion(context)) {
                      controller.repeat(reverse: true);
                    }
                  })
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.15, 1.15),
                    duration: AppMotion.pulse * 1.5,
                    curve: Curves.easeInOut,
                  ),
            ),

            // Inner Atmospheric Glow Halo
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
                  .animate(onPlay: (controller) {
                    if (!AppMotion.isReducedMotion(context)) {
                      controller.repeat(reverse: true);
                    }
                  })
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1.2, 1.2),
                    duration: AppMotion.pulse,
                    curve: Curves.easeInOut,
                  ),
            ),

            // Centered Brand Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with Hero / 0-500ms entrance
                const Hero(
                  tag: 'app_brand_logo',
                  child: AppLogo(size: 110),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1.0, 1.0),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: AppSpacing.xl),

                // App Arabic Name Wordmark (200-700ms with 10px upward slide)
                Text(
                  'شوت لايف',
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkTextPrimary,
                    letterSpacing: 0.0,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutCubic)
                    .moveY(begin: 10, end: 0, delay: 200.ms, duration: 500.ms, curve: Curves.easeOutCubic),

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
                )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 500.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: AppSpacing.xxxl + AppSpacing.md),

                // Slim Progress Line in Electric Pitch Green
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: AppRadii.fullRadius,
                    child: const LinearProgressIndicator(
                      minHeight: 2.5,
                      backgroundColor: AppColors.darkSurfaceHigh,
                      color: AppColors.primary,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 400.ms, curve: Curves.easeOutCubic),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

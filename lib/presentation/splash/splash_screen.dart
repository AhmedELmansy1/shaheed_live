import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/ad_service.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_logo.dart';
import 'splash_controller.dart';

/// Animated Flutter splash screen displayed after native splash screen.
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
    final targetRoute =
        await ref.read(splashControllerProvider).initializeApp();

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
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.15),
            radius: 0.95,
            colors: [
              Color(0xFF161F2C), // Subtle elevated depth
              AppColors.background, // #0B0E14 deep dark background
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Brand Glow
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.liveIndicator.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.15, 1.15),
                  duration: 2200.ms,
                  curve: Curves.easeInOut,
                ),

            // Main Centered Brand Logo & Progress
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: 115)
                    .animate()
                    .fadeIn(duration: 800.ms, curve: Curves.easeOutCubic)
                    .scale(
                      begin: const Offset(0.88, 0.88),
                      end: const Offset(1.0, 1.0),
                      duration: 900.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 52),
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: AppColors.surfaceLight,
                      color: AppColors.liveIndicator,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 500.ms, curve: Curves.easeOutCubic),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

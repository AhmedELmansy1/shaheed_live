import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_constants.dart';
import '../../core/services/ad_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'splash_controller.dart';

/// Minimal, editorial Splash Screen in "Paper × Ink × Vermilion".
///
/// Principles:
/// - Single source of truth for branding: [AppConstants.appName] ("شوت لايف").
/// - Clean, dignified editorial appearance: NO neon glows, NO spotlights, NO emerald turf gradients.
/// - Instant 0ms artificial delay; navigates immediately when background initialization completes.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _runFastStartupSequence();
  }

  Future<void> _runFastStartupSequence() async {
    // 1. Preload App Open Ad in parallel non-blocking
    try {
      ref.read(adServiceProvider).loadAppOpenAd();
    } catch (_) {}

    // 2. Perform background startup tasks and navigate immediately when ready (0ms artificial delay)
    final targetRoute = await ref
        .read(splashControllerProvider)
        .initializeApp();

    if (mounted) {
      context.go(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = AppColors.darkBackground;
    const textPrimary = AppColors.darkTextPrimary;
    const textSecondary = AppColors.darkTextSecondary;
    const primary = AppColors.darkVermilion;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // 1. Refined Brand Emblem with Vermilion Accent
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: AppRadii.xlRadius,
                  border: Border.all(color: AppColors.darkBorder, width: 1.0),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.sports_soccer_rounded,
                  size: 42,
                  color: primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Editorial Arabic Title ("شوت لايف")
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    AppConstants.appName,
                    style: AppTypography.displayLarge(color: textPrimary).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 32,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // 3. Editorial Tagline
              Text(
                'دليلك الشامل لمواعيد ونتائج المباريات',
                style: AppTypography.bodySmall(color: textSecondary).copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),

              const Spacer(flex: 3),

              // 4. Subtle, clean loading indicator
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: primary,
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

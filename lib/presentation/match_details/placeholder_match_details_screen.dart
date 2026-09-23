import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// Placeholder screen for match details route `/match/:id`.
class PlaceholderMatchDetailsScreen extends StatelessWidget {
  final String matchId;

  const PlaceholderMatchDetailsScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('تفاصيل المباراة (#$matchId)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports_soccer_rounded,
              size: 64,
              color: AppColors.liveIndicator,
            ),
            const SizedBox(height: 16),
            Text(
              'تفاصيل المباراة رقم $matchId',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم بناء تفاصيل المباراة في الخطوة التالية',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

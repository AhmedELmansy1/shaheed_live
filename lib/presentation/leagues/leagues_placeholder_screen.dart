import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LeaguesPlaceholderScreen extends StatelessWidget {
  const LeaguesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('الدوريات'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.emoji_events_rounded,
              size: 64,
              color: AppColors.liveIndicator,
            ),
            SizedBox(height: 16),
            Text(
              'قريباً',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'سيتم إضافة قسم الدوريات قريباً',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

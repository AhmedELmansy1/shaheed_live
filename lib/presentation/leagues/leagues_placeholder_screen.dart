import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/app_empty_state.dart';

class LeaguesPlaceholderScreen extends StatelessWidget {
  const LeaguesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الدوريات'),
        centerTitle: true,
      ),
      body: const Center(
        child: AppEmptyState(
          type: EmptyStateType.leagues,
          title: 'قسم الدوريات قريباً',
          subtitle: 'نعمل على إضافة جداول الترتيب والهدافين لأقوى الدوريات العربية والعالمية',
        ),
      ),
    );
  }
}

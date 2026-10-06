import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/app_empty_state.dart';

class LeaguesPlaceholderScreen extends StatelessWidget {
  const LeaguesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        title: Text(
          'الدوريات',
          style: TextStyle(
            color: AppColors.textPrimaryOf(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: AppEmptyState(
          type: EmptyStateType.leagues,
          title: 'قسم الدوريات قريباً',
          subtitle: 'نعمل على إضافة قسم الدوريات وإحصائيات الفرق والبطولات العربية والعالمية',
        ),
      ),
    );
  }
}

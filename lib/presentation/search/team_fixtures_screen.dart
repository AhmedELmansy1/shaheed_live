import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/team_model.dart';
import '../widgets/app_button.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/match_card.dart';
import 'providers/search_provider.dart';

class TeamFixturesScreen extends ConsumerWidget {
  final String teamName;
  final TeamModel? teamModel;

  const TeamFixturesScreen({
    super.key,
    required this.teamName,
    this.teamModel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = teamModel?.name ?? teamName;
    final fixturesState = ref.watch(teamFixturesProvider(displayName));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(displayName),
        centerTitle: true,
      ),
      body: fixturesState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppEmptyState(
                type: EmptyStateType.error,
                title: 'حدث خطأ أثناء تحميل المباريات',
                subtitle: '$error',
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'إعادة المحاولة',
                icon: Icons.refresh_rounded,
                onPressed: () {
                  ref.invalidate(teamFixturesProvider(displayName));
                },
              ),
            ],
          ),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(
              child: AppEmptyState(
                type: EmptyStateType.calendar,
                title: 'لا توجد مباريات قادمة لهذا الفريق',
                subtitle: 'لا توجد مباريات مسجلة خلال الأيام الثلاثة القادمة',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 120),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return MatchCard(match: match);
            },
          );
        },
      ),
    );
  }
}

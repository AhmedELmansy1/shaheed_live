import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/team_model.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          displayName,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: fixturesState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.liveIndicator),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'حدث خطأ أثناء تحميل المباريات',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.liveIndicator,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  ref.invalidate(teamFixturesProvider(displayName));
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.sports_soccer, size: 64, color: AppColors.textMuted),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد مباريات قادمة لهذا الفريق',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'لا توجد مباريات مسجلة خلال الأيام الثلاثة القادمة',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
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

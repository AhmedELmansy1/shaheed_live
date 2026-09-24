import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'providers/search_provider.dart';

class TeamSearchScreen extends ConsumerStatefulWidget {
  const TeamSearchScreen({super.key});

  @override
  ConsumerState<TeamSearchScreen> createState() => _TeamSearchScreenState();
}

class _TeamSearchScreenState extends ConsumerState<TeamSearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    
    // Preload teams list 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(allTeamsProvider.notifier);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final allTeamsState = ref.watch(allTeamsProvider);
    final filteredTeams = ref.watch(filteredTeamsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "البحث عن فريق",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).setQuery(value);
              },
              decoration: InputDecoration(
                hintText: "ابحث عن فريقك...",
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: allTeamsState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.liveIndicator),
              ),
              error: (err, stack) => const Center(
                child: Text(
                  "حدث خطأ أثناء تحميل الفرق",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              data: (_) {
                if (query.isEmpty) {
                  return const Center(
                    child: Text(
                      "اكتب اسم الفريق للبحث",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  );
                }

                if (filteredTeams.isEmpty) {
                  return const Center(
                    child: Text(
                      "لا توجد نتائج",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredTeams.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: AppColors.divider, 
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final team = filteredTeams[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      title: Text(
                        team.name,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        team.nameEn,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          team.leagueId,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                      onTap: () {
                        context.push('/team/${Uri.encodeComponent(team.name)}/fixtures', extra: team);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

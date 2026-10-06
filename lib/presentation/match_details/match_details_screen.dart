import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/match_reminder_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/match_model.dart';
import '../widgets/banner_ad_widget.dart';
import 'providers/match_details_providers.dart';
import 'tabs/events_tab.dart';
import 'tabs/info_tab.dart';
import 'tabs/lineup_tab.dart';
import 'tabs/statistics_tab.dart';

class MatchDetailsScreen extends ConsumerWidget {
  final String matchId;
  final MatchModel? initialMatch;

  const MatchDetailsScreen({
    super.key,
    required this.matchId,
    this.initialMatch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = initialMatch;

    if (match == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('تفاصيل المباراة'),
        ),
        body: const Center(
          child: Text(
            'جاري تحميل بيانات المباراة...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final isReminderSet = ref.watch(isReminderSetProvider(match.matchId));

    final params = MatchDetailsParams(
      matchId: match.id,
      homeTeamId: match.homeTeamId,
      awayTeamId: match.awayTeamId,
      isLive: match.isLive,
    );

    return DefaultTabController(
      length: 5,
      initialIndex: 1, // Start on Events tab by default
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            match.leagueName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            if (!match.isLive && !match.isFinished)
              IconButton(
                icon: Icon(
                  isReminderSet
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: isReminderSet
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                tooltip: 'تفعيل تذكير قبل المباراة',
                onPressed: () {
                  ref.read(matchReminderServiceProvider).toggleReminder(match);
                },
              ),
          ],
        ),
        body: Column(
          children: [
            // Sticky Match Header Card
            _buildMatchHeaderCard(context, ref, match, isReminderSet),

            // Tab Bar
            Container(
              color: AppColors.surface,
              child: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: 'نظرة عامة'),
                  Tab(text: 'الأحداث'),
                  Tab(text: 'التشكيلة'),
                  Tab(text: 'الإحصائيات'),
                  Tab(text: 'معلومات'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _buildOverviewTab(context, match),
                  EventsTab(
                    params: params,
                    homeTeamId: match.homeTeamId,
                    awayTeamId: match.awayTeamId,
                  ),
                  LineupTab(params: params),
                  StatisticsTab(params: params),
                  InfoTab(match: match),
                ],
              ),
            ),

            // Persistent Bottom Banner Ad (Match Details Placement)
            const BannerAdWidget(placement: BannerPlacement.matchDetails),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchHeaderCard(
    BuildContext context,
    WidgetRef ref,
    MatchModel match,
    bool isReminderSet,
  ) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: match.isLive
                ? AppColors.live
                : AppColors.cardBorder,
            width: match.isLive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Home Team (Right side in RTL)
            Expanded(
              child: Column(
                children: [
                  _buildTeamLogo(match.homeTeamLogo),
                  const SizedBox(height: 8),
                  Text(
                    match.homeTeamName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Match Score / Time Center Section
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (match.isLive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.livePulse.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.livePulse),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.livePulse,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                match.statusName.isNotEmpty
                                    ? match.statusName
                                    : 'مباشر',
                                style: const TextStyle(
                                  color: AppColors.livePulse,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormatter.toArabicNumerals(
                            '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
                          ),
                          style: const TextStyle(
                            color: AppColors.live,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ] else if (match.isFinished) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardBorder,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'انتهت',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormatter.toArabicNumerals(
                            '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
                          ),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            match.statusName.isNotEmpty
                                ? match.statusName
                                : 'لم تبدأ',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          match.formattedLocalTime,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Away Team (Left side in RTL)
            Expanded(
              child: Column(
                children: [
                  _buildTeamLogo(match.awayTeamLogo),
                  const SizedBox(height: 8),
                  Text(
                    match.awayTeamName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, MatchModel match) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.sports_soccer,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ملخص المباراة',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.divider, height: 24),
              _buildOverviewRow('البطولة', match.leagueName),
              const SizedBox(height: 10),
              _buildOverviewRow(
                'التاريخ',
                DateFormatter.toArabicNumerals(match.displayDate),
              ),
              const SizedBox(height: 10),
              _buildOverviewRow('التوقيت', match.formattedLocalTime),
              const SizedBox(height: 10),
              _buildOverviewRow('الحالة', match.statusName),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }



  Widget _buildTeamLogo(String? url) {
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: 48,
        height: 48,
        placeholder: (_, _) => const SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
        errorWidget: (_, _, _) =>
            const Icon(Icons.shield, size: 48, color: AppColors.textSecondary),
      );
    }
    return const Icon(Icons.shield, size: 48, color: AppColors.textSecondary);
  }
}

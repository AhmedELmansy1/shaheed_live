import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    final params = MatchDetailsParams(
      matchId: match.id,
      homeTeamId: match.homeTeamId,
      awayTeamId: match.awayTeamId,
      isLive: match.isLive,
    );

    return DefaultTabController(
      length: 4,
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
        ),
        body: Column(
          children: [
            // Sticky Match Header Card
            _buildMatchHeaderCard(context, match),

            // Tab Bar
            Container(
              color: AppColors.surface,
              child: const TabBar(
                indicatorColor: AppColors.liveIndicator,
                labelColor: AppColors.liveIndicator,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: 'الأحداث'),
                  Tab(text: 'الإحصائيات'),
                  Tab(text: 'التشكيلة'),
                  Tab(text: 'معلومات'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  EventsTab(
                    params: params,
                    homeTeamId: match.homeTeamId,
                    awayTeamId: match.awayTeamId,
                  ),
                  StatisticsTab(params: params),
                  LineupTab(params: params),
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

  Widget _buildMatchHeaderCard(BuildContext context, MatchModel match) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  if (match.isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                            match.statusName.isNotEmpty ? match.statusName : 'مباشر',
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
                      DateFormatter.toArabicNumerals('${match.homeScore ?? 0} - ${match.awayScore ?? 0}'),
                      style: const TextStyle(
                        color: AppColors.liveIndicator,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ] else if (match.isFinished) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      DateFormatter.toArabicNumerals('${match.homeScore ?? 0} - ${match.awayScore ?? 0}'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.liveIndicator.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        match.statusName.isNotEmpty ? match.statusName : 'لم تبدأ',
                        style: const TextStyle(
                          color: AppColors.liveIndicator,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      match.formattedLocalTime,
                      style: const TextStyle(
                        color: AppColors.liveIndicator,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ],
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

  Widget _buildTeamLogo(String? url) {
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: 48,
        height: 48,
        placeholder: (_, _) => const SizedBox(
          width: 48,
          height: 48,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.liveIndicator)),
        ),
        errorWidget: (_, _, _) => const Icon(Icons.shield, size: 48, color: AppColors.textSecondary),
      );
    }
    return const Icon(Icons.shield, size: 48, color: AppColors.textSecondary);
  }
}

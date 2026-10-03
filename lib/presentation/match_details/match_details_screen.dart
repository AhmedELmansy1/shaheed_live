import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/match_reminder_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/match_share_helper.dart';
import '../../data/models/match_model.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/live_badge.dart';
import '../widgets/score_text.dart';
import '../widgets/team_logo.dart';
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
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkSurface,
          title: const Text('تفاصيل المباراة'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
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
      length: 6,
      initialIndex: 1, // Start on Events tab by default
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkTextPrimary, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            match.leagueName,
            style: GoogleFonts.cairo(
              color: AppColors.darkTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined, color: AppColors.darkTextPrimary, size: 21),
              tooltip: 'مشاركة تفاصيل المباراة',
              onPressed: () {
                HapticFeedback.lightImpact();
                MatchShareHelper.shareMatch(match);
              },
            ),
            if (!match.isLive && !match.isFinished)
              IconButton(
                icon: Icon(
                  isReminderSet
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: isReminderSet
                      ? AppColors.primary
                      : AppColors.darkTextSecondary,
                  size: 22,
                ),
                tooltip: 'تفعيل تذكير قبل المباراة',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(matchReminderServiceProvider).toggleReminder(match);
                },
              ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
        body: Column(
          children: [
            // Atmospheric Match Scoreboard Header
            _buildMatchHeaderCard(context, ref, match, isReminderSet),

            // Modern Sliding Tab Bar
            Container(
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(
                  bottom: BorderSide(color: AppColors.darkDivider, width: 1),
                ),
              ),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.darkTextSecondary,
                labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 13.5),
                unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13.5),
                tabs: const [
                  Tab(text: 'نظرة عامة'),
                  Tab(text: 'الأحداث'),
                  Tab(text: 'التشكيلة'),
                  Tab(text: 'الإحصائيات'),
                  Tab(text: 'الترتيب'),
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
                  _buildStandingsTab(),
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
      color: AppColors.darkSurface,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.glassCard(
          isLive: match.isLive,
          isFeatured: !match.isLive,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Home Team (Right side in RTL)
            Expanded(
              child: Column(
                children: [
                  TeamLogo(
                    logoUrl: match.homeTeamLogo,
                    teamName: match.homeTeamName,
                    size: 52,
                    heroTag: 'match_home_${match.matchId}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    match.homeTeamName,
                    style: AppTypography.bodyLarge(color: AppColors.darkTextPrimary),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Match Scoreboard Center Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  if (match.isLive) ...[
                    LiveBadge(minuteText: match.statusName.isNotEmpty ? match.statusName : 'مباشر', isLarge: true),
                    const SizedBox(height: AppSpacing.sm),
                    ScoreText(
                      homeScore: match.homeScore,
                      awayScore: match.awayScore,
                      isLive: true,
                      fontSize: 28,
                    ),
                  ] else if (match.isFinished) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceHigh,
                        borderRadius: AppRadii.fullRadius,
                      ),
                      child: const Text(
                        'انتهت',
                        style: TextStyle(
                          color: AppColors.darkTextMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ScoreText(
                      homeScore: match.homeScore,
                      awayScore: match.awayScore,
                      isLive: false,
                      fontSize: 24,
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceHigh,
                        borderRadius: AppRadii.mdRadius,
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Text(
                        match.statusName.isNotEmpty ? match.statusName : 'لم تبدأ',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      match.formattedLocalTime,
                      style: GoogleFonts.cairo(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        letterSpacing: 0.0,
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
                  TeamLogo(
                    logoUrl: match.awayTeamLogo,
                    teamName: match.awayTeamName,
                    size: 52,
                    heroTag: 'match_away_${match.matchId}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    match.awayTeamName,
                    style: AppTypography.bodyLarge(color: AppColors.darkTextPrimary),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: AppRadii.xsRadius,
                    ),
                    child: const Icon(Icons.sports_soccer_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'ملخص المباراة',
                    style: GoogleFonts.cairo(
                      color: AppColors.darkTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.darkDivider, height: AppSpacing.xxl),
              _buildOverviewRow('البطولة', match.leagueName),
              const SizedBox(height: AppSpacing.md),
              _buildOverviewRow('التاريخ', DateFormatter.toArabicNumerals(match.displayDate)),
              const SizedBox(height: AppSpacing.md),
              _buildOverviewRow('التوقيت', match.formattedLocalTime),
              const SizedBox(height: AppSpacing.md),
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
          style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStandingsTab() {
    return const AppEmptyState(
      type: EmptyStateType.leagues,
      title: 'جدول الترتيب غير متاح حالياً',
      subtitle: 'بيانات جدول الترتيب لهذه البطولة غير متوفرة في الوقت الحالي',
    );
  }
}

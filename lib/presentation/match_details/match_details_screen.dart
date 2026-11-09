import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/services/match_reminder_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/match_share_helper.dart';
import '../../data/models/match_model.dart';
import '../../data/models/match_stream_model.dart';
import '../../data/models/sponsorship_model.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/bottom_sheets/watch_match_bottom_sheet.dart';
import '../widgets/score_view.dart';
import '../widgets/sponsorship_banner_widget.dart';
import '../widgets/status_chip.dart';
import '../widgets/team_logo.dart';
import 'controllers/live_match_polling_manager.dart';
import 'providers/match_details_providers.dart';
import 'providers/match_stream_provider.dart';
import 'services/stream_player.dart';
import 'tabs/events_tab.dart';
import 'tabs/info_tab.dart';
import 'tabs/lineup_tab.dart';
import 'tabs/news_tab.dart';
import 'tabs/standings_tab.dart';
import 'tabs/statistics_tab.dart';
import 'widgets/poll_card.dart';

/// Premium Match Details Screen in "Paper × Ink × Vermilion".
///
/// Features:
/// - Sticky/Collapsing Header with TeamLogos, ScoreView, and StatusChip.
/// - Crisp, editorial tab bar with smooth switching (Events, Lineups, Stats, Standings, News, Info).
/// - Non-intrusive bottom banner ad with zero layout shift.
/// - Full RTL layout and responsiveness down to 360dp.
class MatchDetailsScreen extends ConsumerStatefulWidget {
  final String matchId;
  final MatchModel? initialMatch;

  const MatchDetailsScreen({
    super.key,
    required this.matchId,
    this.initialMatch,
  });

  @override
  ConsumerState<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends ConsumerState<MatchDetailsScreen> {
  LiveMatchPollingManager? _pollingManager;

  @override
  void initState() {
    super.initState();
    _setupPolling();
  }

  void _setupPolling() {
    final match = widget.initialMatch;
    if (match != null && match.isLive) {
      final params = MatchDetailsParams(
        matchId: match.id,
        homeTeamId: match.homeTeamId,
        awayTeamId: match.awayTeamId,
        isLive: true,
      );
      _pollingManager = LiveMatchPollingManager(
        isLive: true,
        onPoll: () async {
          await Future.wait([
            ref.refresh(matchEventsProvider(params).future),
            ref.refresh(matchStatisticsProvider(params).future),
          ]);
        },
      )..start();
    }
  }

  @override
  void dispose() {
    _pollingManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.initialMatch;
    final bg = AppColors.backgroundOf(context);
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final primary = AppColors.primaryOf(context);

    if (match == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: surface,
          elevation: 0,
          title: Text(
            'تفاصيل المباراة',
            style: AppTypography.titleMedium(color: textPrimary),
          ),
        ),
        body: Center(
          child: Text(
            'جاري تحميل بيانات المباراة...',
            style: AppTypography.bodyMedium(color: textSecondary),
          ),
        ),
      );
    }

    final isReminderSet = ref.watch(isMatchReminderActiveProvider(match));
    final streamModel = AppConstants.enableStreaming
        ? ref.watch(matchStreamProvider(match.matchId)).value
        : null;
    final bool hasActiveStream = AppConstants.enableStreaming &&
        streamModel != null &&
        streamModel.isEnabled &&
        streamModel.hasActiveServers;

    final params = MatchDetailsParams(
      matchId: match.id,
      homeTeamId: match.homeTeamId,
      awayTeamId: match.awayTeamId,
      isLive: match.isLive,
    );

    return DefaultTabController(
      length: 6,
      initialIndex: 0, // Events tab by default
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
            tooltip: 'رجوع',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            match.leagueName,
            style: AppTypography.titleMedium(color: textPrimary).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          shape: Border(bottom: BorderSide(color: border, width: 1.0)),
          actions: [
            // Share Match Action
            IconButton(
              icon: Icon(Icons.share_rounded, color: textSecondary, size: 20),
              tooltip: 'مشاركة المباراة',
              onPressed: () {
                HapticFeedback.lightImpact();
                MatchShareHelper.shareMatch(match);
              },
            ),

            // TV Stream Action (if active)
            if (AppConstants.enableStreaming && hasActiveStream)
              IconButton(
                icon: Icon(
                  Icons.tv_rounded,
                  color: match.isLive ? AppColors.vermilion : primary,
                  size: 22,
                ),
                tooltip: 'البث المباشر',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _openMatchStream(context, match, streamModel);
                },
              ),

            // Notification Bell (for upcoming matches)
            if (!match.isLive && !match.isFinished)
              IconButton(
                icon: Icon(
                  isReminderSet
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: isReminderSet ? primary : textSecondary,
                  size: 20,
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
        body: SafeArea(
          child: Column(
            children: [
              // 1. Sticky Hero Header Match Card
              _buildMatchHeaderCard(
                context,
                match,
                hasActiveStream: hasActiveStream,
                streamModel: streamModel,
              ),

              // Sponsorship Banner (Match Details Top Placement)
              const SponsorshipBannerWidget(
                placement: SponsorshipPlacement.matchDetailsTop,
              ),

              // Interactive Match Poll Card
              PollCard(
                matchId: match.id,
                isMatchFinished: match.isFinished,
              ),

              // 2. Clean Editorial Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  border: Border(bottom: BorderSide(color: border, width: 1.0)),
                ),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: primary,
                  indicatorWeight: 2.5,
                  labelColor: primary,
                  unselectedLabelColor: textSecondary,
                  labelStyle: AppTypography.labelLarge(color: primary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle:
                      AppTypography.labelLarge(color: textSecondary).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'الأحداث'),
                    Tab(text: 'التشكيلة'),
                    Tab(text: 'الإحصائيات'),
                    Tab(text: 'الترتيب'),
                    Tab(text: 'الأخبار'),
                    Tab(text: 'معلومات'),
                  ],
                ),
              ),

              // 3. Tab Views Content
              Expanded(
                child: TabBarView(
                  children: [
                    EventsTab(
                      params: params,
                      homeTeamId: match.homeTeamId,
                      awayTeamId: match.awayTeamId,
                    ),
                    LineupTab(params: params),
                    StatisticsTab(params: params),
                    StandingsTab(
                      matchId: int.tryParse(match.id) ?? 0,
                      homeTeamId: int.tryParse(match.homeTeamId?.toString() ?? ''),
                      awayTeamId: int.tryParse(match.awayTeamId?.toString() ?? ''),
                    ),
                    NewsTab(matchId: int.tryParse(match.id) ?? 0),
                    InfoTab(match: match),
                  ],
                ),
              ),

              // 4. Persistent Bottom Banner Ad (Match Details Placement)
              const BannerAdWidget(placement: BannerPlacement.matchDetails),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchHeaderCard(
    BuildContext context,
    MatchModel match, {
    required bool hasActiveStream,
    required MatchStreamModel? streamModel,
  }) {
    final surface = AppColors.surfaceOf(context);
    final surfaceElevated = AppColors.surfaceElevatedOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final primary = AppColors.primaryOf(context);

    return Container(
      color: surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surfaceElevated,
          borderRadius: AppRadii.lgRadius,
          border: Border.all(color: border, width: 1.0),
        ),
        child: Column(
          children: [
            // Center Stage: Home Team | Score/Status | Away Team
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Home Team (Right side in RTL)
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      TeamLogo(
                        logoUrl: match.homeTeamLogo,
                        teamName: match.homeTeamName,
                        size: 52,
                        heroTag: 'details_home_${match.matchId}',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        match.homeTeamName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall(color: textPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Center: Score / Time & Status
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusChip(match: match, isCompact: true),
                      const SizedBox(height: AppSpacing.xs),
                      if (match.isLive || match.isFinished)
                        ScoreView(
                          homeScore: match.homeScore,
                          awayScore: match.awayScore,
                          isLive: match.isLive,
                          isFinished: match.isFinished,
                          fontSize: 22,
                        )
                      else ...[
                        Text(
                          match.formattedLocalTime,
                          style: AppTypography.scoreHeadline(color: textPrimary).copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormatter.toArabicNumerals(match.displayDate),
                          style: AppTypography.labelSmall(color: textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),

                // Away Team (Left side in RTL)
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      TeamLogo(
                        logoUrl: match.awayTeamLogo,
                        teamName: match.awayTeamName,
                        size: 52,
                        heroTag: 'details_away_${match.matchId}',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        match.awayTeamName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall(color: textPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Prominent Watch Match Button (Live Stream Access)
            if (AppConstants.enableStreaming) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: match.isLive ? AppColors.vermilion : primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadii.mdRadius,
                    ),
                    elevation: 1,
                  ),
                  icon: Icon(
                    match.isLive ? Icons.live_tv_rounded : Icons.play_circle_filled_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'مشاهدة المباراة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _openMatchStream(context, match, streamModel);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openMatchStream(
    BuildContext context,
    MatchModel match,
    MatchStreamModel? streamModel,
  ) {
    if (streamModel == null ||
        !streamModel.isEnabled ||
        !streamModel.hasActiveServers) {
      WatchMatchBottomSheet.show(context, matchId: match.matchId, match: match);
      return;
    }

    final activeServers = streamModel.activeServersSorted;
    if (activeServers.length == 1) {
      final server = activeServers.first;
      final serverTitle = '${match.homeTeamName} ضد ${match.awayTeamName}';

      // Swappable StreamPlayer engine resolution
      final player = StreamPlayerResolver.resolve(server.playerType);
      player.launch(
        context: context,
        streamUrl: server.streamUrl,
        serverName: serverTitle,
        matchId: match.matchId,
        matchTitle: '${match.homeTeamName} × ${match.awayTeamName}',
        serverId: server.id,
      );
    } else {
      WatchMatchBottomSheet.show(context, matchId: match.matchId, match: match);
    }
  }
}

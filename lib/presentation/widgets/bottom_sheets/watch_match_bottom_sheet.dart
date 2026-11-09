import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/match_stream_model.dart';
import '../../match_details/providers/match_stream_provider.dart';
import '../../match_details/screens/embed_player_screen.dart';
import '../../match_details/screens/hls_player_screen.dart';
import '../../match_details/widgets/stream_report_sheet.dart';
import '../app_button.dart';
import '../app_card.dart';

class WatchMatchBottomSheet extends ConsumerWidget {
  final int matchId;
  final MatchModel? match;

  const WatchMatchBottomSheet({
    super.key,
    required this.matchId,
    this.match,
  });

  static void show(
    BuildContext context, {
    required int matchId,
    MatchModel? match,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (context) => WatchMatchBottomSheet(
        matchId: matchId,
        match: match,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textSecondary = AppColors.textSecondaryOf(context);

    // Dynamic real-time Firestore stream listener
    final streamAsync = ref.watch(matchStreamProvider(matchId));

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: AppRadii.fullRadius,
                  ),
                ),
              ),

              streamAsync.when(
                data: (streamModel) {
                  // Stream Available & Enabled with Active Servers
                  if (streamModel != null &&
                      streamModel.isEnabled &&
                      streamModel.hasActiveServers) {
                    return _buildAvailableServersView(
                      context: context,
                      servers: streamModel.activeServersSorted,
                    );
                  }

                  // Stream Not Configured Yet -> Smart Pre-Match Waiting UI
                  return _buildWaitingState(context, ref);
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (err, _) => _buildErrorState(context, ref, err),
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  /// Available Servers UI displayed when Firestore configuration has active servers.
  Widget _buildAvailableServersView({
    required BuildContext context,
    required List<StreamServerModel> servers,
  }) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.live_tv_rounded, color: AppColors.live, size: 24),
            const SizedBox(width: 8),
            Text(
              AppStrings.liveStreamsTitle,
              style: AppTypography.titleLarge(color: textPrimary)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.chooseServer,
          textAlign: TextAlign.center,
          style: AppTypography.caption(color: textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: servers.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final server = servers[index];
            return _buildServerCard(context: context, server: server);
          },
        ),

        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.flag_outlined, size: 16, color: Colors.amber),
            label: Text(
              'إبلاغ عن عطل أو مشكلة في خوادم البث',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              final matchTitle = match != null
                  ? '${match!.homeTeam.title} vs ${match!.awayTeam.title}'
                  : 'مباراة مباشرة';
              StreamReportBottomSheet.show(
                context,
                matchId: matchId,
                matchTitle: matchTitle,
                serverId: servers.isNotEmpty ? servers.first.id : 'all_servers',
                serverName: servers.isNotEmpty ? servers.first.name : 'خوادم البث',
              );
            },
          ),
        ),
      ],
    );
  }

  /// Smart Time-Based Waiting UI displayed when no stream is yet configured.
  Widget _buildWaitingState(BuildContext context, WidgetRef ref) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);

    final now = DateTime.now();
    final kickoff = match?.kickoffDateTime;
    final isLive = match?.isLive ?? false;
    final isFinished = match?.isFinished ?? false;

    final bool hasStarted = isLive ||
        isFinished ||
        (kickoff != null && (now.isAfter(kickoff) || now.isAtSameMomentAs(kickoff)));

    // 1. Match already started / in progress but no stream added yet
    if (hasStarted) {
      return _buildWaitingCard(
        context: context,
        icon: Icons.timer_outlined,
        iconColor: AppColors.live,
        title: AppStrings.streamPreparingStarted,
        mainMessage: AppStrings.matchStartedWorkingOnPlayer,
        availabilityMessage: AppStrings.pleaseTryAgainShortly,
        actionWidget: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: AppButton(
            label: AppStrings.retry,
            icon: Icons.refresh_rounded,
            variant: AppButtonVariant.primary,
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(matchStreamProvider(matchId));
            },
          ),
        ),
      );
    }

    // 2. Match has kickoff scheduled in future
    if (kickoff != null) {
      final diff = kickoff.difference(now);

      // Starts within 5 minutes
      if (diff <= const Duration(minutes: 5)) {
        return _buildWaitingCard(
          context: context,
          icon: Icons.hourglass_top_rounded,
          iconColor: AppColors.primary,
          title: AppStrings.playerPreparingNow,
          mainMessage: AppStrings.gettingReadyToStream,
          availabilityMessage: AppStrings.playerWillAppearMoments,
        );
      }

      // Starts more than 5 minutes from now -> display countdown
      final countdownStr = _formatFriendlyCountdown(diff);

      return _buildWaitingCard(
        context: context,
        icon: Icons.tv_rounded,
        iconColor: AppColors.primary,
        title: AppStrings.liveStreamComingSoon,
        mainMessage: AppStrings.streamNotPreparedYet,
        availabilityMessage: AppStrings.playerAddedBeforeKickoff,
        middleWidget: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.matchStartsIn,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                countdownStr,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Fallback when kickoff time is not available
    return _buildWaitingCard(
      context: context,
      icon: Icons.tv_rounded,
      iconColor: AppColors.primary,
      title: AppStrings.liveStreamComingSoon,
      mainMessage: AppStrings.streamNotPreparedYet,
      availabilityMessage: AppStrings.playerAddedBeforeKickoff,
    );
  }

  /// Shared waiting card presentation matching MATCH SCORE design tokens.
  Widget _buildWaitingCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String mainMessage,
    required String availabilityMessage,
    Widget? middleWidget,
    Widget? actionWidget,
  }) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with ambient glow container
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(icon, size: 32, color: iconColor),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Main Message
          Text(
            mainMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),

          // Availability Message
          Text(
            availabilityMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: iconColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          ?middleWidget,
          ?actionWidget,

          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.report_problem_outlined, size: 15, color: Colors.amber),
            label: Text(
              'إبلاغ عن عطل أو طلب تفعيل البث',
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              final matchTitle = match != null
                  ? '${match!.homeTeam.title} vs ${match!.awayTeam.title}'
                  : 'مباراة مباشرة';
              StreamReportBottomSheet.show(
                context,
                matchId: matchId,
                matchTitle: matchTitle,
                serverId: 'waiting_state',
                serverName: 'البث قيد التجهيز',
              );
            },
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Friendly Footer
          Text(
            AppStrings.friendlyFooter,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondary.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Friendly error card when Firestore connection or query fails.
  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object err) {
    return _buildWaitingCard(
      context: context,
      icon: Icons.cloud_off_rounded,
      iconColor: AppColors.textSecondary,
      title: 'خدمة البث المباشر غير متاحة حالياً',
      mainMessage: 'تعذر الاتصال بخوادم البث المباشر. يرجى التحقق من اتصالك بالإنترنت.',
      availabilityMessage: 'يرجى المحاولة مرة أخرى بعد لحظات 🔄',
      actionWidget: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: AppButton(
          label: AppStrings.retry,
          icon: Icons.refresh_rounded,
          variant: AppButtonVariant.primary,
          onPressed: () {
            HapticFeedback.lightImpact();
            ref.invalidate(matchStreamProvider(matchId));
          },
        ),
      ),
    );
  }

  /// Formats duration into natural Arabic representation with Eastern Arabic digits.
  String _formatFriendlyCountdown(Duration duration) {
    if (duration.isNegative) return 'الآن';

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    String rawText;
    if (days > 1) {
      rawText = hours > 0 ? '$days أيام و $hours ساعة' : '$days أيام';
    } else if (days == 1) {
      rawText = hours > 0 ? 'يوم و $hours ساعة' : 'يوم واحد';
    } else if (hours > 0) {
      if (minutes > 0) {
        final hoursStr = hours == 1
            ? 'ساعة'
            : hours == 2
                ? 'ساعتان'
                : hours <= 10
                    ? '$hours ساعات'
                    : '$hours ساعة';
        rawText = '$hoursStr و $minutes دقيقة';
      } else {
        rawText = hours == 1
            ? 'ساعة واحدة'
            : hours == 2
                ? 'ساعتان'
                : '$hours ساعات';
      }
    } else {
      rawText = '$minutes دقيقة';
    }

    return DateFormatter.toArabicNumerals(rawText);
  }

  Widget _buildServerCard({
    required BuildContext context,
    required StreamServerModel server,
  }) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    IconData getIconForPlayerType(PlayerType type) {
      switch (type) {
        case PlayerType.hls:
          return Icons.play_circle_fill_rounded;
        case PlayerType.embed:
          return Icons.web_rounded;
        case PlayerType.external:
          return Icons.open_in_new_rounded;
      }
    }

    String getBadgeForPlayerType(PlayerType type) {
      switch (type) {
        case PlayerType.hls:
          return 'مشغل HLS المباشر (عالي الجودة)';
        case PlayerType.embed:
          return 'مشغل الويب المضمّن';
        case PlayerType.external:
          return 'رابط خارجي معتمد';
      }
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      onTap: () => _handleServerTap(context, server),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              getIconForPlayerType(server.playerType),
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  server.name,
                  style: AppTypography.titleMedium(color: textPrimary)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  getBadgeForPlayerType(server.playerType),
                  style: AppTypography.caption(color: textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.live.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.live.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 6, color: AppColors.live),
                SizedBox(width: 4),
                Text(
                  'مباشر',
                  style: TextStyle(
                    color: AppColors.live,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.amber, size: 18),
            tooltip: 'إبلاغ عن عطل في هذا السيرفر',
            onPressed: () {
              Navigator.pop(context);
              final matchTitle = match != null
                  ? '${match!.homeTeam.title} vs ${match!.awayTeam.title}'
                  : 'مباراة مباشرة';
              StreamReportBottomSheet.show(
                context,
                matchId: matchId,
                matchTitle: matchTitle,
                serverId: server.id,
                serverName: server.name,
              );
            },
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_ios_rounded, color: textSecondary, size: 16),
        ],
      ),
    );
  }

  void _handleServerTap(BuildContext context, StreamServerModel server) {
    final uri = Uri.tryParse(server.streamUrl.trim());
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رابط البث غير صالح أو غير معتمد.'),
          backgroundColor: AppColors.live,
        ),
      );
      return;
    }

    Navigator.of(context).pop(); // Close bottom sheet

    final matchTitle = match != null
        ? '${match!.homeTeam.title} vs ${match!.awayTeam.title}'
        : 'مباراة مباشرة';

    switch (server.playerType) {
      case PlayerType.hls:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HlsPlayerScreen(
              streamUrl: server.streamUrl,
              serverName: server.name,
              matchId: matchId,
              matchTitle: matchTitle,
              serverId: server.id,
            ),
          ),
        );
        break;

      case PlayerType.embed:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmbedPlayerScreen(
              streamUrl: server.streamUrl,
              serverName: server.name,
              matchId: matchId,
              matchTitle: matchTitle,
              serverId: server.id,
            ),
          ),
        );
        break;

      case PlayerType.external:
        _launchExternalURL(context, server.streamUrl);
        break;
    }
  }

  Future<void> _launchExternalURL(BuildContext context, String urlString) async {
    final Uri? url = Uri.tryParse(urlString);
    if (url == null || (!url.isScheme('http') && !url.isScheme('https'))) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رابط البث غير صالح.'),
            backgroundColor: AppColors.live,
          ),
        );
      }
      return;
    }

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح الموقع الخارجي، حاول مرة أخرى.'),
            backgroundColor: AppColors.live,
          ),
        );
      }
    }
  }
}

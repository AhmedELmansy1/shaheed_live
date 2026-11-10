import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/match_lineup_model.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/matches_skeleton.dart';
import '../providers/match_details_providers.dart';

/// Editorial Lineups Tab in "Paper × Ink × Vermilion".
///
/// Features:
/// - Neutral tactical pitch layout (ink lines on tactile soft paper/charcoal surface, NO green).
/// - Formation badges with tabular numerals (e.g. ٤-٣-٣).
/// - Graceful fallback to an elegant list layout when formation data is unavailable.
/// - Crisp substitutes bench and manager cards.
class LineupTab extends ConsumerWidget {
  final MatchDetailsParams params;

  const LineupTab({super.key, required this.params});

  /// Testing helper method for avatar sizing test
  static Widget buildPlayerAvatarForTesting(
    LineupPlayer player, {
    required bool isHome,
    double size = 38.0,
  }) {
    return Builder(
      builder: (context) {
        final teamColor = isHome
            ? AppColors.primaryOf(context)
            : AppColors.secondaryOf(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E232E) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: teamColor, width: 2.0),
          ),
          alignment: Alignment.center,
          child: Text(
            player.number > 0
                ? '${player.number}'
                : player.initials,
            style: AppTypography.scoreLarge(color: teamColor).copyWith(
              fontSize: (size * 0.44).clamp(14.0, 20.0),
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineupAsync = ref.watch(matchLineupProvider(params));

    return lineupAsync.when(
      loading: () => const MatchesSkeleton(),
      error: (err, stack) => AppErrorState(
        title: 'تعذر تحميل تشكيلة المباراة',
        subtitle: 'يرجى التحقق من اتصالك بالإنترنت وإعادة المحاولة.',
        onRetry: () => ref.invalidate(matchLineupProvider(params)),
      ),
      data: (lineup) {
        if (lineup == null ||
            (lineup.homeLineup.startingXI.isEmpty &&
                lineup.awayLineup.startingXI.isEmpty)) {
          return const AppEmptyState(
            type: EmptyStateType.soccer,
            title: 'لم يتم الإعلان عن التشكيلة الرسمية بعد',
            subtitle: 'يتم نشر التشكيلة الرسمية لكلا الفريقين عادةً قبل انطلاق اللقاء بحوالي ساعة.',
          );
        }

        final homeHasFormation = lineup.homeLineup.formation != null &&
            lineup.homeLineup.formation!.isNotEmpty;
        final awayHasFormation = lineup.awayLineup.formation != null &&
            lineup.awayLineup.formation!.isNotEmpty;
        final canRenderPitch = homeHasFormation && awayHasFormation;

        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          children: [
            // 1. Formation Display Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: _buildFormationBadge(
                    context,
                    label: 'الأرض',
                    formation: lineup.homeLineup.formation,
                    isHome: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: _buildFormationBadge(
                    context,
                    label: 'الضيف',
                    formation: lineup.awayLineup.formation,
                    isHome: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. Tactical Pitch Canvas OR Graceful List Fallback
            if (canRenderPitch)
              SizedBox(
                height: (MediaQuery.sizeOf(context).width * 1.55).clamp(580.0, 680.0),
                child: NeutralPitchView(
                  homeData: lineup.homeLineup,
                  awayData: lineup.awayLineup,
                ),
              )
            else ...[
              // Fallback list of Starting XI
              _buildSectionTitle(context, 'التشكيلة الأساسية'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildPlayerListCard(
                      context,
                      title: 'الأرض',
                      players: lineup.homeLineup.startingXI,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildPlayerListCard(
                      context,
                      title: 'الضيف',
                      players: lineup.awayLineup.startingXI,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),

            // 3. Manager / Coach Section
            if (lineup.homeLineup.coach != null ||
                lineup.awayLineup.coach != null) ...[
              _buildSectionTitle(context, 'المدير الفني'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (lineup.homeLineup.coach != null)
                    Expanded(
                      child: _buildCoachCard(
                        context,
                        label: 'مدرب الأرض',
                        coachName: lineup.homeLineup.coach!,
                      ),
                    ),
                  if (lineup.homeLineup.coach != null &&
                      lineup.awayLineup.coach != null)
                    const SizedBox(width: AppSpacing.md),
                  if (lineup.awayLineup.coach != null)
                    Expanded(
                      child: _buildCoachCard(
                        context,
                        label: 'مدرب الضيف',
                        coachName: lineup.awayLineup.coach!,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // 4. Substitutes Bench Section
            if (lineup.homeLineup.substitutes.isNotEmpty ||
                lineup.awayLineup.substitutes.isNotEmpty) ...[
              _buildSectionTitle(context, 'قائمة البدلاء'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildPlayerListCard(
                      context,
                      title: 'بدلاء الأرض',
                      players: lineup.homeLineup.substitutes,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildPlayerListCard(
                      context,
                      title: 'بدلاء الضيف',
                      players: lineup.awayLineup.substitutes,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTypography.titleMedium(
        color: AppColors.textPrimaryOf(context),
      ).copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildFormationBadge(
    BuildContext context, {
    required String label,
    required String? formation,
    bool isHome = true,
  }) {
    final surface = AppColors.surfaceOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isHome ? AppColors.electricCyan : AppColors.coralCrimson;

    final displayFormation = formation != null && formation.isNotEmpty
        ? DateFormatter.toArabicNumerals(formation)
        : 'قائمة';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141F36) : surface,
        borderRadius: AppRadii.fullRadius,
        border: Border.all(
          color: isDark ? accent.withValues(alpha: 0.45) : AppColors.borderOf(context),
          width: 1.0,
        ),
        boxShadow: [
          if (isDark)
            BoxShadow(
              color: accent.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: AppTypography.labelSmall(color: textSecondary).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              displayFormation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium(color: textPrimary).copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachCard(
    BuildContext context, {
    required String label,
    required String coachName,
  }) {
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded, size: 18, color: textPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall(color: textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  coachName,
                  style: AppTypography.bodySmall(color: textPrimary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerListCard(
    BuildContext context, {
    required String title,
    required List<LineupPlayer> players,
  }) {
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    if (players.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadii.mdRadius,
          border: Border.all(color: border, width: 1.0),
        ),
        child: Text(
          'لا توجد بيانات',
          style: AppTypography.bodySmall(color: textSecondary),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              title,
              style: AppTypography.labelMedium(color: textSecondary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Divider(color: border, height: AppSpacing.sm),
          ...players.map((p) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevatedOf(context),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: border, width: 0.8),
                    ),
                    child: Text(
                      DateFormatter.toArabicNumerals('${p.number}'),
                      style: AppTypography.labelSmall(color: textPrimary).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: Text(
                      p.name,
                      style: AppTypography.bodySmall(color: textPrimary).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Realistic dark emerald tactical football pitch visualization.
class NeutralPitchView extends StatelessWidget {
  final TeamLineupData homeData;
  final TeamLineupData awayData;

  const NeutralPitchView({
    super.key,
    required this.homeData,
    required this.awayData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: AppRadii.lgRadius,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadii.lgRadius,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B281B),
              Color(0xFF0F3624),
              Color(0xFF0B281B),
            ],
          ),
          border: Border.all(
            color: isDark ? const Color(0xFF1E4D38) : const Color(0xFF2A684C),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A00E676),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pitchWidth =
                constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
            final avatarSize = (pitchWidth * 0.105).clamp(36.0, 44.0);
            final nameFontSize = (avatarSize * 0.23).clamp(10.0, 11.5);
            final nameMaxWidth = (pitchWidth / 5.2).clamp(54.0, 68.0);

            return CustomPaint(
              painter: NeutralPitchPainter(
                lineColor: Colors.white.withValues(alpha: 0.45),
              ),
              child: Stack(
                children: [
                  // Home Team (Top Half)
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.topCenter,
                      heightFactor: 0.5,
                      child: _buildTeamNodes(
                        context,
                        teamData: homeData,
                        isHome: true,
                        avatarSize: avatarSize,
                        nameFontSize: nameFontSize,
                        nameMaxWidth: nameMaxWidth,
                      ),
                    ),
                  ),

                  // Away Team (Bottom Half)
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.bottomCenter,
                      heightFactor: 0.5,
                      child: _buildTeamNodes(
                        context,
                        teamData: awayData,
                        isHome: false,
                        avatarSize: avatarSize,
                        nameFontSize: nameFontSize,
                        nameMaxWidth: nameMaxWidth,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTeamNodes(
    BuildContext context, {
    required TeamLineupData teamData,
    required bool isHome,
    required double avatarSize,
    required double nameFontSize,
    required double nameMaxWidth,
  }) {
    final players = teamData.startingXI;
    if (players.isEmpty) return const SizedBox.shrink();

    final rows = _parseFormationRows(teamData.formation, players.length);
    final isDenseFormation = rows.length >= 5;
    final effectiveAvatarSize = isDenseFormation
        ? (avatarSize * 0.78).clamp(30.0, 34.0)
        : avatarSize;
    final effectiveNameFontSize = isDenseFormation
        ? (nameFontSize * 0.88).clamp(9.0, 10.0)
        : nameFontSize;
    int playerIndex = 0;

    List<Widget> rowWidgets = [];

    for (int r = 0; r < rows.length; r++) {
      final count = rows[r];
      final rowPlayers = players.skip(playerIndex).take(count).toList();
      playerIndex += count;

      rowWidgets.add(
        Expanded(
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: rowPlayers
                  .map((p) => _buildPlayerNode(
                        context,
                        p,
                        isHome: isHome,
                        avatarSize: effectiveAvatarSize,
                        nameFontSize: effectiveNameFontSize,
                        nameMaxWidth: nameMaxWidth,
                      ))
                  .toList(),
            ),
          ),
        ),
      );
    }

    if (!isHome) {
      rowWidgets = rowWidgets.reversed.toList();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: rowWidgets,
      ),
    );
  }

  Widget _buildPlayerNode(
    BuildContext context,
    LineupPlayer player, {
    required bool isHome,
    required double avatarSize,
    required double nameFontSize,
    required double nameMaxWidth,
  }) {
    final teamColor = isHome
        ? AppColors.electricCyan
        : AppColors.coralCrimson;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Node Avatar with team glow ring
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            color: const Color(0xFF141F36),
            shape: BoxShape.circle,
            border: Border.all(color: teamColor, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: teamColor.withValues(alpha: 0.35),
                blurRadius: 8,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: (player.photoUrl != null && player.photoUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: player.photoUrl!,
                  memCacheWidth: 64,
                  memCacheHeight: 64,
                  fit: BoxFit.cover,
                  width: avatarSize,
                  height: avatarSize,
                  errorWidget: (context, url, error) =>
                      _buildFallbackNumber(player, teamColor, avatarSize),
                )
              : _buildFallbackNumber(player, teamColor, avatarSize),
        ),
        const SizedBox(height: 2),

        // High-contrast Name Capsule
        Container(
          constraints: BoxConstraints(maxWidth: nameMaxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Text(
            player.name,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: Colors.white,
              fontSize: nameFontSize,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackNumber(
    LineupPlayer player,
    Color teamColor,
    double avatarSize,
  ) {
    return Text(
      player.number > 0
          ? DateFormatter.toArabicNumerals('${player.number}')
          : player.initials,
      style: AppTypography.scoreHeadline(color: teamColor).copyWith(
        fontSize: (avatarSize * 0.44).clamp(13.0, 19.0),
        fontWeight: FontWeight.w800,
      ),
    );
  }

  List<int> _parseFormationRows(String? formation, int totalPlayers) {
    if (formation == null || formation.isEmpty) {
      if (totalPlayers == 11) return [1, 4, 3, 3];
      return [totalPlayers];
    }

    final parts = formation.split(RegExp(r'[-–—\s]+'));
    final counts = <int>[];

    for (final p in parts) {
      final parsed = int.tryParse(p.trim());
      if (parsed != null && parsed > 0) {
        counts.add(parsed);
      }
    }

    if (counts.isEmpty) return [totalPlayers];

    final sum = counts.fold<int>(0, (a, b) => a + b);
    if (sum == totalPlayers - 1) {
      return [1, ...counts]; // Prepend goalkeeper
    }
    if (sum == totalPlayers) {
      return counts;
    }

    return [1, ...counts];
  }
}

/// CustomPainter for realistic tactical turf markings with alternating lawn stripes.
class NeutralPitchPainter extends CustomPainter {
  final Color lineColor;

  const NeutralPitchPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw alternating turf lawn stripes
    final stripeHeight = size.height / 10;
    final stripePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 10; i++) {
      if (i.isEven) {
        stripePaint.color = Colors.white.withValues(alpha: 0.035);
        canvas.drawRect(
          Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
          stripePaint,
        );
      }
    }

    // 2. Pitch markings
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawRect(rect, paint);

    // Halfway Line
    final centerY = size.height / 2;
    canvas.drawLine(Offset(8, centerY), Offset(size.width - 8, centerY), paint);

    // Center Circle & Spot
    canvas.drawCircle(Offset(size.width / 2, centerY), 42, paint);
    final fillPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, centerY), 3, fillPaint);

    // Penalty Boxes (18-yard)
    final boxWidth = size.width * 0.54;
    final boxHeight = 65.0;
    final boxLeft = (size.width - boxWidth) / 2;

    canvas.drawRect(Rect.fromLTWH(boxLeft, 8, boxWidth, boxHeight), paint);
    canvas.drawRect(
      Rect.fromLTWH(boxLeft, size.height - 8 - boxHeight, boxWidth, boxHeight),
      paint,
    );

    // Goal Areas (6-yard)
    final smallBoxWidth = size.width * 0.28;
    final smallBoxHeight = 24.0;
    final smallBoxLeft = (size.width - smallBoxWidth) / 2;

    canvas.drawRect(Rect.fromLTWH(smallBoxLeft, 8, smallBoxWidth, smallBoxHeight), paint);
    canvas.drawRect(
      Rect.fromLTWH(smallBoxLeft, size.height - 8 - smallBoxHeight, smallBoxWidth, smallBoxHeight),
      paint,
    );

    // Penalty Spots
    canvas.drawCircle(Offset(size.width / 2, 8 + 48), 2.5, fillPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height - 8 - 48), 2.5, fillPaint);

    // Corner Arcs (8dp radius)
    canvas.drawArc(const Rect.fromLTWH(0, 0, 16, 16), 0, 1.57, false, paint);
    canvas.drawArc(Rect.fromLTWH(size.width - 16, 0, 16, 16), 1.57, 1.57, false, paint);
    canvas.drawArc(Rect.fromLTWH(0, size.height - 16, 16, 16), 4.71, 1.57, false, paint);
    canvas.drawArc(Rect.fromLTWH(size.width - 16, size.height - 16, 16, 16), 3.14, 1.57, false, paint);
  }

  @override
  bool shouldRepaint(covariant NeutralPitchPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

/// Compatibility PitchView class for tests and external consumers.
class PitchView extends StatelessWidget {
  final TeamLineupData homeData;
  final TeamLineupData awayData;

  const PitchView({
    super.key,
    required this.homeData,
    required this.awayData,
  });

  @override
  Widget build(BuildContext context) {
    return NeutralPitchView(homeData: homeData, awayData: awayData);
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/match_lineup_model.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../providers/match_details_providers.dart';

class LineupTab extends ConsumerWidget {
  final MatchDetailsParams params;

  const LineupTab({super.key, required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineupAsync = ref.watch(matchLineupProvider(params));

    return lineupAsync.when(
      data: (lineup) {
        if (lineup == null ||
            (lineup.homeLineup.startingXI.isEmpty && lineup.awayLineup.startingXI.isEmpty)) {
          return const Center(
            child: AppEmptyState(
              type: EmptyStateType.soccer,
              title: 'لم يتم الإعلان عن التشكيلة الرسمية بعد',
              subtitle: 'سيتم عرض خطة اللعب والتشكيلة الأساسية فور صدورها',
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
          children: [
            // Pitch Header with Formation Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFormationBadge('صاحب الأرض', lineup.homeLineup.formation),
                _buildFormationBadge('الفريق الضيف', lineup.awayLineup.formation),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Tactical Pitch Canvas
            SizedBox(
              height: 520,
              child: PitchView(
                homeData: lineup.homeLineup,
                awayData: lineup.awayLineup,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Coaches Section
            if (lineup.homeLineup.coach != null || lineup.awayLineup.coach != null) ...[
              Text(
                'المدير الفني',
                style: AppTypography.titleMedium(),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _buildCoachCard(lineup.homeLineup.coach ?? 'غير محدد'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildCoachCard(lineup.awayLineup.coach ?? 'غير محدد'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Substitutes Bench Section
            Text(
              'قائمة البدلاء',
              style: AppTypography.titleMedium(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildSubstitutesList(lineup.homeLineup.substitutes, isHome: true)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _buildSubstitutesList(lineup.awayLineup.substitutes, isHome: false)),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, stack) => Center(
        child: AppEmptyState(
          type: EmptyStateType.error,
          title: 'تعذر تحميل التشكيلة',
          subtitle: '$err',
        ),
      ),
    );
  }

  Widget _buildFormationBadge(String label, String? formation) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceHigh,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Text(
        '$label: ${formation != null ? DateFormatter.toArabicNumerals(formation) : "غير محدد"}',
        style: AppTypography.caption(
          color: AppColors.darkTextPrimary,
        ),
      ),
    );
  }

  Widget _buildCoachCard(String coachName) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      margin: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Row(
        children: [
          const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              coachName,
              style: AppTypography.bodySmall(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubstitutesList(List<LineupPlayer> subs, {required bool isHome}) {
    if (subs.isEmpty) {
      return Text(
        'لا يوجد بدلاء مسجلين',
        style: AppTypography.caption(color: AppColors.darkTextSecondary),
      );
    }
    return Column(
      children: subs.map((player) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              _buildPlayerAvatar(player, isHome: isHome, size: 28),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: AppTypography.caption(
                        color: AppColors.darkTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (player.positionTitle != null || player.position != null)
                      Text(
                        player.positionTitle ?? player.position!,
                        style: AppTypography.caption(
                          color: AppColors.darkTextMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: Text(
                  DateFormatter.toArabicNumerals('${player.number}'),
                  style: AppTypography.badge(
                    color: AppColors.darkTextSecondary,
                    size: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static Widget _buildPlayerAvatar(LineupPlayer player, {required bool isHome, double size = 32}) {
    final teamColor = isHome ? AppColors.primary : AppColors.gold;

    Widget fallbackAvatar() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: teamColor.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: teamColor, width: 1.5),
        ),
        child: Center(
          child: Text(
            player.number > 0
                ? DateFormatter.toArabicNumerals('${player.number}')
                : player.initials,
            style: TextStyle(
              color: teamColor,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.42,
            ),
          ),
        ),
      );
    }

    if (player.photoUrl != null && player.photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: player.photoUrl!,
        imageBuilder: (context, imageProvider) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: teamColor, width: 1.5),
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        ),
        placeholder: (context, url) => fallbackAvatar(),
        errorWidget: (context, url, error) => fallbackAvatar(),
      );
    }

    return fallbackAvatar();
  }
}

/// Pitch Visualization with custom field painter and player nodes layout.
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1F17),
              Color(0xFF133627),
              Color(0xFF0A1F17),
            ],
          ),
        ),
        child: CustomPaint(
          painter: FootballPitchPainter(),
          child: Stack(
            children: [
              // Home Team Pitch Nodes (Top Half)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.topCenter,
                  heightFactor: 0.5,
                  child: _buildTeamNodes(homeData, isHome: true),
                ),
              ),

              // Away Team Pitch Nodes (Bottom Half)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.bottomCenter,
                  heightFactor: 0.5,
                  child: _buildTeamNodes(awayData, isHome: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamNodes(TeamLineupData teamData, {required bool isHome}) {
    final players = teamData.startingXI;
    if (players.isEmpty) return const SizedBox.shrink();

    final rows = _parseFormationRows(teamData.formation, players.length);
    int playerIndex = 0;

    List<Widget> rowWidgets = [];

    for (int r = 0; r < rows.length; r++) {
      final count = rows[r];
      final rowPlayers = players.skip(playerIndex).take(count).toList();
      playerIndex += count;

      rowWidgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: rowPlayers
              .map((p) => _buildPlayerNode(p, isHome: isHome))
              .toList(),
        ),
      );
    }

    if (!isHome) {
      rowWidgets = rowWidgets.reversed.toList();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: rowWidgets,
    );
  }

  List<int> _parseFormationRows(String? formationStr, int totalPlayers) {
    if (formationStr != null) {
      final parts = formationStr
          .split(RegExp(r'[-–\s]+'))
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList();
      if (parts.isNotEmpty) {
        return [1, ...parts]; // 1 Goalkeeper + formation lines
      }
    }
    // Fallback if formation parsing fails: 1-4-4-2
    return [1, 4, 4, 2];
  }

  Widget _buildPlayerNode(LineupPlayer player, {required bool isHome}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LineupTab._buildPlayerAvatar(player, isHome: isHome, size: 32),
        const SizedBox(height: 3),
        Container(
          constraints: const BoxConstraints(maxWidth: 72),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppRadii.xs),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: Text(
            player.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// CustomPainter to render realistic football pitch markings.
class FootballPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Outer Boundary Line
    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    canvas.drawRect(rect, paint);

    // Center Line
    final centerY = size.height / 2;
    canvas.drawLine(Offset(10, centerY), Offset(size.width - 10, centerY), paint);

    // Center Circle
    canvas.drawCircle(Offset(size.width / 2, centerY), 48, paint);
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, centerY), 4, fillPaint);

    // Penalty Areas
    final boxWidth = size.width * 0.56;
    final boxHeight = 72.0;
    final boxLeft = (size.width - boxWidth) / 2;

    // Top Penalty Area
    canvas.drawRect(Rect.fromLTWH(boxLeft, 10, boxWidth, boxHeight), paint);
    // Bottom Penalty Area
    canvas.drawRect(Rect.fromLTWH(boxLeft, size.height - 10 - boxHeight, boxWidth, boxHeight), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

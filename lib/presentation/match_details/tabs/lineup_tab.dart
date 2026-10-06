import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/match_lineup_model.dart';
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
            (lineup.homeLineup.startingXI.isEmpty &&
                lineup.awayLineup.startingXI.isEmpty)) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'لم يتم الإعلان عن التشكيلة الرسمية بعد',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Pitch Header with Formation Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFormationBadge(context, 'الأرض', lineup.homeLineup.formation),
                _buildFormationBadge(context, 'الضيف', lineup.awayLineup.formation),
              ],
            ),
            const SizedBox(height: 12),

            // Tactical Pitch Canvas (Royal Stadium Sizing)
            SizedBox(
              height: (MediaQuery.sizeOf(context).width * 1.58).clamp(600.0, 680.0),
              child: PitchView(
                homeData: lineup.homeLineup,
                awayData: lineup.awayLineup,
              ),
            ),
            const SizedBox(height: 24),

            // Coaches Section
            if (lineup.homeLineup.coach != null ||
                lineup.awayLineup.coach != null) ...[
              Text(
                'المدير الفني',
                style: TextStyle(
                  color: AppColors.textPrimaryOf(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildCoachCard(
                      context,
                      lineup.homeLineup.coach ?? 'غير محدد',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCoachCard(
                      context,
                      lineup.awayLineup.coach ?? 'غير محدد',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Substitutes Bench Section
            Text(
              'قائمة البدلاء',
              style: TextStyle(
                color: AppColors.textPrimaryOf(context),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildSubstitutesList(
                    context,
                    lineup.homeLineup.substitutes,
                    isHome: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSubstitutesList(
                    context,
                    lineup.awayLineup.substitutes,
                    isHome: false,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, stack) => Center(
        child: Text(
          'خطأ في تحميل التشكيلة: $err',
          style: const TextStyle(color: AppColors.livePulse),
        ),
      ),
    );
  }

  Widget _buildFormationBadge(BuildContext context, String label, String? formation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderOf(context)),
      ),
      child: Text(
        '$label: ${formation != null ? DateFormatter.toArabicNumerals(formation) : "غير محدد"}',
        style: TextStyle(
          color: AppColors.textPrimaryOf(context),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCoachCard(BuildContext context, String coachName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorderOf(context)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              coachName,
              style: TextStyle(
                color: AppColors.textPrimaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubstitutesList(
    BuildContext context,
    List<LineupPlayer> subs, {
    bool isHome = true,
  }) {
    if (subs.isEmpty) {
      return Text(
        'لا يوجد بدلاء مسجلين',
        style: TextStyle(
          color: AppColors.textSecondaryOf(context),
          fontSize: 12,
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    // Sub avatar diameter: ~38px on typical 390px screens (+35.7% vs old 28px)
    final subAvatarSize = (screenWidth * 0.098).clamp(36.0, 42.0);

    return Column(
      children: subs.map((player) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.cardBorderOf(context).withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              _buildPlayerAvatar(player, isHome: isHome, size: subAvatarSize),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player.name,
                      style: TextStyle(
                        color: AppColors.textPrimaryOf(context),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (player.positionTitle != null || player.position != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          player.positionTitle ?? player.position!,
                          style: TextStyle(
                            color: AppColors.textSecondaryOf(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cardBorderOf(context).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  DateFormatter.toArabicNumerals('${player.number}'),
                  style: TextStyle(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @visibleForTesting
  static Widget buildPlayerAvatarForTesting(
    LineupPlayer player, {
    required bool isHome,
    double size = 42,
  }) =>
      _buildPlayerAvatar(player, isHome: isHome, size: size);

  static Widget _buildPlayerAvatar(
    LineupPlayer player, {
    required bool isHome,
    double size = 42,
  }) {
    final teamColor = isHome ? AppColors.primary : AppColors.secondary;

    Widget fallbackAvatar() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: teamColor.withValues(alpha: 0.22),
          shape: BoxShape.circle,
          border: Border.all(color: teamColor, width: 2.0),
        ),
        child: Center(
          child: Text(
            player.number > 0
                ? DateFormatter.toArabicNumerals('${player.number}')
                : player.initials,
            style: TextStyle(
              color: teamColor,
              fontWeight: FontWeight.w900,
              fontSize: (size * 0.44).clamp(18.0, 24.0),
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
            border: Border.all(color: teamColor, width: 2.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
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

  const PitchView({super.key, required this.homeData, required this.awayData});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: const Color(0xFF0C1929), // Royal Stadium Deep Navy Pitch
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pitchWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
            // Avatar diameter scaled relative to available pitch width:
            // ~49-51px on 390px screens (+20% to +25% further increase, clamp 46 to 54)
            final avatarSize = (pitchWidth * 0.138).clamp(46.0, 54.0);
            // Proportional name font size (+15% vs old, sharp and legible)
            final nameFontSize = (avatarSize * 0.23).clamp(11.0, 12.5);
            // Dynamic max width: ensures 5 players in a row fit with positive clearance
            final nameMaxWidth = (pitchWidth / 5.3).clamp(62.0, 72.0);

            return CustomPaint(
              painter: FootballPitchPainter(),
              child: Stack(
                children: [
                  // Home Team Pitch Nodes (Top Half)
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.topCenter,
                      heightFactor: 0.5,
                      child: _buildTeamNodes(
                        homeData,
                        isHome: true,
                        pitchWidth: pitchWidth,
                        avatarSize: avatarSize,
                        nameFontSize: nameFontSize,
                        nameMaxWidth: nameMaxWidth,
                      ),
                    ),
                  ),

                  // Away Team Pitch Nodes (Bottom Half)
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.bottomCenter,
                      heightFactor: 0.5,
                      child: _buildTeamNodes(
                        awayData,
                        isHome: false,
                        pitchWidth: pitchWidth,
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
    TeamLineupData teamData, {
    required bool isHome,
    required double pitchWidth,
    required double avatarSize,
    required double nameFontSize,
    required double nameMaxWidth,
  }) {
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
              .map((p) => _buildPlayerNode(
                    p,
                    isHome: isHome,
                    avatarSize: avatarSize,
                    nameFontSize: nameFontSize,
                    nameMaxWidth: nameMaxWidth,
                  ))
              .toList(),
        ),
      );
    }

    if (!isHome) {
      rowWidgets = rowWidgets.reversed.toList();
    }

    return Padding(
      padding: EdgeInsets.only(
        top: isHome ? 8.0 : 6.0,
        bottom: isHome ? 6.0 : 8.0,
        left: 4.0,
        right: 4.0,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: isHome ? Alignment.topCenter : Alignment.bottomCenter,
        child: SizedBox(
          width: pitchWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: rowWidgets,
          ),
        ),
      ),
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

  Widget _buildPlayerNode(
    LineupPlayer player, {
    required bool isHome,
    required double avatarSize,
    required double nameFontSize,
    required double nameMaxWidth,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LineupTab._buildPlayerAvatar(player, isHome: isHome, size: avatarSize),
        const SizedBox(height: 3),
        Container(
          constraints: BoxConstraints(maxWidth: nameMaxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            player.name,
            style: TextStyle(
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
}

/// CustomPainter to render realistic football pitch markings.
class FootballPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Outer Boundary Line
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawRect(rect, paint);

    // Center Line
    final centerY = size.height / 2;
    canvas.drawLine(Offset(8, centerY), Offset(size.width - 8, centerY), paint);

    // Center Circle
    canvas.drawCircle(Offset(size.width / 2, centerY), 45, paint);
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, centerY), 4, fillPaint);

    // Penalty Areas
    final boxWidth = size.width * 0.55;
    final boxHeight = 70.0;
    final boxLeft = (size.width - boxWidth) / 2;

    // Top Penalty Area
    canvas.drawRect(Rect.fromLTWH(boxLeft, 8, boxWidth, boxHeight), paint);
    // Bottom Penalty Area
    canvas.drawRect(
      Rect.fromLTWH(boxLeft, size.height - 8 - boxHeight, boxWidth, boxHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

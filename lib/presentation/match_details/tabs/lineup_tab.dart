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
            (lineup.homeLineup.startingXI.isEmpty && lineup.awayLineup.startingXI.isEmpty)) {
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
                _buildFormationBadge('الأرض', lineup.homeLineup.formation),
                _buildFormationBadge('الضيف', lineup.awayLineup.formation),
              ],
            ),
            const SizedBox(height: 12),

            // Tactical Pitch Canvas
            SizedBox(
              height: 480,
              child: PitchView(
                homeData: lineup.homeLineup,
                awayData: lineup.awayLineup,
              ),
            ),
            const SizedBox(height: 24),

            // Coaches Section
            if (lineup.homeLineup.coach != null || lineup.awayLineup.coach != null) ...[
              const Text(
                'المدير الفني',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildCoachCard(lineup.homeLineup.coach ?? 'غير محدد'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCoachCard(lineup.awayLineup.coach ?? 'غير محدد'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Substitutes Bench Section
            const Text(
              'قائمة البدلاء',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildSubstitutesList(lineup.homeLineup.substitutes)),
                const SizedBox(width: 12),
                Expanded(child: _buildSubstitutesList(lineup.awayLineup.substitutes)),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.liveIndicator),
      ),
      error: (err, stack) => Center(
        child: Text(
          'خطأ في تحميل التشكيلة: $err',
          style: const TextStyle(color: AppColors.livePulse),
        ),
      ),
    );
  }

  Widget _buildFormationBadge(String label, String? formation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        '$label: ${formation != null ? DateFormatter.toArabicNumerals(formation) : "غير محدد"}',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCoachCard(String coachName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: AppColors.liveIndicator, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              coachName,
              style: const TextStyle(
                color: AppColors.textPrimary,
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

  Widget _buildSubstitutesList(List<LineupPlayer> subs) {
    if (subs.isEmpty) {
      return const Text(
        'لا يوجد بدلاء مسجلين',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      );
    }
    return Column(
      children: subs.map((player) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  DateFormatter.toArabicNumerals('${player.number}'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  player.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: const Color(0xFF1B4332), // Deep pitch green
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
    final color = isHome ? AppColors.liveIndicator : Colors.amber;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: Center(
            child: Text(
              DateFormatter.toArabicNumerals('${player.number}'),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          constraints: const BoxConstraints(maxWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            player.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
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
    canvas.drawRect(Rect.fromLTWH(boxLeft, size.height - 8 - boxHeight, boxWidth, boxHeight), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

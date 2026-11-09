import 'package:flutter/material.dart';

import 'score_view.dart';

/// Backward-compatible wrapper delegating to modern [ScoreView].
class ScoreText extends StatelessWidget {
  final dynamic homeScore;
  final dynamic awayScore;
  final bool isLive;
  final bool isFinished;
  final double fontSize;

  const ScoreText({
    super.key,
    required this.homeScore,
    required this.awayScore,
    this.isLive = false,
    this.isFinished = false,
    this.fontSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return ScoreView(
      homeScore: homeScore,
      awayScore: awayScore,
      isLive: isLive,
      isFinished: isFinished,
      fontSize: fontSize,
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_number_format.dart';

/// Editorial Score View displaying tabular Latin digits with semantic labels.
class ScoreView extends StatelessWidget {
  final dynamic homeScore;
  final dynamic awayScore;
  final bool isLive;
  final bool isFinished;
  final double fontSize;

  const ScoreView({
    super.key,
    required this.homeScore,
    required this.awayScore,
    this.isLive = false,
    this.isFinished = false,
    this.fontSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final hScore = AppNumberFormat.formatScore(homeScore);
    final aScore = AppNumberFormat.formatScore(awayScore);

    final scoreColor = isLive
        ? AppColors.primaryOf(context)
        : (isFinished
            ? AppColors.textPrimaryOf(context)
            : AppColors.textSecondaryOf(context));

    final numberStyle = AppTypography.scoreLarge(color: scoreColor).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
    );

    final separatorStyle = AppTypography.scoreSmall(
      color: scoreColor.withValues(alpha: 0.5),
    ).copyWith(
      fontSize: fontSize * 0.7,
      fontWeight: FontWeight.w600,
    );

    return Semantics(
      label: 'النتيجة: $hScore مقابل $aScore',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Home Score (Right side in RTL)
          Text(hScore, style: numberStyle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(':', style: separatorStyle),
          ),
          // Away Score (Left side in RTL)
          Text(aScore, style: numberStyle),
        ],
      ),
    );
  }
}


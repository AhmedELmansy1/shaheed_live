import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/match_reminder_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/match_model.dart';
import '../team_logo.dart';

/// Modal bottom sheet allowing users to configure custom match reminder timing
/// (15 minutes, 30 minutes, 1 hour, or at kickoff).
class MatchReminderSheet extends ConsumerStatefulWidget {
  final MatchModel match;

  const MatchReminderSheet({super.key, required this.match});

  static Future<void> show(BuildContext context, {required MatchModel match}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MatchReminderSheet(match: match),
    );
  }

  @override
  ConsumerState<MatchReminderSheet> createState() => _MatchReminderSheetState();
}

class _MatchReminderSheetState extends ConsumerState<MatchReminderSheet> {
  int _selectedMinutesBefore = 15; // 15, 30, 60, 0
  bool _includeGoalAlerts = true;

  void _onConfirm() async {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();

    await ref.read(matchReminderServiceProvider).toggleReminder(
      widget.match,
      customMinutesBefore: _selectedMinutesBefore,
      includeGoalAlerts: _includeGoalAlerts,
    );

    if (mounted) {
      final leadText = _selectedMinutesBefore == 0
          ? 'عند انطلاق المباراة'
          : 'قبل بداية المباراة بـ $_selectedMinutesBefore دقيقة';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'تم ضبط التنبيه: $leadText 🔔',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.electricBlue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final primary = AppColors.primaryOf(context);

    final match = widget.match;
    final remainingStr = match.remainingTimeUntilKickoff;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        border: Border.all(color: border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.4),
                borderRadius: AppRadii.fullRadius,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Match Header: Teams + Kickoff
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedOf(context),
              borderRadius: AppRadii.lgRadius,
              border: Border.all(color: border, width: 0.8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          TeamLogo(
                            logoUrl: match.homeTeamLogo,
                            teamName: match.homeTeamName,
                            size: 28,
                          ),
                          const SizedBox(width: AppSpacing.xs + 2),
                          Expanded(
                            child: Text(
                              match.homeTeamName,
                              style: AppTypography.titleSmall(color: textPrimary).copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: Text(
                        '×',
                        style: AppTypography.titleMedium(color: textSecondary),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              match.awayTeamName,
                              style: AppTypography.titleSmall(color: textPrimary).copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs + 2),
                          TeamLogo(
                            logoUrl: match.awayTeamLogo,
                            teamName: match.awayTeamName,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Kickoff & Remaining Pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: AppRadii.fullRadius,
                        border: Border.all(color: primary.withValues(alpha: 0.3), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, size: 13, color: primary),
                          const SizedBox(width: 4),
                          Text(
                            'الساعة ${match.formattedLocalTime}',
                            style: AppTypography.caption(color: primary).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (remainingStr.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.coralCrimson.withValues(alpha: 0.12),
                          borderRadius: AppRadii.fullRadius,
                          border: Border.all(
                            color: AppColors.coralCrimson.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 13, color: AppColors.coralCrimson),
                            const SizedBox(width: 4),
                            Text(
                              remainingStr,
                              style: AppTypography.caption(color: AppColors.coralCrimson).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Options Header
          Text(
            'اختر موعد التنبيه قبل المباراة:',
            style: AppTypography.titleSmall(color: textPrimary).copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Timing Options List
          _buildTimingOption(15, 'قبل المباراة بـ 15 دقيقة', 'الموصى به للاستعداد لمشاهدة البث ⚡'),
          _buildTimingOption(30, 'قبل المباراة بـ 30 دقيقة', 'يصلك التنبيه مع نزول التشكيلة الرسمية ⏱️'),
          _buildTimingOption(60, 'قبل المباراة بساعة كاملة', 'تنبيه مبكر لمتابعة الاستوديو التحليلي 🔔'),
          _buildTimingOption(0, 'عند صافرة البداية مباشرة', 'تنبيه فوري لحظة انطلاق اللقاء ⚽'),

          const SizedBox(height: AppSpacing.sm),

          // Goal alerts switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedOf(context),
              borderRadius: AppRadii.mdRadius,
              border: Border.all(color: border, width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sports_soccer_rounded, size: 18, color: AppColors.neonEmerald),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'تنبيهات الأهداف الحية',
                      style: AppTypography.bodySmall(color: textPrimary).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: _includeGoalAlerts,
                  activeTrackColor: AppColors.neonEmerald,
                  activeThumbColor: AppColors.neonEmerald,
                  onChanged: (val) {
                    setState(() {
                      _includeGoalAlerts = val;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Confirm Button
          ElevatedButton(
            onPressed: _onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.lgRadius,
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notifications_active_rounded, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'تفعيل التنبيه',
                  style: AppTypography.titleSmall(color: Colors.white).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingOption(int minutes, String title, String subtitle) {
    final isSelected = _selectedMinutesBefore == minutes;
    final primary = AppColors.primaryOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedMinutesBefore = minutes;
        });
      },
      borderRadius: AppRadii.mdRadius,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: AppRadii.mdRadius,
          border: Border.all(
            color: isSelected ? primary : border.withValues(alpha: 0.6),
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? primary : textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall(color: textPrimary).copyWith(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption(color: textSecondary).copyWith(
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

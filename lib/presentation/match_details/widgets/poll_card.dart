import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/poll_service.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/poll_model.dart';

/// Interactive Poll Card rendered inside Match Details.
class PollCard extends ConsumerStatefulWidget {
  final String matchId;
  final bool isMatchFinished;

  const PollCard({
    super.key,
    required this.matchId,
    required this.isMatchFinished,
  });

  @override
  ConsumerState<PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<PollCard> {
  String? _selectedOptionId;
  bool _isVoting = false;
  PollModel? _optimisticPoll;

  @override
  Widget build(BuildContext context) {
    final pollAsync = ref.watch(matchPollStreamProvider(widget.matchId));

    return pollAsync.when(
      data: (poll) {
        final activePoll = _optimisticPoll ?? poll;
        if (activePoll == null || !activePoll.enabled || activePoll.options.isEmpty) {
          return const SizedBox.shrink();
        }

        final bool showResults = activePoll.hasUserVoted || widget.isMatchFinished;

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: AppRadii.mdRadius,
            border: Border.all(color: context.border, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Question + Status Tag
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.vermilion.withValues(alpha: 0.12),
                      borderRadius: AppRadii.smRadius,
                    ),
                    child: Icon(
                      CupertinoIcons.chart_bar_alt_fill,
                      size: 20,
                      color: context.vermilion,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activePoll.question,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'إجمالي المشاركات: ${DateFormatter.toArabicNumerals(activePoll.totalVotes.toString())}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isMatchFinished)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.finished.withValues(alpha: 0.15),
                        borderRadius: AppRadii.smRadius,
                      ),
                      child: Text(
                        'مغلق',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: context.finished,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Options list
              ...activePoll.options.map((option) {
                if (showResults) {
                  return _buildResultOption(context, activePoll, option);
                } else {
                  return _buildSelectableOption(context, option);
                }
              }),

              // Submit Vote Button (only when voting is open and user hasn't voted)
              if (!showResults) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  height: 48, // 48dp minimum touch target
                  child: FilledButton(
                    onPressed: (_selectedOptionId == null || _isVoting)
                        ? null
                        : () => _submitVote(activePoll),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.vermilion,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadii.smRadius,
                      ),
                    ),
                    child: _isVoting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'تأكيد التصويت',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildSelectableOption(BuildContext context, PollOption option) {
    final isSelected = _selectedOptionId == option.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: isSelected
            ? context.vermilion.withValues(alpha: 0.08)
            : context.surfaceElevated,
        borderRadius: AppRadii.smRadius,
        child: InkWell(
          onTap: _isVoting
              ? null
              : () {
                  setState(() {
                    _selectedOptionId = option.id;
                  });
                },
          borderRadius: AppRadii.smRadius,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48), // 48dp touch target
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: AppRadii.smRadius,
              border: Border.all(
                color: isSelected ? context.vermilion : context.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.circle,
                  color: isSelected ? context.vermilion : context.textMuted,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? context.vermilion : context.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultOption(BuildContext context, PollModel poll, PollOption option) {
    final pct = poll.percentageOf(option);
    final isUserPick = poll.userVotedOptionId == option.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: AppRadii.smRadius,
          border: Border.all(
            color: isUserPick ? context.vermilion : context.border,
            width: isUserPick ? 1.5 : 1.0,
          ),
        ),
        child: Stack(
          children: [
            // Percentage Fill Bar
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerRight, // RTL fill
                widthFactor: (pct / 100.0).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isUserPick
                        ? context.vermilion.withValues(alpha: 0.18)
                        : context.upcoming.withValues(alpha: 0.10),
                    borderRadius: AppRadii.smRadius,
                  ),
                ),
              ),
            ),

            // Content
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isUserPick)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: context.vermilion,
                            size: 16,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isUserPick ? FontWeight.bold : FontWeight.w500,
                            color: isUserPick ? context.vermilion : context.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  poll.formattedPercentageOf(option),
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: isUserPick ? context.vermilion : context.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitVote(PollModel currentPoll) async {
    final optId = _selectedOptionId;
    if (optId == null) return;

    setState(() {
      _isVoting = true;
      // Optimistic state
      final updatedOptions = currentPoll.options.map((o) {
        if (o.id == optId) return o.copyWith(votes: o.votes + 1);
        return o;
      }).toList();
      _optimisticPoll = currentPoll.copyWith(
        options: updatedOptions,
        totalVotes: currentPoll.totalVotes + 1,
        userVotedOptionId: optId,
      );
    });

    try {
      final service = ref.read(pollServiceProvider);
      final serverPoll = await service.vote(
        matchId: widget.matchId,
        optionId: optId,
      );
      if (mounted) {
        setState(() {
          _optimisticPoll = serverPoll;
          _isVoting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تسجيل تصويتك بنجاح! شكراً لمشاركتك 🎉',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        final alreadyVoted = errorMsg.contains('مسبقاً') || errorMsg.contains('already');

        // Persist local receipt so UI stays on results
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('poll_voted_option_${widget.matchId}', optId);

        if (!mounted) return;

        setState(() {
          _isVoting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              alreadyVoted
                  ? 'تم تسجيل تصويتك مسبقاً في هذا الاستطلاع 👍'
                  : 'تم تسجيل تصويتك بنجاح! شكراً لمشاركتك 🎉',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: alreadyVoted ? Colors.amber.shade800 : const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

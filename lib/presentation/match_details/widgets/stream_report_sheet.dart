import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/stream_report_service.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_extensions.dart';

/// Modal bottom sheet allowing users to report stream playback issues.
class StreamReportBottomSheet extends ConsumerStatefulWidget {
  final dynamic matchId;
  final String matchTitle;
  final String serverId;
  final String serverName;

  const StreamReportBottomSheet({
    super.key,
    required this.matchId,
    required this.matchTitle,
    required this.serverId,
    required this.serverName,
  });

  static Future<void> show(
    BuildContext context, {
    required dynamic matchId,
    required String matchTitle,
    required String serverId,
    required String serverName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StreamReportBottomSheet(
        matchId: matchId,
        matchTitle: matchTitle,
        serverId: serverId,
        serverName: serverName,
      ),
    );
  }

  @override
  ConsumerState<StreamReportBottomSheet> createState() =>
      _StreamReportBottomSheetState();
}

class _StreamReportBottomSheetState
    extends ConsumerState<StreamReportBottomSheet> {
  StreamIssueType _selectedIssue = StreamIssueType.buffering;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(streamReportServiceProvider);
      await service.submitReport(
        matchId: widget.matchId,
        matchTitle: widget.matchTitle,
        serverId: widget.serverId,
        serverName: widget.serverName,
        issueType: _selectedIssue,
        userComment: _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم استلام بلاغك بنجاح وسيعمل الفريق الفني على إصلاحه فورا',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.md + bottomInset,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: context.border, width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.vermilion.withValues(alpha: 0.12),
                  borderRadius: AppRadii.smRadius,
                ),
                child: Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
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
                      'الإبلاغ عن مشكلة في البث',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      '${widget.serverName} • ${widget.matchTitle}',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Issue Options
          ...StreamIssueType.values.map((type) {
            final isSelected = _selectedIssue == type;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: isSelected
                    ? context.vermilion.withValues(alpha: 0.08)
                    : context.surfaceElevated,
                borderRadius: AppRadii.smRadius,
                child: InkWell(
                  onTap: _isSubmitting
                      ? null
                      : () => setState(() => _selectedIssue = type),
                  borderRadius: AppRadii.smRadius,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 46),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          type.arabicLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? context.vermilion : context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: AppSpacing.sm),

          // Optional comment
          TextField(
            controller: _commentController,
            maxLength: 250,
            maxLines: 2,
            style: TextStyle(fontSize: 12, color: context.textPrimary),
            decoration: InputDecoration(
              hintText: 'ملاحظة إضافية توضح المشكلة (اختياري)...',
              hintStyle: TextStyle(fontSize: 11, color: context.textMuted),
              filled: true,
              fillColor: context.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: AppRadii.smRadius,
                borderSide: BorderSide(color: context.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.smRadius,
                borderSide: BorderSide(color: context.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.smRadius,
                borderSide: BorderSide(color: context.vermilion),
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: context.vermilion,
                shape: RoundedRectangleBorder(borderRadius: AppRadii.smRadius),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'إرسال البلاغ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}


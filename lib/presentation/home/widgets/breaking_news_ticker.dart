import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env_config.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/ticker_config_model.dart';

/// In-memory session tracking for dismissed tickers by text hash.
final Set<String> _dismissedTickerHashes = <String>{};

class BreakingNewsTicker extends ConsumerStatefulWidget {
  final TickerConfigModel? overrideConfig;

  const BreakingNewsTicker({
    super.key,
    this.overrideConfig,
  });

  @override
  ConsumerState<BreakingNewsTicker> createState() => _BreakingNewsTickerState();
}

class _BreakingNewsTickerState extends ConsumerState<BreakingNewsTicker> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // 1. In demo/public store builds, degrade safely and render nothing unless mocked
    if (EnvConfig.isDemoMode && widget.overrideConfig == null) {
      return const SizedBox.shrink();
    }

    final ticker = widget.overrideConfig ?? ref.watch(currentTickerConfigProvider);

    if (ticker == null || !ticker.isValid) {
      return const SizedBox.shrink();
    }

    final textHash = ticker.text.hashCode.toString();
    if (_dismissedTickerHashes.contains(textHash)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final (badgeColor, badgeText, badgeIcon) = _resolveStyle(ticker.type);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () async {
            if (ticker.actionUrl != null && ticker.actionUrl!.isNotEmpty) {
              try {
                final uri = Uri.parse(ticker.actionUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  return;
                }
              } catch (_) {}
            }
            if (reduceMotion) {
              setState(() => _isExpanded = !_isExpanded);
            }
          },
          child: Row(
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Content
              Expanded(
                child: Text(
                  ticker.text,
                  maxLines: _isExpanded ? 4 : 1,
                  overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),

              // Dismiss 'X' Button
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                splashRadius: 14,
                tooltip: 'إغلاق',
                onPressed: () {
                  setState(() {
                    _dismissedTickerHashes.add(textHash);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, String, IconData) _resolveStyle(String type) {
    switch (type) {
      case 'warning':
        return (Colors.amber.shade800, 'تنبيه', Icons.warning_amber_rounded);
      case 'info':
        return (const Color(0xFF3B5BDB), 'معلومة', Icons.info_outline_rounded);
      case 'breaking':
      default:
        return (const Color(0xFFE5482D), 'عاجل', Icons.local_fire_department_rounded);
    }
  }
}

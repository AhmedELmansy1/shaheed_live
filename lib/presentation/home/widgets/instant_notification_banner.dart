import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/remote_config_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';

/// Provider streaming the latest instant notification from Firestore `config/app_settings`.
final latestNotificationStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final service = ref.watch(remoteConfigServiceProvider);
  return service.listenToLatestNotification();
});

/// Sleek in-app announcement banner displaying instant push notifications sent from the dashboard.
class InstantNotificationBanner extends ConsumerStatefulWidget {
  const InstantNotificationBanner({super.key});

  @override
  ConsumerState<InstantNotificationBanner> createState() =>
      _InstantNotificationBannerState();
}

class _InstantNotificationBannerState
    extends ConsumerState<InstantNotificationBanner> {
  String? _dismissedNotifId;

  @override
  void initState() {
    super.initState();
    _loadDismissedId();
  }

  Future<void> _loadDismissedId() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getString('dismissed_in_app_notif_id');
    if (mounted && dismissed != null) {
      setState(() => _dismissedNotifId = dismissed);
    }
  }

  Future<void> _dismiss(String notifId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dismissed_in_app_notif_id', notifId);
    if (mounted) {
      setState(() => _dismissedNotifId = notifId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifAsync = ref.watch(latestNotificationStreamProvider);

    return notifAsync.when(
      data: (data) {
        if (data == null || data.isEmpty) return const SizedBox.shrink();

        final notifId = data['id']?.toString() ?? '';
        if (notifId.isEmpty || notifId == _dismissedNotifId) {
          return const SizedBox.shrink();
        }

        final title = data['title']?.toString() ?? 'إشعار جديد';
        final body = data['body']?.toString() ?? '';
        final matchId = data['match_id']?.toString();
        final clickUrl = data['click_url']?.toString();

        final textPrimary = AppColors.textPrimaryOf(context);
        final textSecondary = AppColors.textSecondaryOf(context);

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF59E0B).withValues(alpha: 0.12),
                const Color(0xFFE5482D).withValues(alpha: 0.08),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.md),
              onTap: () async {
                HapticFeedback.lightImpact();
                if (matchId != null && matchId.isNotEmpty && matchId != '0') {
                  context.push('/match/$matchId');
                } else if (clickUrl != null && clickUrl.isNotEmpty) {
                  final uri = Uri.tryParse(clickUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bell Glowing Icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF59E0B),
                          width: 1.2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.bell_fill,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Notification Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5482D),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'فوري',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (body.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              DateFormatter.toArabicNumerals(body),
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11,
                                height: 1.3,
                                fontFamily: 'Cairo',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Dismiss Button (X)
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: textSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      onPressed: () => _dismiss(notifId),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/fcm_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_logo.dart';
import 'providers/onboarding_provider.dart';

class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  ConsumerState<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends ConsumerState<NotificationPermissionScreen> {
  bool _isProcessing = false;

  Future<void> _requestNotificationPermission() async {
    setState(() => _isProcessing = true);

    try {
      // 1. Request runtime notification permission (Android 13+ & iOS)
      final status = await Permission.notification.request();

      // 2. Request FCM permissions safely (iOS / Web)
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        debugPrint('FCM requestPermission skipped/failed: $e');
      }

      if (status.isGranted) {
        await _onPermissionGranted();
      } else {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      _showPermissionDeniedDialog();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _onPermissionGranted() async {
    // Initialize Messaging Handlers via services
    try {
      await ref.read(notificationServiceProvider).init();
      ref.read(fcmServiceProvider).init();
    } catch (e) {
      debugPrint('Notification/FCM service setup error: $e');
    }

    // Persist completed notification setup
    await ref.read(onboardingProvider.notifier).completeNotificationSetup();

    if (mounted) {
      context.go('/onboarding/leagues');
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: const Text(
            'التنبيهات مطلوبة للمتابعة',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'تطبيق شوت لايف يعتمد بشكل أساسي على الإشعارات المباشرة لتنبيهك بالأهداف وأحداث المباريات والتشكيلة. يرجى تفعيل الإشعارات من إعدادات النظام للمتابعة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton(
              onPressed: () async {
                await openAppSettings();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.divider),
              ),
              child: const Text('فتح الإعدادات'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final status = await Permission.notification.status;
                if (status.isGranted) {
                  await _onPermissionGranted();
                } else {
                  _showPermissionDeniedDialog();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.liveIndicator,
                foregroundColor: Colors.black,
              ),
              child: const Text('تحقق مرة أخرى'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              const Spacer(),
              const AppLogo(size: 90, showSubtitle: true),
              const SizedBox(height: 40),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.liveIndicator.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  size: 48,
                  color: AppColors.liveIndicator,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'تفعيل إشعارات المباريات المباشرة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'احصل على تنبيهات لحظية بالأهداف، بداية ونهاية المباريات، وتشكيلة الفرق المفضلة لديك فور إعلانها حتى أثناء إغلاق التطبيق.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _isProcessing ? null : _requestNotificationPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.liveIndicator,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'تفعيل الإشعارات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

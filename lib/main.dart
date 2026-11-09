import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/env_config.dart';
import 'core/localization/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/services/ad_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/firebase_ready_provider.dart';
import 'core/services/match_reminder_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/remote_config_service.dart';
import 'core/services/sync_queue_service.dart';
import 'core/services/user_sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/timezone_helper.dart';
import 'presentation/widgets/animated_app_background.dart';
import 'firebase_options.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized inside the background isolate if cold-started
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      await Firebase.initializeApp();
    }
  }
  debugPrint('[FCM Background] 📩 Handling background message ID: ${message.messageId}');
  debugPrint('[FCM Background]   - Topic/From: ${message.from}');
  debugPrint('[FCM Background]   - Data: ${message.data}');
  debugPrint('[FCM Background]   - Notification: title="${message.notification?.title}", body="${message.notification?.body}"');

  // If the message has no system notification payload (e.g. data-only message), display it via local notifications
  if (message.notification == null && message.data.isNotEmpty) {
    final title = message.data['title']?.toString() ?? 'شوت لايف';
    final body = message.data['body']?.toString() ?? '';
    if (title.isNotEmpty || body.isNotEmpty) {
      try {
        final localPlugin = FlutterLocalNotificationsPlugin();
        const androidDetails = AndroidNotificationDetails(
          NotificationService.channelMatches,
          'تنبيهات المباريات',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_stat_notify',
        );
        const details = NotificationDetails(android: androidDetails);
        await localPlugin.show(
          id: message.messageId.hashCode,
          title: title,
          body: body,
          notificationDetails: details,
          payload: message.data['match_id'] != null
              ? '{"type":"match_reminder","matchId":"${message.data['match_id']}"}'
              : null,
        );
      } catch (e) {
        debugPrint('[FCM Background] Fallback local notification error: $e');
      }
    }
  }
}

Future<void> _initNotificationsSafely() async {
  try {
    final notificationService = NotificationService();
    await notificationService.init();
    debugPrint('[Main] Local notifications initialized.');
  } catch (e) {
    debugPrint('[Main] Local notifications init error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fast essential startup initializations (all local, zero network)
  await Future.wait([
    EnvConfig.init(),
    TimezoneHelper.init(),
    SharedPreferences.getInstance(),
  ]);

  // Launch local notifications service without blocking first frame
  final notifInitFuture = _initNotificationsSafely();

  runApp(ProviderScope(
    child: ShootLiveApp(
      notifInitFuture: notifInitFuture,
    ),
  ));
}

class ShootLiveApp extends ConsumerStatefulWidget {
  final Future<void>? notifInitFuture;

  const ShootLiveApp({
    super.key,
    this.notifInitFuture,
  });

  @override
  ConsumerState<ShootLiveApp> createState() => _ShootLiveAppState();
}

class _ShootLiveAppState extends ConsumerState<ShootLiveApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Defer all heavier services (Firebase, AdMob, FCM) until after the first frame is painted
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Initialize AdMob SDK and test device config
      MobileAds.instance.initialize().then((_) {
        AdService.initTestDeviceConfig();
      }).catchError((e) {
        debugPrint('[Main] AdMob init deferred error: $e');
      });

      // 2. Wait for notifications initialization
      if (widget.notifInitFuture != null) {
        await widget.notifInitFuture;
      }

      // 3. Initialize Firebase via dedicated firebaseReadyProvider with background message registration
      final firebaseNotifier = ref.read(firebaseReadyProvider.notifier);
      await firebaseNotifier.initializeFirebase(
        backgroundMessageHandler: _firebaseMessagingBackgroundHandler,
      );

      // 4. Initialize FCM listeners (guarded inside by firebaseReadyProvider)
      try {
        await ref.read(fcmServiceProvider).init();
      } catch (e) {
        debugPrint('[Main] FCM service init skipped/failed: $e');
      }

      // 5. Preload App Open Ad in parallel non-blocking
      try {
        ref.read(adServiceProvider).loadAppOpenAd();
      } catch (_) {}

      // 6. Start connectivity listener and reconcile any pending syncs
      try {
        final syncQueue = ref.read(syncQueueServiceProvider);
        syncQueue.startConnectivityMonitoring();
        syncQueue.processPendingSync();
      } catch (e) {
        debugPrint('[Main] SyncQueue init notice: $e');
      }

      // 7. Background Auth and Cloud Sync (guarded for runtime when Firebase is configured)
      if (Firebase.apps.isNotEmpty) {
        try {
          ref.read(authServiceProvider).ensureAuthenticated().then((_) {
            ref.read(userSyncServiceProvider).pullFirestoreToLocal().catchError((e) {
              debugPrint('[Main] Firestore pull sync notice: $e');
            });
          }).catchError((e) {
            debugPrint('[Main] Auth notice: $e');
          });
        } catch (e) {
          debugPrint('[Main] Auth notice: $e');
        }

        // 8. Reschedule pending match reminders
        try {
          ref.read(matchReminderServiceProvider).rescheduleAllReminders().catchError((e) {
            debugPrint('[Main] Match reminder reschedule notice: $e');
          });
        } catch (e) {
          debugPrint('[Main] Match reminder reschedule notice: $e');
        }

        // 9. Fetch initial remote config
        () async {
          try {
            await ref.read(remoteConfigServiceProvider).fetchInitialConfig();
          } catch (e) {
            debugPrint('[Main] Remote config fetch notice: $e');
          }
        }();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final adService = ref.read(adServiceProvider);

    if (state == AppLifecycleState.paused) {
      adService.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      adService.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final themeConfig = ref.watch(currentThemeConfigProvider);
    final lightColors = themeConfig.toThemeColors(isDark: false);
    final darkColors = themeConfig.toThemeColors(isDark: true);

    return MaterialApp.router(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(overrideColors: lightColors),
      darkTheme: AppTheme.getDarkTheme(overrideColors: darkColors),
      themeMode: themeMode,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AnimatedAppBackground(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

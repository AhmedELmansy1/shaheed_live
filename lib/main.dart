import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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
import 'core/services/match_reminder_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/remote_config_service.dart';
import 'core/services/user_sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/timezone_helper.dart';
import 'presentation/widgets/animated_app_background.dart';
import 'firebase_options.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] 📩 Handling background message ID: ${message.messageId}');
  debugPrint('[FCM Background]   - Topic/From: ${message.from}');
  debugPrint('[FCM Background]   - Data: ${message.data}');
  debugPrint('[FCM Background]   - Notification: title="${message.notification?.title}", body="${message.notification?.body}"');
}

Future<void> _initFirebaseSafely() async {
  try {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      await Firebase.initializeApp();
    }
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('[Main] Firebase initialized successfully.');
  } catch (e) {
    debugPrint('[Main] Firebase initialization fallback/skipped: $e');
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

  // Parallelize critical startup initializations
  await Future.wait([
    EnvConfig.init(),
    TimezoneHelper.init(),
    _initFirebaseSafely(),
    _initNotificationsSafely(),
    SharedPreferences.getInstance(),
  ]);

  runApp(const ProviderScope(child: ShootLiveApp()));
}

class ShootLiveApp extends ConsumerStatefulWidget {
  const ShootLiveApp({super.key});

  @override
  ConsumerState<ShootLiveApp> createState() => _ShootLiveAppState();
}

class _ShootLiveAppState extends ConsumerState<ShootLiveApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Defer non-critical services (AdMob, FCM listener) until after first frame is painted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Initialize AdMob SDK and test device config
      MobileAds.instance.initialize().then((_) {
        AdService.initTestDeviceConfig();
      }).catchError((e) {
        debugPrint('[Main] AdMob init deferred error: $e');
      });

      // 2. Initialize FCM foreground listener
      try {
        ref.read(fcmServiceProvider).init();
      } catch (e) {
        debugPrint('[Main] FCM service init skipped/failed: $e');
      }

      // 3. Preload App Open Ad in parallel non-blocking
      try {
        ref.read(adServiceProvider).loadAppOpenAd();
      } catch (_) {}

      // 4. Background Auth and Cloud Sync (guarded for runtime when Firebase is configured)
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

        // 5. Reschedule pending match reminders
        try {
          ref.read(matchReminderServiceProvider).rescheduleAllReminders().catchError((e) {
            debugPrint('[Main] Match reminder reschedule notice: $e');
          });
        } catch (e) {
          debugPrint('[Main] Match reminder reschedule notice: $e');
        }

        // 6. Fetch initial remote config
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

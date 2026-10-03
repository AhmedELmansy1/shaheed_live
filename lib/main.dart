import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/config/env_config.dart';
import 'core/localization/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/services/ad_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/timezone_helper.dart';
import 'firebase_options.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background FCM message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await EnvConfig.init();

  // Initialize Firebase safely
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

  // Initialize timezone rules
  await TimezoneHelper.init();

  // Initialize Local Notifications
  try {
    final notificationService = NotificationService();
    await notificationService.init();
    debugPrint('[Main] Local notifications initialized.');
  } catch (e) {
    debugPrint('[Main] Local notifications init error: $e');
  }

  // Initialize AdMob SDK with test device configuration
  await MobileAds.instance.initialize();
  await AdService.initTestDeviceConfig();

  runApp(
    const ProviderScope(
      child: ShootLiveApp(),
    ),
  );
}

class ShootLiveApp extends ConsumerStatefulWidget {
  const ShootLiveApp({super.key});

  @override
  ConsumerState<ShootLiveApp> createState() => _ShootLiveAppState();
}

class _ShootLiveAppState extends ConsumerState<ShootLiveApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize FCM foreground listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(fcmServiceProvider).init();
      } catch (e) {
        debugPrint('[Main] FCM service init skipped/failed: $e');
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

    return MaterialApp.router(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

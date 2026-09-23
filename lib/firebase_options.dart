import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Generated manually from google-services.json configuration.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD_RTsJ_UoQ04frF9BvsMYt56y5h7J225s',
    appId: '1:463115339836:android:9e54378647b1122c1b1b39',
    messagingSenderId: '463115339836',
    projectId: 'shoot-bc845',
    storageBucket: 'shoot-bc845.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD_RTsJ_UoQ04frF9BvsMYt56y5h7J225s',
    appId: '1:463115339836:ios:9e54378647b1122c1b1b39',
    messagingSenderId: '463115339836',
    projectId: 'shoot-bc845',
    storageBucket: 'shoot-bc845.firebasestorage.app',
    iosBundleId: 'com.shootlive.app.shootLive',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD_RTsJ_UoQ04frF9BvsMYt56y5h7J225s',
    appId: '1:463115339836:web:9e54378647b1122c1b1b39',
    messagingSenderId: '463115339836',
    projectId: 'shoot-bc845',
    storageBucket: 'shoot-bc845.firebasestorage.app',
  );
}

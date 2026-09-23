# Flutter ProGuard / R8 Rules

# Flutter Engine & Plugin Registrant
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# AndroidX WorkManager & Room (Critical for flutter_local_notifications & background workers)
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.room.RoomDatabase
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker
-dontwarn androidx.work.**
-dontwarn androidx.room.**

# AndroidX Startup
-keep class androidx.startup.** { *; }
-dontwarn androidx.startup.**

# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.mediation.** { *; }
-keep class io.flutter.plugins.googlemobileads.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn io.flutter.plugins.googlemobileads.**

# Firebase Core, Auth, Firestore, Messaging
-keep class com.google.firebase.** { *; }
-keep class io.flutter.plugins.firebase.** { *; }
-dontwarn com.google.firebase.**
-dontwarn io.flutter.plugins.firebase.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# SharedPreferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Desugaring & Java 8+ APIs
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

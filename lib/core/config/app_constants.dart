/// Single source of truth for application branding and constants.
class AppConstants {
  /// Arabic brand display name across all user-facing UI
  static const String appName = 'شاهد لايف';

  /// English brand display name
  static const String appTitle = 'Shahid Live';

  static const String defaultLocale = 'ar';

  /// Feature flag for live streaming features. Enabled by default so stream links and watch buttons
  /// are active during testing and standard builds. Can be explicitly disabled via
  /// `--dart-define=ENABLE_STREAMING=false`.
  static bool enableStreaming =
      const bool.fromEnvironment('ENABLE_STREAMING', defaultValue: true);

  /// الرابط الافتراضي لتحميل التحديث الجديد لتطبيق شاهد لايف (يمكن تغييره من هنا أو من لوحة التحكم Remote Config)
  static const String defaultUpdateDownloadUrl = 'https://example.com/download';

  /// تفعيل ظهور نافذة إشعار التحديث الجديد للمشتركين عند فتح التطبيق
  static const bool showUpdatePromptOnStart = true;
}

/// Single source of truth for application branding and constants.
class AppConstants {
  /// Arabic brand display name across all user-facing UI
  static const String appName = 'شوت لايف';

  /// English brand display name
  static const String appTitle = 'Shoot Live';

  static const String defaultLocale = 'ar';

  /// Feature flag for live streaming features. Enabled by default so stream links and watch buttons
  /// are active during testing and standard builds. Can be explicitly disabled via
  /// `--dart-define=ENABLE_STREAMING=false`.
  static bool enableStreaming =
      const bool.fromEnvironment('ENABLE_STREAMING', defaultValue: true);
}

/// Single source of truth for application branding and constants.
class AppConstants {
  /// Arabic brand display name across all user-facing UI
  static const String appName = 'شوت لايف';

  /// English brand display name
  static const String appTitle = 'Shoot Live';

  static const String defaultLocale = 'ar';

  /// Compile-time feature flag to completely gate live streaming features in public store builds.
  /// Defaults to `false` so public builds contain zero stream UI entry points and never fetch stream URLs.
  /// Pass `--dart-define=ENABLE_STREAMING=true` only for private/internal builds with live video streaming.
  static bool enableStreaming =
      const bool.fromEnvironment('ENABLE_STREAMING', defaultValue: false);
}

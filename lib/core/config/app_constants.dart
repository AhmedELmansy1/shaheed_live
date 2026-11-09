/// Single source of truth for application branding and constants.
class AppConstants {
  /// Arabic brand display name across all user-facing UI
  static const String appName = 'مدرّج';

  /// English brand display name
  static const String appTitle = 'Modarraj';

  static const String defaultLocale = 'ar';

  /// Compile-time feature flag for live streaming features. Defaults to `false` for store compliance.
  /// Enable via `--dart-define=ENABLE_STREAMING=true`.
  static bool enableStreaming =
      const bool.fromEnvironment('ENABLE_STREAMING', defaultValue: false);
}

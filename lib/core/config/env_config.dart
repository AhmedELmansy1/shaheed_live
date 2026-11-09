import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Class for accessing environment configurations loaded from `.env`.
class EnvConfig {
  static const String defaultBaseApiUrl =
      'https://shoot-live-admin-dashboard.vercel.app/api/matches';
  static const String defaultDashboardBaseUrl =
      'https://shoot-live-admin-dashboard.vercel.app';

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {}
  }

  static String get baseApiUrl {
    if (dotenv.isInitialized) {
      return dotenv.env['BASE_API_URL'] ?? defaultBaseApiUrl;
    }
    return defaultBaseApiUrl;
  }

  static String get dashboardBaseUrl {
    const defineUrl = String.fromEnvironment('DASHBOARD_BASE_URL');
    if (defineUrl.isNotEmpty) return defineUrl;
    if (dotenv.isInitialized) {
      final envVal = dotenv.env['DASHBOARD_BASE_URL'];
      if (envVal != null && envVal.trim().isNotEmpty) return envVal.trim();
    }
    final api = baseApiUrl;
    if (api.contains('/api/matches')) {
      return api.substring(0, api.indexOf('/api/matches'));
    }
    return defaultDashboardBaseUrl;
  }

  static bool get isDemoMode {
    const defineMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);
    if (defineMode) return true;
    if (dotenv.isInitialized) {
      final envVal = dotenv.env['DEMO_MODE']?.toLowerCase();
      if (envVal == 'true' || envVal == '1') return true;
    }
    return false;
  }
}

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Class for accessing environment configurations loaded from `.env`.
class EnvConfig {
  static const String defaultBaseApiUrl =
      'https://shoot-live-admin-dashboard.vercel.app/api/matches';

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
}

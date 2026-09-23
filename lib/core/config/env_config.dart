import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Class for accessing environment configurations loaded from `.env`.
class EnvConfig {
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {}
  }

  static String get baseApiUrl {
    if (dotenv.isInitialized) {
      return dotenv.env['BASE_API_URL'] ?? 'https://matches-api.edwardmitrovic.workers.dev/';
    }
    return 'https://matches-api.edwardmitrovic.workers.dev/';
  }
}

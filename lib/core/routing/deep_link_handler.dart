import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Central handler for parsing and routing incoming deep links.
/// Supports both custom schemes (shootlive://match/{id}) and universal links (https://shootlive.app/match/{id}).
class DeepLinkHandler {
  /// Extracts the match ID from an incoming URI.
  /// Supports:
  /// - `shootlive://match/12345`
  /// - `shootlive://match?id=12345`
  /// - `https://shootlive.app/match/12345`
  /// - `https://shootlive.app/match?id=12345`
  static String? extractMatchId(Uri uri) {
    try {
      // 1. Query parameter override
      final queryId = uri.queryParameters['id'] ?? uri.queryParameters['match_id'];
      if (queryId != null && queryId.trim().isNotEmpty) {
        return queryId.trim();
      }

      // 2. Custom scheme: shootlive://match/12345
      if (uri.scheme == 'shootlive' && uri.host == 'match') {
        if (uri.pathSegments.isNotEmpty) {
          final first = uri.pathSegments.first.trim();
          if (first.isNotEmpty) return first;
        }
      }

      // 3. Web URL: https://shootlive.app/match/12345
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'match') {
        if (uri.pathSegments.length >= 2) {
          final seg = uri.pathSegments[1].trim();
          if (seg.isNotEmpty) return seg;
        }
      }
    } catch (e) {
      debugPrint('[DeepLinkHandler] Error extracting matchId from URI $uri: $e');
    }
    return null;
  }

  /// Routes the incoming URI to the appropriate screen using [GoRouter].
  static bool handleUri(Uri uri, GoRouter router) {
    debugPrint('[DeepLinkHandler] Processing incoming URI: $uri');
    final matchId = extractMatchId(uri);
    if (matchId != null && matchId.isNotEmpty) {
      try {
        router.push('/match/$matchId');
        return true;
      } catch (e) {
        debugPrint('[DeepLinkHandler] Navigation error: $e');
      }
    }
    return false;
  }
}


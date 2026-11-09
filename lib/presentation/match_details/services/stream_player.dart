import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/match_stream_model.dart';
import '../screens/embed_player_screen.dart';
import '../screens/hls_player_screen.dart';

/// Clean abstraction for swappable stream playback engines.
/// Allows embedding WebViews, native HLS players, or external intent launchers
/// behind a uniform interface without coupling the presentation layer to any single player SDK.
abstract class StreamPlayer {
  Future<void> launch({
    required BuildContext context,
    required String streamUrl,
    required String serverName,
    required dynamic matchId,
    required String matchTitle,
    required String serverId,
  });
}

/// Stream player implementation that loads web iframe/embed players in an in-app browser.
class EmbedStreamPlayer implements StreamPlayer {
  const EmbedStreamPlayer();

  @override
  Future<void> launch({
    required BuildContext context,
    required String streamUrl,
    required String serverName,
    required dynamic matchId,
    required String matchTitle,
    required String serverId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmbedPlayerScreen(
          streamUrl: streamUrl,
          serverName: serverName,
          matchId: matchId,
          matchTitle: matchTitle,
          serverId: serverId,
        ),
      ),
    );
  }
}

/// Stream player implementation that plays direct HLS (.m3u8) streams.
class HlsStreamPlayer implements StreamPlayer {
  const HlsStreamPlayer();

  @override
  Future<void> launch({
    required BuildContext context,
    required String streamUrl,
    required String serverName,
    required dynamic matchId,
    required String matchTitle,
    required String serverId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HlsPlayerScreen(
          streamUrl: streamUrl,
          serverName: serverName,
        ),
      ),
    );
  }
}

/// Stream player implementation that hands off video streams to external system players (e.g. VLC, Chrome).
class ExternalStreamPlayer implements StreamPlayer {
  const ExternalStreamPlayer();

  @override
  Future<void> launch({
    required BuildContext context,
    required String streamUrl,
    required String serverName,
    required dynamic matchId,
    required String matchTitle,
    required String serverId,
  }) async {
    final uri = Uri.tryParse(streamUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Factory resolver that selects the appropriate [StreamPlayer] implementation based on [PlayerType].
class StreamPlayerResolver {
  const StreamPlayerResolver._();

  static StreamPlayer resolve(PlayerType playerType) {
    switch (playerType) {
      case PlayerType.hls:
        return const HlsStreamPlayer();
      case PlayerType.embed:
        return const EmbedStreamPlayer();
      case PlayerType.external:
        return const ExternalStreamPlayer();
    }
  }
}


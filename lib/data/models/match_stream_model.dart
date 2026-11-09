/// Supported stream player rendering types in mobile app.
enum PlayerType {
  hls,
  embed,
  external;

  static PlayerType fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'hls':
      case 'm3u8':
        return PlayerType.hls;
      case 'embed':
      case 'iframe':
      case 'webview':
        return PlayerType.embed;
      case 'external':
      default:
        return PlayerType.external;
    }
  }

  String toValue() {
    switch (this) {
      case PlayerType.hls:
        return 'hls';
      case PlayerType.embed:
        return 'embed';
      case PlayerType.external:
        return 'external';
    }
  }
}

/// Model representing an individual stream server source for a match.
class StreamServerModel {
  final String id;
  final String name;
  final String streamUrl;
  final PlayerType playerType;
  final bool isActive;
  final int priority;

  const StreamServerModel({
    required this.id,
    required this.name,
    required this.streamUrl,
    required this.playerType,
    required this.isActive,
    required this.priority,
  });

  /// Cleans and normalizes stream URLs, extracting iframe src attributes if pasted directly.
  static String normalizeStreamUrl(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return '';
    // If user pasted an iframe tag like <iframe src="https://..." ...>
    if (s.contains('<iframe') || s.contains('src=')) {
      final match = RegExp(r'''src=["']([^"']+)["']''').firstMatch(s);
      if (match != null && match.group(1) != null) {
        s = match.group(1)!.trim();
      }
    }
    if (s.startsWith('//')) {
      s = 'https:$s';
    } else if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'https://$s';
    }
    return s;
  }

  /// Validates that the stream URL uses a supported and secure scheme (http / https).
  bool get isValidUrl {
    final clean = normalizeStreamUrl(streamUrl);
    if (clean.isEmpty) return false;
    final uri = Uri.tryParse(clean);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  factory StreamServerModel.fromMap(Map<String, dynamic> map) {
    int parsePriority(dynamic p) {
      if (p is int) return p;
      if (p is num) return p.toInt();
      return int.tryParse(p?.toString() ?? '') ?? 99;
    }

    final rawUrl = normalizeStreamUrl((map['stream_url'] ?? map['url'] ?? '').toString());

    return StreamServerModel(
      id: (map['id'] ?? map['server_id'] ?? '').toString(),
      name: (map['name'] ?? map['title'] ?? 'سيرفر مشاهدة').toString(),
      streamUrl: rawUrl,
      playerType: PlayerType.fromString(
        map['player_type']?.toString() ?? map['type']?.toString(),
      ),
      isActive: (map['is_active'] as bool?) ?? (map['isActive'] as bool?) ?? true,
      priority: parsePriority(map['priority']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stream_url': streamUrl,
      'player_type': playerType.toValue(),
      'is_active': isActive,
      'priority': priority,
    };
  }
}

/// Model representing the live stream configuration document for a specific match.
class MatchStreamModel {
  final int matchId;
  final bool isEnabled;
  final String? streamUrl;
  final List<StreamServerModel> servers;

  const MatchStreamModel({
    required this.matchId,
    required this.isEnabled,
    this.streamUrl,
    required this.servers,
  });

  /// Factory creating an empty disabled stream model.
  factory MatchStreamModel.empty(int matchId) {
    return MatchStreamModel(
      matchId: matchId,
      isEnabled: false,
      streamUrl: null,
      servers: const [],
    );
  }

  /// Get active servers with valid http/https URLs, sorted strictly by priority ascending (1, 2, 3...).
  List<StreamServerModel> get activeServersSorted {
    if (!isEnabled) return const [];
    final activeList = servers
        .where((s) => s.isActive && s.isValidUrl)
        .toList();

    // Fallback: If servers array has no valid active items, but top-level streamUrl is configured
    if (activeList.isEmpty && streamUrl != null && streamUrl!.trim().isNotEmpty) {
      final clean = StreamServerModel.normalizeStreamUrl(streamUrl!);
      if (clean.isNotEmpty) {
        activeList.add(StreamServerModel(
          id: 'primary',
          name: 'سيرفر رئيسي',
          streamUrl: clean,
          playerType: PlayerType.embed,
          isActive: true,
          priority: 1,
        ));
      }
    }

    activeList.sort((a, b) => a.priority.compareTo(b.priority));
    return activeList;
  }

  bool get hasActiveServers => activeServersSorted.isNotEmpty;

  /// Primary stream URL to open (either explicit streamUrl or the highest priority server URL).
  String? get primaryStreamUrl {
    if (streamUrl != null && streamUrl!.trim().isNotEmpty) {
      return streamUrl!.trim();
    }
    return activeServersSorted.firstOrNull?.streamUrl;
  }

  /// Whether an active and playable stream is available.
  bool get hasActiveStream => isEnabled && (primaryStreamUrl != null && primaryStreamUrl!.isNotEmpty);

  factory MatchStreamModel.fromMap(Map<String, dynamic>? map, [dynamic fallbackMatchId]) {
    int parseMatchId(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) {
        final parsed = int.tryParse(val.trim());
        if (parsed != null) return parsed;
      }
      if (fallbackMatchId is int) return fallbackMatchId;
      if (fallbackMatchId is String) {
        final parsed = int.tryParse(fallbackMatchId.trim());
        if (parsed != null) return parsed;
      }
      return 0;
    }

    if (map == null) {
      return MatchStreamModel.empty(parseMatchId(fallbackMatchId));
    }

    final serversList = <StreamServerModel>[];
    final rawServers = map['servers'];
    if (rawServers is List) {
      for (final item in rawServers) {
        if (item is Map<String, dynamic>) {
          serversList.add(StreamServerModel.fromMap(item));
        } else if (item is Map) {
          serversList.add(StreamServerModel.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Direct stream_url field fallback support
    final directUrl = (map['stream_url'] ?? map['streamUrl'] ?? map['url'] ?? '').toString().trim();
    if (serversList.isEmpty && directUrl.isNotEmpty) {
      serversList.add(StreamServerModel(
        id: 'primary',
        name: (map['name'] ?? map['server_name'] ?? 'بث مباشر').toString(),
        streamUrl: directUrl,
        playerType: PlayerType.fromString(map['player_type']?.toString() ?? 'embed'),
        isActive: true,
        priority: 1,
      ));
    }

    final effectiveStreamUrl = directUrl.isNotEmpty
        ? directUrl
        : (serversList.isNotEmpty ? serversList.first.streamUrl : null);

    final isEnabled = (map['enabled'] as bool?) ??
        (map['is_enabled'] as bool?) ??
        (map['isEnabled'] as bool?) ??
        true;

    return MatchStreamModel(
      matchId: parseMatchId(map['match_id'] ?? map['matchId']),
      isEnabled: isEnabled,
      streamUrl: effectiveStreamUrl,
      servers: serversList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'match_id': matchId,
      'is_enabled': isEnabled,
      'servers': servers.map((s) => s.toMap()).toList(),
    };
  }
}

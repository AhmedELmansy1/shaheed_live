import 'package:flutter/foundation.dart';

/// Player playback engine supported for TV channels.
enum TvPlayerType {
  hls,
  embed,
  external;

  static TvPlayerType fromString(String? val) {
    switch (val?.trim().toLowerCase()) {
      case 'embed':
      case 'iframe':
      case 'webview':
        return TvPlayerType.embed;
      case 'external':
        return TvPlayerType.external;
      case 'hls':
      case 'm3u8':
      default:
        return TvPlayerType.hls;
    }
  }

  String get key {
    switch (this) {
      case TvPlayerType.embed:
        return 'embed';
      case TvPlayerType.external:
        return 'external';
      case TvPlayerType.hls:
        return 'hls';
    }
  }

  String get labelArabic {
    switch (this) {
      case TvPlayerType.embed:
        return 'مشغل ويب';
      case TvPlayerType.external:
        return 'مشغل خارجي';
      case TvPlayerType.hls:
        return 'بث HLS مباشر';
    }
  }
}

/// Represents a live TV sports channel managed via Firestore `tv_channels` collection.
@immutable
class TvChannelModel {
  final String id;
  final String name;
  final String logoUrl;
  final String defaultStreamUrl;
  final TvPlayerType defaultPlayerType;
  final String defaultQuality;
  final bool isActive;
  final int order;

  const TvChannelModel({
    required this.id,
    required this.name,
    this.logoUrl = '',
    this.defaultStreamUrl = '',
    this.defaultPlayerType = TvPlayerType.hls,
    this.defaultQuality = 'hd',
    this.isActive = true,
    this.order = 1,
  });

  /// Factory parser extracting from a Firestore map or local cache map.
  factory TvChannelModel.fromMap(Map<String, dynamic>? map, String docId) {
    if (map == null) {
      return TvChannelModel(id: docId, name: 'قناة رياضية');
    }

    final rawOrder = map['order'];
    int parsedOrder = 1;
    if (rawOrder is num) {
      parsedOrder = rawOrder.toInt();
    } else if (rawOrder != null) {
      parsedOrder = int.tryParse(rawOrder.toString()) ?? 1;
    }

    return TvChannelModel(
      id: docId.isNotEmpty ? docId : (map['id']?.toString() ?? ''),
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? (map['name'] as String).trim()
          : 'قناة رياضية',
      logoUrl: (map['logo_url'] as String?)?.trim() ?? '',
      defaultStreamUrl: (map['default_stream_url'] as String?)?.trim() ??
          (map['stream_url'] as String?)?.trim() ??
          (map['url'] as String?)?.trim() ??
          '',
      defaultPlayerType: TvPlayerType.fromString(
        (map['default_player_type'] ?? map['player_type']) as String?,
      ),
      defaultQuality:
          (map['default_quality'] ?? map['quality'])?.toString().trim().toLowerCase() ??
              'hd',
      isActive: (map['is_active'] as bool?) ?? (map['enabled'] as bool?) ?? true,
      order: parsedOrder,
    );
  }

  /// Converts this channel into a serializable JSON map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'default_stream_url': defaultStreamUrl,
      'default_player_type': defaultPlayerType.key,
      'default_quality': defaultQuality,
      'is_active': isActive,
      'order': order,
    };
  }

  TvChannelModel copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? defaultStreamUrl,
    TvPlayerType? defaultPlayerType,
    String? defaultQuality,
    bool? isActive,
    int? order,
  }) {
    return TvChannelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      defaultStreamUrl: defaultStreamUrl ?? this.defaultStreamUrl,
      defaultPlayerType: defaultPlayerType ?? this.defaultPlayerType,
      defaultQuality: defaultQuality ?? this.defaultQuality,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
    );
  }

  /// Resolves the actual player engine to use, intelligently detecting if a URL
  /// is an HTML webpage/embed vs a direct video stream (.m3u8/.mp4).
  TvPlayerType get effectivePlayerType {
    final clean = defaultStreamUrl.toLowerCase().trim();
    if (clean.isEmpty) return defaultPlayerType;

    // Explicit external intent URLs
    if (defaultPlayerType == TvPlayerType.external) {
      return TvPlayerType.external;
    }

    // Direct video stream extensions -> always native HLS
    if (clean.contains('.m3u8') || clean.contains('.mp4')) {
      return TvPlayerType.hls;
    }

    // Explicit web player / embed pages -> Embed WebView player
    if (clean.endsWith('.php') ||
        clean.contains('.php?') ||
        clean.endsWith('.html') ||
        clean.contains('.html?') ||
        clean.endsWith('.htm') ||
        clean.contains('.htm?') ||
        clean.contains('embed') ||
        clean.contains('iframe') ||
        clean.contains('/tv/') ||
        clean.contains('/live/')) {
      return TvPlayerType.embed;
    }

    return defaultPlayerType;
  }

  /// Formatted quality badge string (e.g. FHD 1080p, HD 720p).
  String get qualityBadge {
    switch (defaultQuality.toLowerCase()) {
      case 'fhd':
        return 'FHD';
      case 'sd':
        return 'SD';
      case 'auto':
        return 'AUTO';
      case 'hd':
      default:
        return 'HD';
    }
  }

  /// Initial fallback channels matching dashboard `DEFAULT_CHANNELS`.
  static const List<TvChannelModel> defaultChannels = [
    TvChannelModel(
      id: 'bein_1',
      name: 'beIN Sports 1 HD',
      logoUrl: 'https://imgs.ysscores.com/championship/48/3411694791422.png',
      defaultStreamUrl: 'https://example.com/live/bein1.m3u8',
      defaultPlayerType: TvPlayerType.hls,
      defaultQuality: 'fhd',
      isActive: true,
      order: 1,
    ),
    TvChannelModel(
      id: 'bein_2',
      name: 'beIN Sports 2 HD',
      logoUrl: 'https://imgs.ysscores.com/championship/48/3411694791422.png',
      defaultStreamUrl: 'https://example.com/live/bein2.m3u8',
      defaultPlayerType: TvPlayerType.hls,
      defaultQuality: 'hd',
      isActive: true,
      order: 2,
    ),
    TvChannelModel(
      id: 'ssc_1',
      name: 'SSC 1 HD (السعودية)',
      logoUrl: 'https://imgs.ysscores.com/championship/48/3411694791422.png',
      defaultStreamUrl: 'https://example.com/live/ssc1.m3u8',
      defaultPlayerType: TvPlayerType.hls,
      defaultQuality: 'hd',
      isActive: true,
      order: 3,
    ),
    TvChannelModel(
      id: 'ad_sports_1',
      name: 'أبو ظبي الرياضية 1',
      logoUrl: 'https://imgs.ysscores.com/championship/48/3411694791422.png',
      defaultStreamUrl: 'https://example.com/live/adsports1.m3u8',
      defaultPlayerType: TvPlayerType.hls,
      defaultQuality: 'hd',
      isActive: true,
      order: 4,
    ),
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TvChannelModel &&
        other.id == id &&
        other.name == name &&
        other.logoUrl == logoUrl &&
        other.defaultStreamUrl == defaultStreamUrl &&
        other.defaultPlayerType == defaultPlayerType &&
        other.defaultQuality == defaultQuality &&
        other.isActive == isActive &&
        other.order == order;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        logoUrl,
        defaultStreamUrl,
        defaultPlayerType,
        defaultQuality,
        isActive,
        order,
      );
}


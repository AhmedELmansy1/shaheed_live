import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/env_config.dart';
import '../../core/services/firebase_ready_provider.dart';
import '../models/tv_channel_model.dart';

/// Repository responsible for reading, caching, and streaming live TV channels from Firestore.
class TvChannelsRepository {
  final FirebaseFirestore? _explicitFirestore;
  final SharedPreferences? _explicitPrefs;

  static const String _cacheKey = 'cached_tv_channels_list_v1';

  TvChannelsRepository({
    FirebaseFirestore? firestore,
    SharedPreferences? prefs,
  })  : _explicitFirestore = firestore,
        _explicitPrefs = prefs;

  FirebaseFirestore? get _firestore {
    if (_explicitFirestore != null) return _explicitFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<SharedPreferences?> _getPrefs() async {
    if (_explicitPrefs != null) return _explicitPrefs;
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  /// Loads cached channels from persistent storage or returns default channels if none exist.
  Future<List<TvChannelModel>> getCachedChannels() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs?.getString(_cacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = json.decode(jsonStr);
        if (decoded is List) {
          final channels = decoded
              .whereType<Map<String, dynamic>>()
              .map((map) => TvChannelModel.fromMap(map, map['id']?.toString() ?? ''))
              .toList();
          if (channels.isNotEmpty) {
            channels.sort((a, b) => a.order.compareTo(b.order));
            return channels;
          }
        }
      }
    } catch (e) {
      debugPrint('[TvChannelsRepository] Error reading local cache: $e');
    }
    return TvChannelModel.defaultChannels;
  }

  /// Persists the latest channel list into local storage for offline resiliency.
  Future<void> _persistChannels(List<TvChannelModel> channels) async {
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        final rawList = channels.map((c) => c.toMap()).toList();
        await prefs.setString(_cacheKey, json.encode(rawList));
      }
    } catch (e) {
      debugPrint('[TvChannelsRepository] Error caching channels: $e');
    }
  }

  static const String _firestoreRestUrl =
      'https://firestore.googleapis.com/v1/projects/shoot-bc845/databases/(default)/documents/tv_channels?key=AIzaSyD_RTsJ_UoQ04frF9BvsMYt56y5h7J225s';

  /// Parses a document map from the Firestore REST API into a [TvChannelModel].
  @visibleForTesting
  static TvChannelModel parseRestDocForTesting(Map<String, dynamic> fields, String docId) =>
      _parseFirestoreRestDoc(fields, docId);

  static TvChannelModel _parseFirestoreRestDoc(Map<String, dynamic> fields, String docId) {
    String getString(String key) => fields[key]?['stringValue']?.toString() ?? '';
    bool getBool(String key, {bool fallback = true}) {
      final val = fields[key]?['booleanValue'];
      return val is bool ? val : fallback;
    }
    int getInt(String key, {int fallback = 1}) {
      final val = fields[key]?['integerValue'];
      if (val != null) return int.tryParse(val.toString()) ?? fallback;
      return fallback;
    }

    final rawName = getString('name');
    final name = rawName.isNotEmpty ? rawName : 'قناة رياضية';
    final logoUrl = getString('logo_url');
    final streamUrl = getString('default_stream_url').isNotEmpty
        ? getString('default_stream_url')
        : (getString('stream_url').isNotEmpty ? getString('stream_url') : getString('url'));
    final playerType = TvPlayerType.fromString(
      getString('default_player_type').isNotEmpty
          ? getString('default_player_type')
          : getString('player_type'),
    );
    final quality = getString('default_quality').isNotEmpty
        ? getString('default_quality')
        : (getString('quality').isNotEmpty ? getString('quality') : 'hd');
    final isActive = getBool('is_active', fallback: getBool('enabled', fallback: true));
    final order = getInt('order', fallback: 1);

    return TvChannelModel(
      id: docId,
      name: name,
      logoUrl: logoUrl,
      defaultStreamUrl: streamUrl,
      defaultPlayerType: playerType,
      defaultQuality: quality,
      isActive: isActive,
      order: order,
    );
  }

  /// Direct Firestore REST API fetch fallback if SDK or dashboard endpoint fails.
  Future<List<TvChannelModel>?> fetchFromFirestoreRest() async {
    try {
      final dio = Dio();
      final res = await dio.get(
        _firestoreRestUrl,
        options: Options(
          headers: {'Accept': 'application/json'},
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 6),
        ),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final rawDocs = res.data['documents'] as List?;
        if (rawDocs != null && rawDocs.isNotEmpty) {
          final channels = <TvChannelModel>[];
          for (final rawDoc in rawDocs) {
            if (rawDoc is Map<String, dynamic>) {
              final docName = rawDoc['name']?.toString() ?? '';
              final docId = docName.split('/').last;
              final fields = rawDoc['fields'] as Map<String, dynamic>?;
              if (fields != null) {
                channels.add(_parseFirestoreRestDoc(fields, docId));
              }
            }
          }
          if (channels.isNotEmpty) {
            channels.sort((a, b) => a.order.compareTo(b.order));
            await _persistChannels(channels);
            return channels;
          }
        }
      }
    } catch (e) {
      debugPrint('[TvChannelsRepository] Firestore REST API fallback notice: $e');
    }
    return null;
  }

  /// Fallback fetch from dashboard API `GET /api/channels`.
  Future<List<TvChannelModel>?> fetchFromApi() async {
    try {
      final dio = Dio();
      final url = '${EnvConfig.dashboardBaseUrl}/api/channels';
      final res = await dio.get(
        url,
        options: Options(
          headers: {'Accept': 'application/json'},
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 6),
        ),
      );
      if (res.statusCode == 200 && res.data != null) {
        final body = res.data is String ? json.decode(res.data as String) : res.data;
        final list = (body is Map ? body['channels'] : body) as List?;
        if (list != null && list.isNotEmpty) {
          final channels = list
              .map((item) => TvChannelModel.fromMap(
                    Map<String, dynamic>.from(item as Map),
                    item['id']?.toString() ?? '',
                  ))
              .toList();
          channels.sort((a, b) => a.order.compareTo(b.order));
          await _persistChannels(channels);
          return channels;
        }
      }
    } catch (e) {
      debugPrint('[TvChannelsRepository] HTTP fallback error: $e');
    }
    return null;
  }

  /// Real-time stream of TV channels from Firestore `tv_channels` with multi-tier fallback.
  /// Immediately yields cached items, then emits live Firestore updates.
  Stream<List<TvChannelModel>> listenToChannels() async* {
    // 1. Emit cached/default channels first for instant render
    final initial = await getCachedChannels();
    yield initial;

    // 2. Resolve Firestore instance safely
    FirebaseFirestore? fs = _firestore;
    if (fs == null && Firebase.apps.isNotEmpty) {
      try {
        fs = FirebaseFirestore.instance;
      } catch (_) {}
    }

    if (fs == null) {
      // Fetch via direct REST fallback while Firestore SDK is initializing
      final restChannels = await fetchChannels();
      if (restChannels.isNotEmpty) {
        yield restChannels;
      }
      return;
    }

    // 3. Listen to live Firestore snapshots without server-side orderBy
    // to avoid index requirement or type mismatch errors, sorting in Dart
    try {
      yield* fs.collection('tv_channels').snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return initial;
        }

        final channels = snapshot.docs.map((doc) {
          return TvChannelModel.fromMap(doc.data(), doc.id);
        }).toList();

        // Sort by order ascending
        channels.sort((a, b) => a.order.compareTo(b.order));

        // Background persist to local cache
        _persistChannels(channels);

        return channels;
      }).handleError((error, stackTrace) {
        debugPrint('[TvChannelsRepository] Live Firestore stream error: $error');
      });
    } catch (e) {
      debugPrint('[TvChannelsRepository] Failed to initialize Firestore listener: $e');
      final restChannels = await fetchChannels();
      if (restChannels.isNotEmpty) {
        yield restChannels;
      }
    }
  }

  /// One-off fetch of TV channels with multi-tier fallback (SDK -> Firestore REST -> Dashboard API -> Cache).
  Future<List<TvChannelModel>> fetchChannels() async {
    final fs = _firestore;
    if (fs != null) {
      try {
        final snap = await fs.collection('tv_channels').get();
        if (snap.docs.isNotEmpty) {
          final channels = snap.docs.map((doc) => TvChannelModel.fromMap(doc.data(), doc.id)).toList();
          channels.sort((a, b) => a.order.compareTo(b.order));
          await _persistChannels(channels);
          return channels;
        }
      } catch (e) {
        debugPrint('[TvChannelsRepository] Firestore SDK fetch notice: $e');
      }
    }

    // Tier 2: Direct Firestore REST API
    final restChannels = await fetchFromFirestoreRest();
    if (restChannels != null && restChannels.isNotEmpty) {
      return restChannels;
    }

    // Tier 3: Dashboard HTTP API
    final apiChannels = await fetchFromApi();
    if (apiChannels != null && apiChannels.isNotEmpty) {
      return apiChannels;
    }

    // Tier 4: Local persistent cache or default static channels
    return getCachedChannels();
  }
}

/// Provider for [TvChannelsRepository].
final tvChannelsRepositoryProvider = Provider<TvChannelsRepository>((ref) {
  return TvChannelsRepository();
});

/// StreamProvider listening to real-time TV channels.
/// Re-evaluates automatically once Firebase is initialized.
final tvChannelsStreamProvider = StreamProvider<List<TvChannelModel>>((ref) {
  ref.watch(firebaseReadyProvider);
  final repo = ref.watch(tvChannelsRepositoryProvider);
  return repo.listenToChannels();
});

/// Provider returning only active TV channels.
final activeTvChannelsProvider = Provider<List<TvChannelModel>>((ref) {
  final asyncVal = ref.watch(tvChannelsStreamProvider);
  final all = asyncVal.value ?? TvChannelModel.defaultChannels;
  return all.where((c) => c.isActive).toList();
});

/// Family provider resolving a channel by ID.
final tvChannelByIdProvider = Provider.family<TvChannelModel?, String>((ref, id) {
  final channels = ref.watch(activeTvChannelsProvider);
  try {
    return channels.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});


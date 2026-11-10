import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Real-time stream of TV channels from Firestore `tv_channels`.
  /// Immediately yields cached items, then emits live Firestore updates.
  Stream<List<TvChannelModel>> listenToChannels() async* {
    // 1. Emit cached/default channels first for instant render
    final initial = await getCachedChannels();
    yield initial;

    final fs = _firestore;
    if (fs == null) {
      return;
    }

    try {
      final query = fs.collection('tv_channels').orderBy('order', descending: false);

      yield* query.snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) {
          // If Firestore collection is empty, keep default catalog
          return TvChannelModel.defaultChannels;
        }

        final channels = snapshot.docs.map((doc) {
          return TvChannelModel.fromMap(doc.data(), doc.id);
        }).toList();

        // Sort by order ascending
        channels.sort((a, b) => a.order.compareTo(b.order));

        // Background persist to local cache
        _persistChannels(channels);

        return channels;
      }).handleError((err) {
        debugPrint('[TvChannelsRepository] Firestore stream error: $err');
        return initial;
      });
    } catch (e) {
      debugPrint('[TvChannelsRepository] Failed to initialize Firestore listener: $e');
    }
  }

  /// One-off fetch of TV channels.
  Future<List<TvChannelModel>> fetchChannels() async {
    final fs = _firestore;
    if (fs == null) {
      return getCachedChannels();
    }

    try {
      final snap = await fs.collection('tv_channels').orderBy('order').get();
      if (snap.docs.isEmpty) {
        return TvChannelModel.defaultChannels;
      }
      final channels = snap.docs.map((doc) => TvChannelModel.fromMap(doc.data(), doc.id)).toList();
      channels.sort((a, b) => a.order.compareTo(b.order));
      await _persistChannels(channels);
      return channels;
    } catch (e) {
      debugPrint('[TvChannelsRepository] Fetch error: $e');
      return getCachedChannels();
    }
  }
}

/// Provider for [TvChannelsRepository].
final tvChannelsRepositoryProvider = Provider<TvChannelsRepository>((ref) {
  return TvChannelsRepository();
});

/// StreamProvider listening to real-time TV channels.
final tvChannelsStreamProvider = StreamProvider<List<TvChannelModel>>((ref) {
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


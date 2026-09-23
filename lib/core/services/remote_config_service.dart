import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ad_config_model.dart';
import '../network/dio_client.dart';

/// Data model representing remote app configuration from Firestore (`config/app_settings`).
class RemoteConfigModel {
  final String? apiBaseUrlOverride;
  final String latestAppVersion;
  final String updateDownloadUrl;
  final bool forceUpdate;
  final String minSupportedVersion;

  const RemoteConfigModel({
    this.apiBaseUrlOverride,
    this.latestAppVersion = '1.0.0',
    this.updateDownloadUrl = '',
    this.forceUpdate = false,
    this.minSupportedVersion = '1.0.0',
  });

  factory RemoteConfigModel.fromMap(Map<String, dynamic> map) {
    return RemoteConfigModel(
      apiBaseUrlOverride: map['api_base_url_override'] as String?,
      latestAppVersion: (map['latest_app_version'] as String?) ?? '1.0.0',
      updateDownloadUrl: (map['update_download_url'] as String?) ?? '',
      forceUpdate: (map['force_update'] as bool?) ?? false,
      minSupportedVersion: (map['min_supported_version'] as String?) ?? '1.0.0',
    );
  }
}

/// Service responsible for observing and streaming the consolidated remote configuration
/// from Firestore document `config/app_settings`.
///
/// ARCHITECTURAL RULES:
/// 1. `config/app_settings` is the SINGLE unified document in Firestore.
/// 2. Ad configuration lives inside the nested map field `ad_config`.
/// 3. The client app has strictly READ-ONLY access. No client-side write/seeding is permitted.
/// 4. If the document is missing, malformed, or offline, all ads fall back to `enabled: false` (ZERO ads).
/// 5. FAILS OPEN: If Firebase is not initialized or offline, returns empty/default models cleanly.
class RemoteConfigService {
  final FirebaseFirestore? _explicitFirestore;
  final DioClient dioClient;

  RemoteConfigService({
    FirebaseFirestore? firestore,
    required this.dioClient,
  }) : _explicitFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_explicitFirestore != null) return _explicitFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Stream of the single unified `config/app_settings` document snapshots.
  Stream<DocumentSnapshot<Map<String, dynamic>>> _getAppSettingsSnapshotStream() {
    try {
      final fs = _firestore;
      if (fs == null) {
        debugPrint('[RemoteConfigService] Firestore instance is null when requesting snapshot stream.');
        return const Stream.empty();
      }

      return fs
          .collection('config')
          .doc('app_settings')
          .snapshots();
    } catch (e) {
      debugPrint('[RemoteConfigService] Non-fatal: Firestore stream unavailable: $e');
      return const Stream.empty();
    }
  }

  /// Listens to Firestore document `config/app_settings` and extracts the nested `ad_config` map in real-time.
  /// If offline, missing, or errored, emits [AdConfig()] where ALL placements are disabled (`enabled: false`).
  Stream<AdConfig> listenToAdConfig() {
    try {
      return _getAppSettingsSnapshotStream().map((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          final adConfigMap = data['ad_config'] as Map<String, dynamic>?;
          if (adConfigMap != null && adConfigMap.isNotEmpty) {
            debugPrint('[RemoteConfigService] Real-time ad_config updated from config/app_settings.');
            return AdConfig.fromMap(adConfigMap);
          }
        }
        debugPrint('[RemoteConfigService] No ad_config in config/app_settings — defaulting to ads DISABLED.');
        return const AdConfig(); // Safe offline/missing fallback: all enabled: false
      }).handleError((error) {
        debugPrint('[RemoteConfigService] Error listening to app_settings ad_config: $error. Defaulting to ads DISABLED.');
        return const AdConfig(); // Safe fallback: all enabled: false
      });
    } catch (e) {
      debugPrint('[RemoteConfigService] Failed to initialize ad_config listener: $e');
      return Stream.value(const AdConfig());
    }
  }

  /// Listens to Firestore document `config/app_settings` for dynamic general remote updates.
  Stream<RemoteConfigModel> listenToRemoteConfig() {
    try {
      return _getAppSettingsSnapshotStream().map((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          debugPrint(
            '[RemoteConfigService] Stream Snapshot -> latest_app_version: "${data['latest_app_version']}", '
            'force_update: ${data['force_update']}, min_supported_version: "${data['min_supported_version']}"',
          );
          final config = RemoteConfigModel.fromMap(data);
          if (config.apiBaseUrlOverride != null && config.apiBaseUrlOverride!.isNotEmpty) {
            dioClient.updateBaseUrl(config.apiBaseUrlOverride!);
          }
          return config;
        }
        debugPrint('[RemoteConfigService] Stream snapshot does not exist or has no data.');
        return const RemoteConfigModel();
      }).handleError((err) {
        debugPrint('[RemoteConfigService] Error listening to remote config stream: $err');
        return const RemoteConfigModel();
      });
    } catch (e) {
      debugPrint('[RemoteConfigService] Failed to initialize remote config listener: $e');
      return Stream.value(const RemoteConfigModel());
    }
  }

  /// Fetches the latest remote configuration once directly from Firestore.
  /// Used during startup sequence to guarantee fresh values before splash navigation.
  Future<RemoteConfigModel> fetchInitialConfig() async {
    try {
      final fs = _firestore;
      if (fs == null) {
        debugPrint('[RemoteConfigService] fetchInitialConfig: Firestore not available, returning default model.');
        return const RemoteConfigModel();
      }

      final snapshot = await fs
          .collection('config')
          .doc('app_settings')
          .get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        debugPrint(
          '[RemoteConfigService] fetchInitialConfig -> latest_app_version: "${data['latest_app_version']}", '
          'force_update: ${data['force_update']}, min_supported_version: "${data['min_supported_version']}"',
        );
        final config = RemoteConfigModel.fromMap(data);
        if (config.apiBaseUrlOverride != null && config.apiBaseUrlOverride!.isNotEmpty) {
          dioClient.updateBaseUrl(config.apiBaseUrlOverride!);
        }
        return config;
      }
      debugPrint('[RemoteConfigService] fetchInitialConfig: doc does not exist.');
      return const RemoteConfigModel();
    } catch (e) {
      debugPrint('[RemoteConfigService] fetchInitialConfig error: $e');
      return const RemoteConfigModel();
    }
  }
}

/// Provider for [RemoteConfigService].
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return RemoteConfigService(dioClient: dioClient);
});

/// Real-time StreamProvider watching `config/app_settings` in Firestore and extracting `ad_config`.
/// Emits live updates whenever any nested ad placement is toggled or changed in Firestore Console.
final adConfigStreamProvider = StreamProvider<AdConfig>((ref) {
  final service = ref.watch(remoteConfigServiceProvider);
  return service.listenToAdConfig();
});

/// Current value accessor provider for [AdConfig].
/// Defaults to `const AdConfig()` (all ads disabled) when loading or offline.
final currentAdConfigProvider = Provider<AdConfig>((ref) {
  final asyncVal = ref.watch(adConfigStreamProvider);
  return asyncVal.value ?? const AdConfig();
});

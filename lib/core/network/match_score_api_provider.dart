import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/match_score_api.dart';
import '../services/remote_config_service.dart';

/// Singleton [MatchScoreApi] instance whose base URL tracks the dashboard
/// `api_base_url_override` Firestore field in real time.
///
/// The [remoteConfigServiceProvider] already calls [DioClient.updateBaseUrl]
/// for the legacy Dio client. This provider mirrors that behaviour for
/// [MatchScoreApi] so both clients stay in sync.
final matchScoreApiProvider = Provider<MatchScoreApi>((ref) {
  final apiClient = MatchScoreApi();

  // React to real-time remote config changes and forward the base-URL override.
  ref.listen<AsyncValue<RemoteConfigModel>>(
    remoteConfigStreamProvider,
    (_, next) {
      next.whenData((config) {
        if (config.apiBaseUrlOverride != null &&
            config.apiBaseUrlOverride!.isNotEmpty) {
          apiClient.setBaseUrl(config.apiBaseUrlOverride!);
        }
      });
    },
  );

  return apiClient;
});

/// StreamProvider mirroring [RemoteConfigService.listenToRemoteConfig].
final remoteConfigStreamProvider = StreamProvider<RemoteConfigModel>((ref) {
  final service = ref.watch(remoteConfigServiceProvider);
  return service.listenToRemoteConfig();
});

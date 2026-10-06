import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/version_helper.dart';
import 'remote_config_service.dart';

/// Enum representing the evaluation outcome of the app version check.
enum UpdateStatus {
  /// App is up to date or remote config is unavailable/fails open.
  none,

  /// Non-mandatory update available (current < latest && force_update == false).
  softPrompt,

  /// Mandatory update required (current < minSupported OR current < latest && force_update == true).
  hardBlock,
}

/// Comprehensive update information data model.
class AppUpdateInfo {
  final UpdateStatus status;
  final String currentVersion;
  final String latestVersion;
  final String minSupportedVersion;
  final String updateDownloadUrl;
  final bool forceUpdate;

  const AppUpdateInfo({
    this.status = UpdateStatus.none,
    this.currentVersion = '1.0.0',
    this.latestVersion = '1.0.0',
    this.minSupportedVersion = '1.0.0',
    this.updateDownloadUrl = '',
    this.forceUpdate = false,
  });

  bool get isHardBlocked => status == UpdateStatus.hardBlock;
  bool get isSoftPrompt => status == UpdateStatus.softPrompt;
}

/// Core service that evaluates app update requirements against real-time Firestore config.
class UpdateService {
  /// Evaluates the [UpdateStatus] using semantic version comparison rules:
  ///
  /// 1. If `currentVersion < minSupportedVersion` → [UpdateStatus.hardBlock]
  /// 2. Else if `currentVersion < latestVersion` AND `forceUpdate == true` → [UpdateStatus.hardBlock]
  /// 3. Else if `currentVersion < latestVersion` AND `forceUpdate == false` → [UpdateStatus.softPrompt]
  /// 4. Else (currentVersion >= latestVersion) → [UpdateStatus.none]
  ///
  /// Fails OPEN: If config values are empty or invalid, returns [UpdateStatus.none].
  static AppUpdateInfo evaluate({
    required String currentVersion,
    required RemoteConfigModel config,
  }) {
    final latest = config.latestAppVersion.trim();
    final minSupported = config.minSupportedVersion.trim();
    final isForce = config.forceUpdate;
    final downloadUrl = config.updateDownloadUrl.trim();

    final isBelowMin =
        minSupported.isNotEmpty &&
        VersionHelper.isLessThan(currentVersion, minSupported);
    final isBelowLatest =
        latest.isNotEmpty && VersionHelper.isLessThan(currentVersion, latest);

    debugPrint(
      '[UpdateService] Evaluating version comparison: current="$currentVersion", latest="$latest", '
      'minSupported="$minSupported", forceUpdate=$isForce | isBelowMin=$isBelowMin, isBelowLatest=$isBelowLatest',
    );

    // 1. Check Hard Block: Current version is below minimum supported version
    if (isBelowMin) {
      debugPrint(
        '[UpdateService] -> Result: HARD BLOCK (current < minSupported)',
      );
      return AppUpdateInfo(
        status: UpdateStatus.hardBlock,
        currentVersion: currentVersion,
        latestVersion: latest.isNotEmpty ? latest : currentVersion,
        minSupportedVersion: minSupported,
        updateDownloadUrl: downloadUrl,
        forceUpdate: isForce,
      );
    }

    // 2. Check Hard Block: Current version is below latest version AND force_update is explicitly true
    if (isBelowLatest && isForce) {
      debugPrint(
        '[UpdateService] -> Result: HARD BLOCK (current < latest with force_update=true)',
      );
      return AppUpdateInfo(
        status: UpdateStatus.hardBlock,
        currentVersion: currentVersion,
        latestVersion: latest,
        minSupportedVersion: minSupported,
        updateDownloadUrl: downloadUrl,
        forceUpdate: true,
      );
    }

    // 3. Check Soft Prompt: Current version is below latest version AND force_update is false
    if (isBelowLatest) {
      debugPrint('[UpdateService] -> Result: SOFT PROMPT (current < latest)');
      return AppUpdateInfo(
        status: UpdateStatus.softPrompt,
        currentVersion: currentVersion,
        latestVersion: latest,
        minSupportedVersion: minSupported,
        updateDownloadUrl: downloadUrl,
        forceUpdate: false,
      );
    }

    // 4. Up to date or fail open
    debugPrint('[UpdateService] -> Result: NONE (app up to date / default)');
    return AppUpdateInfo(
      status: UpdateStatus.none,
      currentVersion: currentVersion,
      latestVersion: latest.isNotEmpty ? latest : currentVersion,
      minSupportedVersion: minSupported,
      updateDownloadUrl: downloadUrl,
      forceUpdate: isForce,
    );
  }
}

/// Provider fetching the current running app version.
final currentAppVersionProvider = FutureProvider<String>((ref) async {
  return VersionHelper.getCurrentAppVersion();
});

/// StreamProvider listening to general app configuration updates from Firestore (`config/app_settings`).
final remoteConfigStreamProvider = StreamProvider<RemoteConfigModel>((ref) {
  final service = ref.watch(remoteConfigServiceProvider);
  return service.listenToRemoteConfig();
});

/// Reactive Provider combining current app version + real-time RemoteConfigModel into [AppUpdateInfo].
final appUpdateInfoProvider = Provider<AppUpdateInfo>((ref) {
  final versionAsync = ref.watch(currentAppVersionProvider);
  final currentVersion = versionAsync.value ?? '1.0.0';

  final configAsync = ref.watch(remoteConfigStreamProvider);
  final config = configAsync.value ?? const RemoteConfigModel();

  return UpdateService.evaluate(currentVersion: currentVersion, config: config);
});

/// Notifier tracking whether the user has dismissed the soft update prompt during the current app session.
/// In-memory only (resets on app restart).
class SoftPromptDismissedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() {
    state = true;
  }
}

final softPromptDismissedProvider =
    NotifierProvider<SoftPromptDismissedNotifier, bool>(() {
      return SoftPromptDismissedNotifier();
    });

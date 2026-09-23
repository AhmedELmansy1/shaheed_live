import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/core/services/remote_config_service.dart';
import 'package:shoot_live/core/services/update_service.dart';
import 'package:shoot_live/core/utils/version_helper.dart';

void main() {
  group('Cold Start Force Update Evaluation', () {
    test('Verifies that runtime version 1.0.0 vs Firestore 9.9.9 with force_update=true triggers HARD BLOCK', () {
      const currentVersion = '1.0.0';
      const remoteConfig = RemoteConfigModel(
        latestAppVersion: '9.9.9',
        forceUpdate: true,
        minSupportedVersion: '1.0.0',
        updateDownloadUrl: 'https://example.com/download',
      );

      final isBelow = VersionHelper.isLessThan(currentVersion, remoteConfig.latestAppVersion);
      expect(isBelow, isTrue);

      final updateInfo = UpdateService.evaluate(
        currentVersion: currentVersion,
        config: remoteConfig,
      );

      expect(updateInfo.status, UpdateStatus.hardBlock);
      expect(updateInfo.isHardBlocked, isTrue);
      expect(updateInfo.currentVersion, '1.0.0');
      expect(updateInfo.latestVersion, '9.9.9');
      expect(updateInfo.updateDownloadUrl, 'https://example.com/download');
    });
  });
}

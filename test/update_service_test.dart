import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/core/services/remote_config_service.dart';
import 'package:shoot_live/core/services/update_service.dart';

void main() {
  group('UpdateService Evaluation Scenario Tests', () {
    test('Scenario 1: Current version below min_supported_version triggers HARD BLOCK', () {
      final config = RemoteConfigModel(
        minSupportedVersion: '2.0.0',
        latestAppVersion: '2.1.0',
        forceUpdate: false, // Even with forceUpdate false, minSupported takes precedence
        updateDownloadUrl: 'https://example.com/download',
      );

      final result = UpdateService.evaluate(
        currentVersion: '1.9.9',
        config: config,
      );

      expect(result.status, UpdateStatus.hardBlock);
      expect(result.isHardBlocked, isTrue);
      expect(result.updateDownloadUrl, 'https://example.com/download');
    });

    test('Scenario 2: Current version below latest_app_version with force_update=true triggers HARD BLOCK', () {
      final config = RemoteConfigModel(
        minSupportedVersion: '1.0.0',
        latestAppVersion: '1.2.0',
        forceUpdate: true,
        updateDownloadUrl: 'https://example.com/download',
      );

      final result = UpdateService.evaluate(
        currentVersion: '1.1.0',
        config: config,
      );

      expect(result.status, UpdateStatus.hardBlock);
      expect(result.isHardBlocked, isTrue);
    });

    test('Scenario 3: Current version below latest_app_version with force_update=false triggers SOFT PROMPT', () {
      final config = RemoteConfigModel(
        minSupportedVersion: '1.0.0',
        latestAppVersion: '1.2.0',
        forceUpdate: false,
        updateDownloadUrl: 'https://example.com/download',
      );

      final result = UpdateService.evaluate(
        currentVersion: '1.1.0',
        config: config,
      );

      expect(result.status, UpdateStatus.softPrompt);
      expect(result.isSoftPrompt, isTrue);
      expect(result.isHardBlocked, isFalse);
    });

    test('Scenario 4: Current version equal to or greater than latest_app_version triggers NONE', () {
      final config = RemoteConfigModel(
        minSupportedVersion: '1.0.0',
        latestAppVersion: '1.2.0',
        forceUpdate: true,
      );

      // Equal to latest
      final resultEqual = UpdateService.evaluate(
        currentVersion: '1.2.0',
        config: config,
      );
      expect(resultEqual.status, UpdateStatus.none);
      expect(resultEqual.isHardBlocked, isFalse);
      expect(resultEqual.isSoftPrompt, isFalse);

      // Greater than latest (e.g. dev/beta build)
      final resultGreater = UpdateService.evaluate(
        currentVersion: '1.3.0',
        config: config,
      );
      expect(resultGreater.status, UpdateStatus.none);
    });

    test('Scenario 5: Fail open on empty or unreachable remote config', () {
      const config = RemoteConfigModel(); // Defaults to 1.0.0, force_update: false

      final result = UpdateService.evaluate(
        currentVersion: '1.0.0',
        config: config,
      );

      expect(result.status, UpdateStatus.none);
      expect(result.isHardBlocked, isFalse);
    });
  });
}

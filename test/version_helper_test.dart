import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/core/utils/version_helper.dart';

void main() {
  group('VersionHelper Semantic Version Comparison Tests', () {
    test('Identical version strings are equal', () {
      expect(VersionHelper.compare('1.0.0', '1.0.0'), 0);
      expect(VersionHelper.isEqual('1.0.0', '1.0.0'), isTrue);
    });

    test('Different segment counts with trailing zeros are equal', () {
      expect(VersionHelper.compare('1.2', '1.2.0'), 0);
      expect(VersionHelper.compare('1.2.0.0', '1.2'), 0);
      expect(VersionHelper.isEqual('1.2', '1.2.0'), isTrue);
    });

    test('Leading "v" and "V" prefixes are ignored', () {
      expect(VersionHelper.compare('v1.2.3', '1.2.3'), 0);
      expect(VersionHelper.compare('V2.0.0', '2.0.0'), 0);
      expect(VersionHelper.isEqual('v1.0.0', '1.0.0'), isTrue);
    });

    test('Build numbers and pre-release tags are stripped', () {
      expect(VersionHelper.compare('1.0.0+1', '1.0.0+2'), 0);
      expect(VersionHelper.compare('1.0.0-beta', '1.0.0'), 0);
      expect(VersionHelper.compare('1.0.0+10', '1.0.0'), 0);
    });

    test('Numeric comparisons handle double-digit segments (1.10.0 > 1.2.3)', () {
      expect(VersionHelper.compare('1.10.0', '1.2.3'), greaterThan(0));
      expect(VersionHelper.compare('1.2.3', '1.10.0'), lessThan(0));
      expect(VersionHelper.isLessThan('1.2.3', '1.10.0'), isTrue);
      expect(VersionHelper.isGreaterThan('1.10.0', '1.2.3'), isTrue);
    });

    test('Major version upgrades are correctly detected', () {
      expect(VersionHelper.compare('2.0.0', '1.99.99'), greaterThan(0));
      expect(VersionHelper.compare('1.0.0', '2.0.0'), lessThan(0));
      expect(VersionHelper.isLessThan('1.0.0', '2.0.0'), isTrue);
      expect(VersionHelper.isAtLeast('2.0.0', '2.0.0'), isTrue);
      expect(VersionHelper.isAtLeast('2.1.0', '2.0.0'), isTrue);
    });

    test('Minor and Patch comparisons', () {
      expect(VersionHelper.compare('1.2.1', '1.2.0'), greaterThan(0));
      expect(VersionHelper.compare('1.2.0', '1.2.1'), lessThan(0));
      expect(VersionHelper.compare('1.2.1', '1.2'), greaterThan(0));
      expect(VersionHelper.compare('1.2', '1.2.1'), lessThan(0));
      expect(VersionHelper.compare('1.0.10', '1.0.9'), greaterThan(0));
      expect(VersionHelper.compare('1.0.10', '1.0.2'), greaterThan(0));
    });

    test('Extra depth segments (4 parts)', () {
      expect(VersionHelper.compare('1.0.0.1', '1.0.0'), greaterThan(0));
      expect(VersionHelper.compare('1.0.0', '1.0.0.1'), lessThan(0));
    });
  });
}

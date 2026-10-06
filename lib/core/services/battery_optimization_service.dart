import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

final batteryOptimizationServiceProvider = Provider<BatteryOptimizationService>(
  (ref) {
    return BatteryOptimizationService();
  },
);

/// Service responsible for detecting aggressive OEM battery management (MIUI, EMUI, ColorOS)
/// and providing user guidance to whitelist the app for reliable background notifications.
class BatteryOptimizationService {
  static const String _keyNeverShow = 'never_show_battery_guidance';
  static const String _keyHasSeen = 'has_seen_battery_guidance';

  static const List<String> _aggressiveManufacturers = [
    'xiaomi',
    'redmi',
    'poco',
    'huawei',
    'honor',
    'oppo',
    'vivo',
    'oneplus',
    'realme',
    'transsion',
    'infinix',
    'tecno',
  ];

  /// Detects whether current device is from an OEM with known background task kill policies.
  Future<bool> isAggressiveOem() async {
    if (!Platform.isAndroid) return false;
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      final brand = androidInfo.brand.toLowerCase();

      return _aggressiveManufacturers.any(
        (oem) => manufacturer.contains(oem) || brand.contains(oem),
      );
    } catch (e) {
      debugPrint('[BatteryOptimization] Error detecting manufacturer: $e');
      return false;
    }
  }

  /// Returns device brand name for display (e.g. "XIAOMI").
  Future<String> getDeviceBrandName() async {
    if (!Platform.isAndroid) return '';
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final m = androidInfo.manufacturer;
      if (m.isNotEmpty) {
        return m[0].toUpperCase() + m.substring(1);
      }
      return androidInfo.brand.toUpperCase();
    } catch (_) {
      return '';
    }
  }

  /// Determines whether the guidance should be automatically presented on startup.
  Future<bool> shouldShowGuidance() async {
    if (!Platform.isAndroid) return false;
    final prefs = await SharedPreferences.getInstance();
    final neverShow = prefs.getBool(_keyNeverShow) ?? false;
    if (neverShow) return false;

    final hasSeen = prefs.getBool(_keyHasSeen) ?? false;
    if (hasSeen) return false;

    return await isAggressiveOem();
  }

  /// Marks that the user has seen the guidance dialog once.
  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeen, true);
  }

  /// Marks permanent dismissal so the automatic prompt never appears again.
  Future<void> markNeverShowAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNeverShow, true);
    await prefs.setBool(_keyHasSeen, true);
  }

  /// Requests the system to whitelist the app from battery optimizations.
  Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint(
        '[BatteryOptimization] Error requesting ignoreBatteryOptimizations: $e',
      );
      await openAppSettings();
    }
  }

  /// Opens the device App Settings screen where Autostart / Battery permissions live.
  Future<void> openAppSystemSettings() async {
    await openAppSettings();
  }
}

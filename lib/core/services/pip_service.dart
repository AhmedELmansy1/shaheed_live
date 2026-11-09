import 'package:flutter/services.dart';

/// Service managing Android Native Picture-in-Picture (PiP) lifecycle and controls.
class PipService {
  static const MethodChannel _channel = MethodChannel('com.livepulse.scores/pip');

  /// Checks if Picture-in-Picture is supported by the device OS and hardware.
  static Future<bool> isPipSupported() async {
    try {
      final supported = await _channel.invokeMethod<bool>('isPipSupported');
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Triggers PiP mode immediately (shrinks activity to a 16:9 floating window).
  static Future<bool> enterPip() async {
    try {
      final success = await _channel.invokeMethod<bool>('enterPip');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Configures whether backgrounding the app automatically transitions to PiP.
  static Future<void> setAutoPip(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setAutoPip', {'enabled': enabled});
    } catch (_) {}
  }

  /// Registers a callback for PiP mode changes (entered / exited floating window).
  static void setPipModeListener(void Function(bool isInPip) onPipModeChanged) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPipModeChanged') {
        final isInPip = call.arguments as bool? ?? false;
        onPipModeChanged(isInPip);
      }
    });
  }

  /// Clears listener
  static void removePipModeListener() {
    _channel.setMethodCallHandler(null);
  }
}

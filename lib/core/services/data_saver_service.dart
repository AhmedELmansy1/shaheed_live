import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for application-wide Data Saver mode.
final dataSaverModeProvider = NotifierProvider<DataSaverNotifier, bool>(() {
  return DataSaverNotifier();
});

class DataSaverNotifier extends Notifier<bool> {
  static const String _key = 'pref_data_saver_mode';

  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    state = value;
  }

  Future<void> toggle() async {
    await setEnabled(!state);
  }
}

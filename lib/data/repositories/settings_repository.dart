import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;
  static const storageKey = 'app_settings_v1';

  /// False on a fresh install (or after settings were reset).
  bool get hasStored => _prefs.containsKey(storageKey);

  AppSettings load() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return const AppSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return AppSettings.fromJson(decoded);
    } catch (_) {
      // Damaged data: use defaults.
    }
    return const AppSettings();
  }

  Future<void> save(AppSettings settings) =>
      _prefs.setString(storageKey, jsonEncode(settings.toJson()));

  Future<void> clear() => _prefs.remove(storageKey);
}

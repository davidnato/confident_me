import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores a list of small records as JSON under one SharedPreferences key.
/// Entries that cannot be read are skipped, so one damaged record never loses
/// the rest. Screens only talk to controllers, never to this class, so it can
/// be replaced by a database later.
class JsonListStore<T> {
  JsonListStore({
    required SharedPreferences prefs,
    required this.key,
    required this.fromJson,
    required this.toJson,
  }) : _prefs = prefs;

  final SharedPreferences _prefs;
  final String key;
  final T? Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;

  List<T> load() {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final result = <T>[];
        for (final entry in decoded) {
          if (entry is Map<String, dynamic>) {
            final item = fromJson(entry);
            if (item != null) result.add(item);
          }
        }
        return result;
      }
    } catch (_) {
      // Damaged data: start empty rather than crash.
    }
    return [];
  }

  Future<void> save(List<T> items) =>
      _prefs.setString(key, jsonEncode([for (final i in items) toJson(i)]));

  Future<void> clear() => _prefs.remove(key);
}

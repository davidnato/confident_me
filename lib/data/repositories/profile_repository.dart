import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_profile.dart';

/// Stores the (small) user profile as JSON in SharedPreferences.
/// A profile existing means onboarding has been completed or skipped.
class ProfileRepository {
  ProfileRepository(this._prefs);

  final SharedPreferences _prefs;
  static const storageKey = 'user_profile_v1';

  UserProfile? load() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return UserProfile.fromJson(decoded);
    } catch (_) {
      // Damaged data: fall through and treat as "no profile yet".
    }
    return null;
  }

  Future<void> save(UserProfile profile) =>
      _prefs.setString(storageKey, jsonEncode(profile.toJson()));

  Future<void> clear() => _prefs.remove(storageKey);
}

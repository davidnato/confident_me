import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/challenge_progress.dart';

/// Storage interface so the SharedPreferences version below can later be
/// replaced by SQLite without touching any screens.
abstract class ChallengeProgressRepository {
  List<ChallengeProgress> load();
  Future<void> save(List<ChallengeProgress> records);
  Future<void> clear();
}

class PrefsChallengeProgressRepository implements ChallengeProgressRepository {
  PrefsChallengeProgressRepository(this._prefs);

  final SharedPreferences _prefs;
  static const storageKey = 'challenge_progress_v1';

  @override
  List<ChallengeProgress> load() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return [
          for (final entry in decoded)
            if (entry is Map<String, dynamic>)
              if (ChallengeProgress.tryFromJson(entry) case final r?) r,
        ];
      }
    } catch (_) {
      // Damaged data: start with an empty history rather than crash.
    }
    return [];
  }

  @override
  Future<void> save(List<ChallengeProgress> records) => _prefs.setString(
        storageKey,
        jsonEncode([for (final r in records) r.toJson()]),
      );

  @override
  Future<void> clear() => _prefs.remove(storageKey);
}

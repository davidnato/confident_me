import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/clock.dart';
import '../affirmations/affirmation_providers.dart';
import '../challenges/progress_controller.dart';
import '../gamification/achievements_controller.dart';
import '../gamification/milestones_controller.dart';
import '../gamification/xp_ledger_controller.dart';
import '../journal/journal_controller.dart';
import '../onboarding/profile_controller.dart';
import '../practice/practice_sessions_controller.dart';
import '../settings_controller.dart';
import 'data_export.dart';
import 'reminder_logic.dart';

/// Export, reset and delete. The screens always ask for confirmation first;
/// nothing here asks again.
class DataManagementService {
  DataManagementService(this._ref);

  final Ref _ref;

  /// A complete copy of the person's data as pretty-printed JSON.
  String exportJson() {
    final prefs = _ref.read(affirmationPrefsProvider);
    final map = DataExport.build(
      now: _ref.read(clockProvider)(),
      profile: _ref.read(profileProvider),
      settings: _ref.read(settingsProvider),
      challengeProgress: _ref.read(challengeProgressProvider),
      xpHistory: _ref.read(xpLedgerProvider),
      achievements: _ref.read(earnedAchievementsProvider),
      milestones: _ref.read(milestonesProvider),
      practiceSessions: _ref.read(practiceSessionsProvider),
      journalEntries: _ref.read(journalProvider),
      customAffirmations: _ref.read(customAffirmationsProvider),
      favoriteAffirmationIds: prefs.favoriteIds,
      preferredAffirmationThemes: prefs.categories,
    );
    return DataExport.toPrettyJson(map);
  }

  /// Clears challenge attempts, XP, levels, achievements, milestones and
  /// practice history. Keeps the journal, your own affirmations, favorites,
  /// settings and profile.
  Future<void> resetProgress() async {
    await _ref.read(challengeProgressProvider.notifier).clearAll();
    await _ref.read(xpLedgerProvider.notifier).clearAll();
    await _ref.read(earnedAchievementsProvider.notifier).clearAll();
    await _ref.read(milestonesProvider.notifier).clearAll();
    await _ref.read(practiceSessionsProvider.notifier).clearAll();
  }

  /// Removes everything the app has stored, then returns to the welcome
  /// screen (clearing the profile last is what triggers that).
  Future<void> deleteAllData() async {
    await resetProgress();
    await _ref.read(journalProvider.notifier).clearAll();
    await _ref.read(customAffirmationsProvider.notifier).clearAll();
    await _ref.read(affirmationPrefsProvider.notifier).clearAll();
    await _ref.read(reminderDismissProvider.notifier).clearAll();
    await _ref.read(settingsProvider.notifier).reset();
    await _ref.read(profileProvider.notifier).clear();
  }
}

final dataManagementServiceProvider =
    Provider<DataManagementService>((ref) => DataManagementService(ref));

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/affirmation.dart';
import '../models/earned_achievement.dart';
import '../models/journal_entry.dart';
import '../models/milestone.dart';
import '../models/practice_session.dart';
import '../models/xp_transaction.dart';
import 'repositories/affirmation_repository.dart';
import 'repositories/challenge_repository.dart';
import 'repositories/json_list_store.dart';
import 'repositories/profile_repository.dart';
import 'repositories/progress_repository.dart';
import 'repositories/record_store.dart';
import 'repositories/scenario_repository.dart';
import 'repositories/settings_repository.dart';

/// Overridden in main.dart (and in tests) with a real SharedPreferences.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope.',
  ),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(sharedPreferencesProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final challengeRepositoryProvider =
    Provider<ChallengeRepository>((ref) => ChallengeRepository());

final affirmationRepositoryProvider =
    Provider<AffirmationRepository>((ref) => AffirmationRepository());

final progressRepositoryProvider = Provider<ChallengeProgressRepository>(
  (ref) => PrefsChallengeProgressRepository(ref.watch(sharedPreferencesProvider)),
);

final xpStoreProvider = Provider<JsonListStore<XpTransaction>>(
  (ref) => JsonListStore<XpTransaction>(
    prefs: ref.watch(sharedPreferencesProvider),
    key: 'xp_ledger_v1',
    fromJson: XpTransaction.tryFromJson,
    toJson: (t) => t.toJson(),
  ),
);

final achievementStoreProvider = Provider<JsonListStore<EarnedAchievement>>(
  (ref) => JsonListStore<EarnedAchievement>(
    prefs: ref.watch(sharedPreferencesProvider),
    key: 'earned_achievements_v1',
    fromJson: EarnedAchievement.tryFromJson,
    toJson: (a) => a.toJson(),
  ),
);

final milestoneStoreProvider = Provider<JsonListStore<Milestone>>(
  (ref) => JsonListStore<Milestone>(
    prefs: ref.watch(sharedPreferencesProvider),
    key: 'milestones_v1',
    fromJson: Milestone.tryFromJson,
    toJson: (m) => m.toJson(),
  ),
);

/// Hive in the real app, memory in tests. Must be overridden in ProviderScope.
final recordStoreFactoryProvider = Provider<RecordStoreFactory>(
  (ref) => throw UnimplementedError(
    'recordStoreFactoryProvider must be overridden in ProviderScope.',
  ),
);

final journalStoreProvider = Provider<RecordStore<JournalEntry>>(
  (ref) => ref.watch(recordStoreFactoryProvider).create<JournalEntry>(
        HiveRecordStoreFactory.journalBox,
        fromJson: JournalEntry.tryFromJson,
        toJson: (e) => e.toJson(),
        idOf: (e) => e.id,
      ),
);

final practiceStoreProvider = Provider<RecordStore<PracticeSession>>(
  (ref) => ref.watch(recordStoreFactoryProvider).create<PracticeSession>(
        HiveRecordStoreFactory.practiceBox,
        fromJson: PracticeSession.tryFromJson,
        toJson: (s) => s.toJson(),
        idOf: (s) => s.id,
      ),
);

final customAffirmationStoreProvider = Provider<RecordStore<Affirmation>>(
  (ref) => ref.watch(recordStoreFactoryProvider).create<Affirmation>(
        HiveRecordStoreFactory.customAffirmationBox,
        fromJson: Affirmation.tryFromJson,
        toJson: (a) => a.toJson(),
        idOf: (a) => a.id,
      ),
);

final scenarioRepositoryProvider =
    Provider<ScenarioRepository>((ref) => ScenarioRepository());

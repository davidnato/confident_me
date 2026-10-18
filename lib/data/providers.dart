import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/affirmation_repository.dart';
import 'repositories/challenge_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/progress_repository.dart';
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

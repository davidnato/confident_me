import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/xp_config.dart';
import '../../core/utils/clock.dart';
import '../../data/providers.dart';
import '../../models/challenge_progress.dart';
import '../../models/confidence_challenge.dart';
import '../onboarding/profile_controller.dart';
import '../settings_controller.dart';
import 'daily_planner.dart';
import 'progress_controller.dart';

/// Loads the bundled library and applies the configured XP values, so what is
/// shown before a challenge is always what is awarded after it.
final challengesProvider = FutureProvider<List<ConfidenceChallenge>>((ref) async {
  final config = ref.watch(xpConfigProvider);
  final all = await ref.watch(challengeRepositoryProvider).loadAll();
  return [
    for (final c in all) c.withXpReward(config.forDifficulty(c.difficulty)),
  ];
});

final challengeByIdProvider =
    Provider.family<ConfidenceChallenge?, String>((ref, id) {
  final all = ref.watch(challengesProvider).valueOrNull;
  if (all == null) return null;
  for (final c in all) {
    if (c.id == id) return c;
  }
  return null;
});

/// Today's suggestion. Recomputed whenever progress or the profile changes.
/// (It does not tick over at midnight on its own; it refreshes the next time
/// something changes or the app restarts.)
final todaysChallengeProvider = Provider<ConfidenceChallenge?>((ref) {
  final challenges = ref.watch(challengesProvider).valueOrNull;
  if (challenges == null) return null;
  final profile = ref.watch(profileProvider);
  return const DailyPlanner().pick(
    challenges: challenges,
    progress: ref.watch(challengeProgressProvider),
    goals: profile?.selectedGoals ?? const [],
    preferredDifficulty: ref.watch(settingsProvider).preferredDifficulty,
    now: ref.watch(clockProvider)(),
  );
});

/// The newest completion that happened today, if any.
final completedTodayProvider = Provider<ChallengeProgress?>((ref) {
  final now = ref.watch(clockProvider)();
  final records = ref.watch(challengeProgressProvider);
  for (var i = records.length - 1; i >= 0; i--) {
    final r = records[i];
    final at = r.completedAt;
    if (r.status == ChallengeStatus.completed &&
        at != null &&
        at.year == now.year &&
        at.month == now.month &&
        at.day == now.day) {
      return r;
    }
  }
  return null;
});


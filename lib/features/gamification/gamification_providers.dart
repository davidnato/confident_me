import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/xp_config.dart';
import '../../core/utils/clock.dart';
import '../../models/user_progress.dart';
import '../challenges/progress_controller.dart';
import '../../models/challenge_progress.dart';
import '../journal/journal_controller.dart';
import '../practice/practice_sessions_controller.dart';
import '../../models/challenge_category.dart';
import '../challenges/challenge_providers.dart';
import 'achievements_controller.dart';
import 'milestones_controller.dart';
import 'level_calculator.dart';
import 'streak_calculator.dart';
import 'xp_ledger_controller.dart';

final totalXpProvider = Provider<int>(
  (ref) => ref.watch(xpLedgerProvider).fold(0, (sum, t) => sum + t.amount),
);

final levelInfoProvider = Provider<LevelInfo>(
  (ref) => levelForXp(
    ref.watch(totalXpProvider),
    config: ref.watch(xpConfigProvider),
  ),
);

/// Days with any activity: a completed challenge or any XP earned.
final activityDatesProvider = Provider<List<DateTime>>((ref) {
  final dates = <DateTime>[
    for (final r in ref.watch(challengeProgressProvider).completedRecords)
      if (r.completedAt != null) r.completedAt!,
    for (final t in ref.watch(xpLedgerProvider)) t.createdAt,
    for (final p in ref.watch(practiceSessionsProvider)) p.completedAt,
    for (final j in ref.watch(journalProvider)) j.createdAt,
  ];
  return dates;
});

final streakProvider = Provider<StreakInfo>(
  (ref) => calculateStreaks(
    ref.watch(activityDatesProvider),
    ref.watch(clockProvider)(),
  ),
);

final userProgressProvider = Provider<UserProgress>((ref) {
  final level = ref.watch(levelInfoProvider);
  final streak = ref.watch(streakProvider);
  return UserProgress(
    totalXp: level.totalXp,
    level: level.level,
    completedChallenges: ref.watch(challengeProgressProvider).completedCount,
    longestStreak: streak.longest,
    currentStreak: streak.current,
    earnedAchievementIds: [
      for (final e in ref.watch(earnedAchievementsProvider)) e.achievementId,
    ],
  );
});

/// One entry per thing the person did (a completed challenge, a finished
/// practice, a journal entry, a completed milestone). Used by the weekly
/// calendar. Unlike [activityDatesProvider] it never counts one action twice.
final activityEventsProvider = Provider<List<DateTime>>((ref) => [
      for (final r in ref.watch(challengeProgressProvider).completedRecords)
        if (r.completedAt != null) r.completedAt!,
      for (final p in ref.watch(practiceSessionsProvider)) p.completedAt,
      for (final j in ref.watch(journalProvider))
        if (!j.isBlank) j.createdAt,
      for (final m in ref.watch(milestonesProvider))
        if (m.completedAt != null) m.completedAt!,
    ]);

/// Categories in which at least one challenge has been completed.
final exploredCategoriesProvider = Provider<Set<ChallengeCategory>>((ref) {
  final challenges = ref.watch(challengesProvider).valueOrNull ?? const [];
  final byId = {for (final c in challenges) c.id: c};
  return {
    for (final r in ref.watch(challengeProgressProvider).completedRecords)
      if (byId[r.challengeId] != null) byId[r.challengeId]!.category,
  };
});

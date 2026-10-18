import '../../core/utils/stable_hash.dart';
import '../../models/challenge_category.dart';
import '../../models/challenge_progress.dart';
import '../../models/confidence_challenge.dart';
import '../../models/difficulty.dart';

/// Chooses one manageable challenge for today using plain, deterministic rules.
/// This is NOT AI: the same inputs always give the same answer.
///
/// Rules, in order:
///  1. Leave out challenges that are postponed (until their date) or were
///     skipped in the last 3 days.
///  2. Prefer ones not completed yet. If everything is completed, allow repeats.
///  3. Score what is left:
///       +4 / +3 / +2 / +2 / 0  matching the preferred difficulty
///                              (same / one easier / two easier / one harder / two harder)
///       +2  category matches a chosen goal
///       +5  already started (finish what you began)
///       -4  longer than the time available (if a time is given)
///       -4  not easier than a challenge skipped recently (offer something gentler)
///       -1  same category as the most recently completed challenge (variety)
///  4. Ties are broken by a stable hash of today's date and the challenge id,
///     so the choice rotates day to day but does not flicker within a day.
class DailyPlanner {
  const DailyPlanner();

  static const skipCooldown = Duration(days: 3);

  ConfidenceChallenge? pick({
    required List<ConfidenceChallenge> challenges,
    required List<ChallengeProgress> progress,
    required Iterable<ChallengeCategory> goals,
    required Difficulty preferredDifficulty,
    required DateTime now,
    int? timeAvailableMinutes,
  }) {
    if (challenges.isEmpty) return null;

    final byId = {for (final c in challenges) c.id: c};
    final goalSet = goals.toSet();
    final completedIds = {
      for (final r in progress)
        if (r.status == ChallengeStatus.completed) r.challengeId,
    };

    // Difficulty of the most recent recent-skip, if any.
    Difficulty? skipCeiling;
    DateTime? newestSkip;
    for (final r in progress) {
      if (r.status != ChallengeStatus.skipped) continue;
      if (now.difference(r.updatedAt) >= skipCooldown) continue;
      final skipped = byId[r.challengeId];
      if (skipped == null) continue;
      if (newestSkip == null || r.updatedAt.isAfter(newestSkip)) {
        newestSkip = r.updatedAt;
        skipCeiling = skipped.difficulty;
      }
    }

    // Category of the most recently completed challenge.
    ChallengeCategory? lastCategory;
    DateTime? newestCompletion;
    for (final r in progress) {
      if (r.status != ChallengeStatus.completed) continue;
      final at = r.completedAt ?? r.updatedAt;
      final c = byId[r.challengeId];
      if (c == null) continue;
      if (newestCompletion == null || at.isAfter(newestCompletion)) {
        newestCompletion = at;
        lastCategory = c.category;
      }
    }

    bool eligible(ConfidenceChallenge c) {
      final latest = progress.latestFor(c.id);
      if (latest == null) return true;
      switch (latest.status) {
        case ChallengeStatus.postponed:
          final until = latest.postponedUntil;
          return until == null || !until.isAfter(now);
        case ChallengeStatus.skipped:
          return now.difference(latest.updatedAt) >= skipCooldown;
        case ChallengeStatus.inProgress:
        case ChallengeStatus.completed:
          return true;
      }
    }

    var pool = challenges.where(eligible).toList();
    final fresh = pool.where((c) => !completedIds.contains(c.id)).toList();
    if (fresh.isNotEmpty) pool = fresh;
    if (pool.isEmpty) pool = List.of(challenges);

    int score(ConfidenceChallenge c) {
      var s = _difficultyFit(c.difficulty, preferredDifficulty);
      if (goalSet.contains(c.category)) s += 2;
      if (progress.latestFor(c.id)?.status == ChallengeStatus.inProgress) s += 5;
      if (timeAvailableMinutes != null && c.estimatedMinutes > timeAvailableMinutes) {
        s -= 4;
      }
      if (skipCeiling != null && c.difficulty.index >= skipCeiling.index) s -= 4;
      if (lastCategory != null && c.category == lastCategory) s -= 1;
      return s;
    }

    final dayKey = '${now.year}-${now.month}-${now.day}';
    final scores = {for (final c in pool) c.id: score(c)};
    pool.sort((a, b) {
      final byScore = scores[b.id]!.compareTo(scores[a.id]!);
      if (byScore != 0) return byScore;
      final byHash =
          stableHash('$dayKey:${a.id}').compareTo(stableHash('$dayKey:${b.id}'));
      if (byHash != 0) return byHash;
      return a.id.compareTo(b.id);
    });
    return pool.first;
  }

  static int _difficultyFit(Difficulty challenge, Difficulty preferred) {
    switch (challenge.index - preferred.index) {
      case 0:
        return 4;
      case -1:
        return 3;
      case -2:
        return 2;
      case 1:
        return 2;
      default:
        return 0;
    }
  }
}

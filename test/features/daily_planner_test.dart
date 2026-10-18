import 'package:confident_me/features/challenges/daily_planner.dart';
import 'package:confident_me/models/challenge_category.dart';
import 'package:confident_me/models/challenge_progress.dart';
import 'package:confident_me/models/difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  const planner = DailyPlanner();
  final challenges = fixtureChallenges();
  final now = DateTime(2026, 10, 18, 9);

  test('returns null when there are no challenges', () {
    expect(
      planner.pick(
        challenges: const [],
        progress: const [],
        goals: const [],
        preferredDifficulty: Difficulty.easy,
        now: now,
      ),
      isNull,
    );
  });

  test('prefers a challenge in a chosen goal at the preferred difficulty', () {
    final pick = planner.pick(
      challenges: challenges,
      progress: const [],
      goals: const [ChallengeCategory.everydayInteractions],
      preferredDifficulty: Difficulty.easy,
      now: now,
    );
    expect(pick!.id, 'daily_easy');
  });

  test('starts gently: with no goals a beginner gets an easy challenge', () {
    final pick = planner.pick(
      challenges: challenges,
      progress: const [],
      goals: const [],
      preferredDifficulty: Difficulty.easy,
      now: now,
    );
    expect(pick!.difficulty, Difficulty.easy);
  });

  test('does not repeat a completed challenge while others remain', () {
    final pick = planner.pick(
      challenges: challenges,
      progress: [record('daily_easy', ChallengeStatus.completed, now)],
      goals: const [ChallengeCategory.everydayInteractions],
      preferredDifficulty: Difficulty.easy,
      now: now,
    );
    expect(pick!.id, isNot('daily_easy'));
    expect(pick.difficulty, Difficulty.easy);
  });

  test('postponed challenges return once their date has passed', () {
    final until = DateTime(2026, 10, 19);
    final progress = [
      record('daily_easy', ChallengeStatus.postponed, now, postponedUntil: until),
    ];
    const goals = [ChallengeCategory.everydayInteractions];

    final before = planner.pick(
      challenges: challenges,
      progress: progress,
      goals: goals,
      preferredDifficulty: Difficulty.easy,
      now: now,
    );
    expect(before!.id, isNot('daily_easy'));

    final after = planner.pick(
      challenges: challenges,
      progress: progress,
      goals: goals,
      preferredDifficulty: Difficulty.easy,
      now: until.add(const Duration(hours: 1)),
    );
    expect(after!.id, 'daily_easy');
  });

  test('after skipping a medium challenge, the next suggestion is easier', () {
    const goals = [ChallengeCategory.expressingOpinions];
    final before = planner.pick(
      challenges: challenges,
      progress: const [],
      goals: goals,
      preferredDifficulty: Difficulty.medium,
      now: now,
    );
    expect(before!.id, 'opin_medium');

    final after = planner.pick(
      challenges: challenges,
      progress: [
        record('opin_medium', ChallengeStatus.skipped,
            now.subtract(const Duration(hours: 1))),
      ],
      goals: goals,
      preferredDifficulty: Difficulty.medium,
      now: now,
    );
    expect(after!.difficulty, Difficulty.easy);
  });

  test('respects the time available when one is given', () {
    final pick = planner.pick(
      challenges: challenges,
      progress: const [],
      goals: const [],
      preferredDifficulty: Difficulty.easy,
      now: now,
      timeAvailableMinutes: 3,
    );
    expect(pick!.id, 'quick_easy');
  });

  test('is repeatable for the same day and inputs', () {
    String run() => planner
        .pick(
          challenges: challenges,
          progress: const [],
          goals: const [],
          preferredDifficulty: Difficulty.easy,
          now: now,
        )!
        .id;
    expect(run(), run());
  });

  test('still suggests something when everything is completed', () {
    final progress = [
      for (final c in challenges) record(c.id, ChallengeStatus.completed, now),
    ];
    final pick = planner.pick(
      challenges: challenges,
      progress: progress,
      goals: const [],
      preferredDifficulty: Difficulty.easy,
      now: now,
    );
    expect(pick, isNotNull);
  });
}

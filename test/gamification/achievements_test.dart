import 'package:confident_me/features/gamification/achievement_catalog.dart';
import 'package:confident_me/models/challenge_progress.dart';
import 'package:confident_me/models/challenge_category.dart';
import 'package:confident_me/models/difficulty.dart';
import 'package:confident_me/models/milestone.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  final now = DateTime(2026, 10, 18);

  test('catalog ids are unique and every achievement has text', () {
    final ids = achievementCatalog.map((d) => d.achievement.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final d in achievementCatalog) {
      expect(d.achievement.title, isNotEmpty);
      expect(d.achievement.description, isNotEmpty);
      expect(d.achievement.requirement, isNotEmpty);
    }
  });

  test('nothing is earned with no activity', () {
    expect(eligibleAchievementIds(const AchievementSnapshot()), isEmpty);
  });

  test('count-based achievements unlock at their thresholds', () {
    expect(
      eligibleAchievementIds(const AchievementSnapshot(completedChallenges: 1)),
      {'first_step'},
    );
    expect(
      eligibleAchievementIds(const AchievementSnapshot(completedChallenges: 5)),
      {'first_step', 'five_steps'},
    );
    expect(
      eligibleAchievementIds(const AchievementSnapshot(completedChallenges: 20)),
      containsAll(['first_step', 'five_steps', 'twenty_steps']),
    );
  });

  test('streak and milestone achievements', () {
    expect(
      eligibleAchievementIds(const AchievementSnapshot(longestStreak: 3)),
      {'showing_up'},
    );
    expect(
      eligibleAchievementIds(const AchievementSnapshot(longestStreak: 7)),
      {'showing_up', 'week_of_steps'},
    );
    expect(
      eligibleAchievementIds(const AchievementSnapshot(completedMilestones: 1)),
      {'milestone_reached'},
    );
  });

  test('snapshot is built from real records', () {
    final challenges = fixtureChallenges();
    final progress = [
      record('conv_easy', ChallengeStatus.completed, now),
      ChallengeProgress(
        id: 'r2',
        challengeId: 'opin_medium',
        status: ChallengeStatus.completed,
        updatedAt: now,
        completedAt: now,
        simplified: true,
        reflection: 'It went fine',
      ),
      record('speak_hard', ChallengeStatus.skipped, now),
    ];
    final snapshot = buildAchievementSnapshot(
      progress: progress,
      challenges: challenges,
      milestones: [
        Milestone(id: 'm', title: 't', createdAt: now, completedAt: now),
        Milestone(id: 'n', title: 'u', createdAt: now),
      ],
      longestStreak: 2,
    );
    expect(snapshot.completedChallenges, 2);
    expect(snapshot.categoriesExplored, 2);
    expect(snapshot.completedDifficulties, {Difficulty.easy, Difficulty.medium});
    expect(snapshot.completedWithSmallerStep, isTrue);
    expect(snapshot.completedWithReflection, isTrue);
    expect(snapshot.completedMilestones, 1);

    final ids = eligibleAchievementIds(snapshot);
    expect(ids, containsAll(['first_step', 'stretch', 'gentle_pace', 'thoughtful', 'milestone_reached']));
    expect(ids, isNot(contains('big_stretch')));
    expect(ChallengeCategory.values.length, 8);
  });
}

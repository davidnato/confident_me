import '../../models/achievement.dart';
import '../../models/challenge_category.dart';
import '../../models/challenge_progress.dart';
import '../../models/confidence_challenge.dart';
import '../../models/difficulty.dart';
import '../../models/milestone.dart';
import '../../models/practice_session.dart';

/// Facts about what the person has done. Achievements are decided from this
/// alone, so they are easy to test.
class AchievementSnapshot {
  const AchievementSnapshot({
    this.completedChallenges = 0,
    this.categoriesExplored = 0,
    this.completedDifficulties = const {},
    this.completedWithSmallerStep = false,
    this.completedWithReflection = false,
    this.longestStreak = 0,
    this.completedMilestones = 0,
    this.breathingSessions = 0,
    this.socialSessions = 0,
    this.journalEntries = 0,
  });

  final int completedChallenges;
  final int categoriesExplored;
  final Set<Difficulty> completedDifficulties;
  final bool completedWithSmallerStep;
  final bool completedWithReflection;
  final int longestStreak;
  final int completedMilestones;
  final int breathingSessions;
  final int socialSessions;
  final int journalEntries;

  int get practiceSessions => breathingSessions + socialSessions;
}

AchievementSnapshot buildAchievementSnapshot({
  required List<ChallengeProgress> progress,
  required List<ConfidenceChallenge> challenges,
  required List<Milestone> milestones,
  required int longestStreak,
  List<PracticeSession> practiceSessions = const [],
  int journalEntryCount = 0,
}) {
  final byId = {for (final c in challenges) c.id: c};
  final completed = progress.completedRecords;
  final categories = <ChallengeCategory>{};
  final difficulties = <Difficulty>{};
  for (final r in completed) {
    final c = byId[r.challengeId];
    if (c == null) continue;
    categories.add(c.category);
    difficulties.add(c.difficulty);
  }
  return AchievementSnapshot(
    completedChallenges: completed.length,
    categoriesExplored: categories.length,
    completedDifficulties: difficulties,
    completedWithSmallerStep: completed.any((r) => r.simplified),
    completedWithReflection: completed.any((r) => r.reflection.isNotEmpty),
    longestStreak: longestStreak,
    completedMilestones: milestones.where((m) => m.isCompleted).length,
    breathingSessions:
        practiceSessions.where((p) => p.kind == PracticeKind.breathing).length,
    socialSessions:
        practiceSessions.where((p) => p.kind == PracticeKind.social).length,
    journalEntries: journalEntryCount,
  );
}

class AchievementDefinition {
  const AchievementDefinition({required this.achievement, required this.isEarned});

  final Achievement achievement;
  final bool Function(AchievementSnapshot snapshot) isEarned;
}

/// Achievements celebrate effort and consistency. None compare you with other
/// people or imply your worth.
final List<AchievementDefinition> achievementCatalog = [
  AchievementDefinition(
    achievement: const Achievement(
      id: 'first_step',
      title: 'First small step',
      description: 'You completed your first challenge.',
      requirement: 'Complete 1 challenge',
      iconKey: 'flag',
    ),
    isEarned: (s) => s.completedChallenges >= 1,
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'five_steps',
      title: 'Five steps',
      description: 'Five challenges completed, one at a time.',
      requirement: 'Complete 5 challenges',
      iconKey: 'steps',
    ),
    isEarned: (s) => s.completedChallenges >= 5,
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'twenty_steps',
      title: 'Twenty steps',
      description: 'Twenty challenges completed. That is real practice.',
      requirement: 'Complete 20 challenges',
      iconKey: 'trail',
    ),
    isEarned: (s) => s.completedChallenges >= 20,
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'explorer',
      title: 'Explorer',
      description: 'You tried challenges in 3 different categories.',
      requirement: 'Complete challenges in 3 categories',
      iconKey: 'explore',
    ),
    isEarned: (s) => s.categoriesExplored >= 3,
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'well_rounded',
      title: 'Well-rounded',
      description: 'You have tried every category at least once.',
      requirement: 'Complete challenges in all 8 categories',
      iconKey: 'category',
    ),
    isEarned: (s) => s.categoriesExplored >= ChallengeCategory.values.length,
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'stretch',
      title: 'A little stretch',
      description: 'You completed an Intermediate challenge.',
      requirement: 'Complete an Intermediate challenge',
      iconKey: 'stretch',
    ),
    isEarned: (s) => s.completedDifficulties.contains(Difficulty.medium),
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'big_stretch',
      title: 'A big stretch',
      description: 'You completed an Advanced challenge.',
      requirement: 'Complete an Advanced challenge',
      iconKey: 'summit',
    ),
    isEarned: (s) => s.completedDifficulties.contains(Difficulty.hard),
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'gentle_pace',
      title: 'Gentle with myself',
      description: 'You chose a smaller step and completed it. That is wise pacing.',
      requirement: 'Complete a challenge using "Make this easier"',
      iconKey: 'heart',
    ),
    isEarned: (s) => s.completedWithSmallerStep,
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'thoughtful',
      title: 'Thoughtful',
      description: 'You wrote a reflection after a challenge.',
      requirement: 'Write a reflection after a challenge',
      iconKey: 'edit',
    ),
    isEarned: (s) => s.completedWithReflection,
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'showing_up',
      title: 'Showing up',
      description: 'Three days in a row with a step of some kind.',
      requirement: 'Be active 3 days in a row',
      iconKey: 'calendar',
    ),
    isEarned: (s) => s.longestStreak >= 3,
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'week_of_steps',
      title: 'A week of steps',
      description: 'Seven days in a row. Consistency is a strength.',
      requirement: 'Be active 7 days in a row',
      iconKey: 'week',
    ),
    isEarned: (s) => s.longestStreak >= 7,
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'milestone_reached',
      title: 'Milestone reached',
      description: 'You reached a personal milestone you set for yourself.',
      requirement: 'Complete a personal milestone',
      iconKey: 'star',
    ),
    isEarned: (s) => s.completedMilestones >= 1,
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'first_practice',
      title: 'First practice',
      description: 'You finished a guided practice session.',
      requirement: 'Finish a breathing or conversation practice',
      iconKey: 'practice',
    ),
    isEarned: (s) => s.practiceSessions >= 1,
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'calm_pause',
      title: 'A calm pause',
      description: 'You took a full breathing session for yourself.',
      requirement: 'Finish a breathing exercise',
      iconKey: 'breath',
    ),
    isEarned: (s) => s.breathingSessions >= 1,
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'rehearsed',
      title: 'Rehearsed it first',
      description: 'You practised a conversation before the real thing.',
      requirement: 'Finish a conversation practice',
      iconKey: 'chat',
    ),
    isEarned: (s) => s.socialSessions >= 1,
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'first_reflection',
      title: 'First reflection',
      description: 'You wrote your first journal entry.',
      requirement: 'Write a journal entry',
      iconKey: 'journal',
    ),
    isEarned: (s) => s.journalEntries >= 1,
  ),
  AchievementDefinition(
    achievement: const Achievement(
      id: 'regular_reflection',
      title: 'Reflecting regularly',
      description: 'Five journal entries. Reflection helps you notice progress.',
      requirement: 'Write 5 journal entries',
      iconKey: 'journal',
    ),
    isEarned: (s) => s.journalEntries >= 5,
  ),
];

Set<String> eligibleAchievementIds(AchievementSnapshot snapshot) => {
      for (final d in achievementCatalog)
        if (d.isEarned(snapshot)) d.achievement.id,
    };

Achievement? achievementById(String id) {
  for (final d in achievementCatalog) {
    if (d.achievement.id == id) return d.achievement;
  }
  return null;
}

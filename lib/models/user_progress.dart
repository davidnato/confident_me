/// A read-only summary calculated from the XP history, challenge attempts and
/// earned achievements. It is never stored, so it cannot drift out of sync.
class UserProgress {
  const UserProgress({
    required this.totalXp,
    required this.level,
    required this.completedChallenges,
    required this.longestStreak,
    required this.currentStreak,
    required this.earnedAchievementIds,
  });

  final int totalXp;
  final int level;
  final int completedChallenges;
  final int longestStreak;
  final int currentStreak;
  final List<String> earnedAchievementIds;
}

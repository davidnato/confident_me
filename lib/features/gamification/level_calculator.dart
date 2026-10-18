import '../../core/constants/xp_config.dart';

class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.totalXp,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
  });

  final int level;
  final int totalXp;

  /// XP earned since reaching [level].
  final int xpIntoLevel;

  /// Size of the current level (XP needed to reach the next one).
  final int xpForNextLevel;

  int get xpRemaining => xpForNextLevel - xpIntoLevel;
  double get progress => xpForNextLevel == 0 ? 0 : xpIntoLevel / xpForNextLevel;
}

/// The level is always calculated from lifetime XP, never stored, so it cannot
/// disagree with the XP history.
LevelInfo levelForXp(int totalXp, {XpConfig config = const XpConfig()}) {
  final total = totalXp < 0 ? 0 : totalXp;
  var remaining = total;
  var level = 1;
  while (remaining >= config.xpToReachNextLevel(level)) {
    remaining -= config.xpToReachNextLevel(level);
    level++;
  }
  return LevelInfo(
    level: level,
    totalXp: total,
    xpIntoLevel: remaining,
    xpForNextLevel: config.xpToReachNextLevel(level),
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/difficulty.dart';

/// Every XP number lives here so it can be tuned in one place.
///
/// Level formula: the XP needed to go from level L to level L+1 is
/// `levelBaseXp * L`. With the default of 100: level 1 -> 2 needs 100 XP,
/// level 2 -> 3 needs another 200, level 3 -> 4 another 300, and so on.
/// Total XP needed to reach level L is `levelBaseXp * L * (L - 1) / 2`.
class XpConfig {
  const XpConfig({
    this.easyChallenge = 10,
    this.mediumChallenge = 20,
    this.hardChallenge = 30,
    this.milestone = 50,
    this.practiceSession = 5,
    this.levelBaseXp = 100,
  }) : assert(levelBaseXp > 0, 'levelBaseXp must be positive');

  final int easyChallenge;
  final int mediumChallenge;
  final int hardChallenge;
  final int milestone;
  final int practiceSession;
  final int levelBaseXp;

  int forDifficulty(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return easyChallenge;
      case Difficulty.medium:
        return mediumChallenge;
      case Difficulty.hard:
        return hardChallenge;
    }
  }

  int xpToReachNextLevel(int level) => levelBaseXp * level;
}

final xpConfigProvider = Provider<XpConfig>((ref) => const XpConfig());

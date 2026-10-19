enum Difficulty {
  easy('easy', 'Beginner'),
  medium('medium', 'Intermediate'),
  hard('hard', 'Advanced');

  const Difficulty(this.id, this.label);

  final String id;
  final String label;

  /// Fallback XP when a challenge entry has no value. The XP actually shown and
  /// awarded comes from XpConfig (lib/core/constants/xp_config.dart).
  int get defaultXp => switch (this) {
        Difficulty.easy => 10,
        Difficulty.medium => 20,
        Difficulty.hard => 30,
      };

  static Difficulty fromId(String? id, {Difficulty fallback = Difficulty.easy}) {
    for (final d in values) {
      if (d.id == id) return d;
    }
    return fallback;
  }
}

import 'package:confident_me/core/constants/xp_config.dart';
import 'package:confident_me/features/gamification/level_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('0 XP is level 1 with 100 XP to go', () {
    final info = levelForXp(0);
    expect(info.level, 1);
    expect(info.xpIntoLevel, 0);
    expect(info.xpForNextLevel, 100);
    expect(info.progress, 0);
  });

  test('level boundaries follow 100 x level', () {
    expect(levelForXp(99).level, 1);
    expect(levelForXp(100).level, 2);
    expect(levelForXp(299).level, 2);
    expect(levelForXp(300).level, 3);
    expect(levelForXp(599).level, 3);
    expect(levelForXp(600).level, 4);
  });

  test('progress inside a level is reported correctly', () {
    final info = levelForXp(250);
    expect(info.level, 2);
    expect(info.xpIntoLevel, 150);
    expect(info.xpForNextLevel, 200);
    expect(info.xpRemaining, 50);
    expect(info.progress, 0.75);
  });

  test('total XP to reach level L is 50 x L x (L - 1)', () {
    for (var level = 1; level <= 30; level++) {
      final needed = 50 * level * (level - 1);
      expect(levelForXp(needed).level, level, reason: 'at exactly $needed XP');
      if (needed > 0) {
        expect(levelForXp(needed - 1).level, level - 1,
            reason: 'one XP short of level $level');
      }
    }
  });

  test('negative XP is treated as zero', () {
    final info = levelForXp(-50);
    expect(info.level, 1);
    expect(info.totalXp, 0);
  });

  test('the base XP is configurable', () {
    const config = XpConfig(levelBaseXp: 50);
    expect(levelForXp(49, config: config).level, 1);
    expect(levelForXp(50, config: config).level, 2);
    expect(levelForXp(150, config: config).level, 3);
  });
}

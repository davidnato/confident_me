import 'package:confident_me/features/gamification/streak_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 18, 15);
  DateTime day(int offset) => DateTime(2026, 10, 18 + offset, 9);

  test('no activity means no streak', () {
    final s = calculateStreaks(const [], today);
    expect(s.current, 0);
    expect(s.longest, 0);
  });

  test('counts consecutive days ending today', () {
    final s = calculateStreaks([day(-2), day(-1), day(0)], today);
    expect(s.current, 3);
    expect(s.longest, 3);
  });

  test('streak stays alive if you were active yesterday but not yet today', () {
    final s = calculateStreaks([day(-2), day(-1)], today);
    expect(s.current, 2);
  });

  test('a gap ends the current streak but keeps the longest', () {
    final s = calculateStreaks([day(-6), day(-5), day(-4), day(-3)], today);
    expect(s.current, 0);
    expect(s.longest, 4);
  });

  test('several entries on one day count once', () {
    final s = calculateStreaks(
      [DateTime(2026, 10, 18, 8), DateTime(2026, 10, 18, 20)],
      today,
    );
    expect(s.current, 1);
    expect(s.longest, 1);
  });

  test('works across month boundaries', () {
    final s = calculateStreaks(
      [DateTime(2026, 3, 30), DateTime(2026, 3, 31), DateTime(2026, 4, 1)],
      DateTime(2026, 4, 1, 12),
    );
    expect(s.current, 3);
  });

  test('longest streak can be earlier than the current one', () {
    final s = calculateStreaks(
      [day(-10), day(-9), day(-8), day(-7), day(0)],
      today,
    );
    expect(s.longest, 4);
    expect(s.current, 1);
  });
}

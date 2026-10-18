import 'package:confident_me/features/progress/weekly_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 18, 15);

  test('returns seven days, oldest first, ending today', () {
    final days = weeklyActivity(const [], now);
    expect(days.length, 7);
    expect(days.first.day, DateTime(2026, 10, 12));
    expect(days.last.day, DateTime(2026, 10, 18));
    expect(days.every((d) => !d.active && d.count == 0), isTrue);
  });

  test('counts several things on the same day', () {
    final days = weeklyActivity([
      DateTime(2026, 10, 18, 8),
      DateTime(2026, 10, 18, 20),
      DateTime(2026, 10, 16, 12),
    ], now);
    expect(days.last.count, 2);
    expect(days[4].day, DateTime(2026, 10, 16));
    expect(days[4].count, 1);
    expect(days[4].active, isTrue);
    expect(days[5].count, 0);
  });

  test('ignores things older than the window or in the future', () {
    final days = weeklyActivity([
      DateTime(2026, 10, 11, 12),
      DateTime(2026, 10, 19, 12),
    ], now);
    expect(days.fold<int>(0, (sum, d) => sum + d.count), 0);
  });

  test('works across a month boundary', () {
    final days = weeklyActivity(const [], DateTime(2026, 11, 2, 9));
    expect(days.first.day, DateTime(2026, 10, 27));
    expect(days.last.day, DateTime(2026, 11, 2));
  });

  test('the number of days can be changed', () {
    expect(weeklyActivity(const [], now, days: 3).length, 3);
  });
}

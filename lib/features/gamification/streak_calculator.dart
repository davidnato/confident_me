class StreakInfo {
  const StreakInfo({this.current = 0, this.longest = 0});

  final int current;
  final int longest;
}

int _dayNumber(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

/// Counts consecutive calendar days with any activity.
///
/// A streak is still "alive" if you were active yesterday but not yet today,
/// so it never looks broken in the middle of the day. Streaks are only a
/// gentle record: they never affect XP.
StreakInfo calculateStreaks(Iterable<DateTime> activity, DateTime now) {
  final days = {for (final d in activity) _dayNumber(d)}.toList()..sort();
  if (days.isEmpty) return const StreakInfo();

  var longest = 1;
  var run = 1;
  for (var i = 1; i < days.length; i++) {
    run = days[i] == days[i - 1] + 1 ? run + 1 : 1;
    if (run > longest) longest = run;
  }

  final set = days.toSet();
  final today = _dayNumber(now);
  int? start;
  if (set.contains(today)) {
    start = today;
  } else if (set.contains(today - 1)) {
    start = today - 1;
  }

  var current = 0;
  if (start != null) {
    var cursor = start;
    while (set.contains(cursor)) {
      current++;
      cursor--;
    }
  }
  return StreakInfo(current: current, longest: longest);
}

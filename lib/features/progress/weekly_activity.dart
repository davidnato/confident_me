class DayActivity {
  const DayActivity({required this.day, required this.count});

  /// Midnight of the day.
  final DateTime day;

  /// How many things were done that day (steps, practice, journal, milestones).
  final int count;

  bool get active => count > 0;
}

/// The last [days] days, oldest first, ending with today.
List<DayActivity> weeklyActivity(
  Iterable<DateTime> events,
  DateTime now, {
  int days = 7,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final counts = <DateTime, int>{};
  for (final e in events) {
    final d = DateTime(e.year, e.month, e.day);
    counts[d] = (counts[d] ?? 0) + 1;
  }
  return [
    for (var i = days - 1; i >= 0; i--)
      DayActivity(
        day: DateTime(today.year, today.month, today.day - i),
        count: counts[DateTime(today.year, today.month, today.day - i)] ?? 0,
      ),
  ];
}

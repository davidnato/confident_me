/// Builds a gentle, time-of-day greeting. Pure function so it is easy to test.
String buildGreeting(DateTime now, String name) {
  final hour = now.hour;
  final base = hour < 12
      ? 'Good morning'
      : hour < 18
          ? 'Good afternoon'
          : 'Good evening';
  final trimmed = name.trim();
  return trimmed.isEmpty ? base : '$base, $trimmed';
}

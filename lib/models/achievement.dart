class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.requirement,
    required this.iconKey,
  });

  final String id;
  final String title;

  /// Shown after it is earned.
  final String description;

  /// Shown while it is still locked.
  final String requirement;
  final String iconKey;
}

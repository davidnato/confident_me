class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.situation = '',
    this.feelings = '',
    this.anticipatedOutcome = '',
    this.actualOutcome = '',
    this.lessonsLearned = '',
    this.nextStep = '',
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// What happened.
  final String situation;

  /// What I felt.
  final String feelings;

  /// What I feared might happen.
  final String anticipatedOutcome;

  /// What actually happened.
  final String actualOutcome;

  /// What I learned.
  final String lessonsLearned;

  /// What I would like to try next time.
  final String nextStep;

  bool get isBlank =>
      [situation, feelings, anticipatedOutcome, actualOutcome, lessonsLearned, nextStep]
          .every((s) => s.trim().isEmpty);

  JournalEntry copyWith({
    DateTime? updatedAt,
    String? situation,
    String? feelings,
    String? anticipatedOutcome,
    String? actualOutcome,
    String? lessonsLearned,
    String? nextStep,
  }) =>
      JournalEntry(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        situation: situation ?? this.situation,
        feelings: feelings ?? this.feelings,
        anticipatedOutcome: anticipatedOutcome ?? this.anticipatedOutcome,
        actualOutcome: actualOutcome ?? this.actualOutcome,
        lessonsLearned: lessonsLearned ?? this.lessonsLearned,
        nextStep: nextStep ?? this.nextStep,
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'situation': situation,
        'feelings': feelings,
        'anticipatedOutcome': anticipatedOutcome,
        'actualOutcome': actualOutcome,
        'lessonsLearned': lessonsLearned,
        'nextStep': nextStep,
      };

  /// Missing text fields become empty; only a missing id makes it unreadable.
  static JournalEntry? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    DateTime? date(String key) =>
        json[key] is String ? DateTime.tryParse(json[key] as String) : null;
    final created = date('createdAt') ?? date('updatedAt') ?? DateTime.now();
    String text(String key) => json[key] is String ? json[key] as String : '';
    return JournalEntry(
      id: id,
      createdAt: created,
      updatedAt: date('updatedAt') ?? created,
      situation: text('situation'),
      feelings: text('feelings'),
      anticipatedOutcome: text('anticipatedOutcome'),
      actualOutcome: text('actualOutcome'),
      lessonsLearned: text('lessonsLearned'),
      nextStep: text('nextStep'),
    );
  }
}

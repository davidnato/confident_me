enum ChallengeStatus {
  inProgress('in_progress'),
  completed('completed'),
  skipped('skipped'),
  postponed('postponed');

  const ChallengeStatus(this.id);
  final String id;

  static ChallengeStatus? fromId(String? id) {
    for (final s in values) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// One attempt at one challenge. Repeating a challenge creates a new record,
/// so history is never overwritten.
class ChallengeProgress {
  const ChallengeProgress({
    required this.id,
    required this.challengeId,
    required this.status,
    required this.updatedAt,
    this.startedAt,
    this.completedAt,
    this.postponedUntil,
    this.reflection = '',
    this.xpAwarded = 0,
    this.simplified = false,
  });

  final String id;
  final String challengeId;
  final ChallengeStatus status;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? postponedUntil;
  final String reflection;

  /// XP this attempt earned (0 if none yet).
  final int xpAwarded;

  /// True if the person chose the smaller "Make this easier" version.
  final bool simplified;

  ChallengeProgress copyWith({
    ChallengeStatus? status,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? postponedUntil,
    bool clearPostponedUntil = false,
    String? reflection,
    bool? simplified,
  }) =>
      ChallengeProgress(
        id: id,
        challengeId: challengeId,
        status: status ?? this.status,
        updatedAt: updatedAt ?? this.updatedAt,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        postponedUntil:
            clearPostponedUntil ? null : (postponedUntil ?? this.postponedUntil),
        reflection: reflection ?? this.reflection,
        xpAwarded: xpAwarded,
        simplified: simplified ?? this.simplified,
      );

  ChallengeProgress withXpAwarded(int xp) => ChallengeProgress(
        id: id,
        challengeId: challengeId,
        status: status,
        updatedAt: updatedAt,
        startedAt: startedAt,
        completedAt: completedAt,
        postponedUntil: postponedUntil,
        reflection: reflection,
        xpAwarded: xp,
        simplified: simplified,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'challengeId': challengeId,
        'status': status.id,
        'updatedAt': updatedAt.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'postponedUntil': postponedUntil?.toIso8601String(),
        'reflection': reflection,
        'xpAwarded': xpAwarded,
        'simplified': simplified,
      };

  static ChallengeProgress? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final challengeId = json['challengeId'];
    final status =
        ChallengeStatus.fromId(json['status'] is String ? json['status'] as String : null);
    if (id is! String || id.isEmpty) return null;
    if (challengeId is! String || challengeId.isEmpty) return null;
    if (status == null) return null;

    DateTime? date(String key) {
      final raw = json[key];
      return raw is String ? DateTime.tryParse(raw) : null;
    }

    final started = date('startedAt');
    final completed = date('completedAt');
    return ChallengeProgress(
      id: id,
      challengeId: challengeId,
      status: status,
      startedAt: started,
      completedAt: completed,
      postponedUntil: date('postponedUntil'),
      updatedAt: date('updatedAt') ??
          completed ??
          started ??
          DateTime.fromMillisecondsSinceEpoch(0),
      reflection: json['reflection'] is String ? json['reflection'] as String : '',
      xpAwarded: json['xpAwarded'] is int ? json['xpAwarded'] as int : 0,
      simplified: json['simplified'] == true,
    );
  }
}

extension ChallengeProgressQueries on List<ChallengeProgress> {
  /// Records are kept in creation order, so the last match is the newest.
  ChallengeProgress? latestFor(String challengeId) {
    for (var i = length - 1; i >= 0; i--) {
      if (this[i].challengeId == challengeId) return this[i];
    }
    return null;
  }

  List<ChallengeProgress> get completedRecords =>
      where((r) => r.status == ChallengeStatus.completed).toList();

  int get completedCount => completedRecords.length;
}

enum PracticeKind {
  breathing('breathing'),
  social('social');

  const PracticeKind(this.id);
  final String id;

  static PracticeKind? fromId(String? id) {
    for (final k in values) {
      if (k.id == id) return k;
    }
    return null;
  }
}

/// A completed guided practice (a finished breathing session or a finished
/// scenario rehearsal). What you typed while rehearsing is never saved.
class PracticeSession {
  const PracticeSession({
    required this.id,
    required this.kind,
    required this.completedAt,
    this.refId = '',
    this.durationSeconds = 0,
    this.xpAwarded = 0,
  });

  final String id;
  final PracticeKind kind;
  final DateTime completedAt;

  /// Scenario id for social practice; empty for breathing.
  final String refId;
  final int durationSeconds;
  final int xpAwarded;

  PracticeSession withXp(int xp) => PracticeSession(
        id: id,
        kind: kind,
        completedAt: completedAt,
        refId: refId,
        durationSeconds: durationSeconds,
        xpAwarded: xp,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.id,
        'completedAt': completedAt.toIso8601String(),
        'refId': refId,
        'durationSeconds': durationSeconds,
        'xpAwarded': xpAwarded,
      };

  static PracticeSession? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final kind =
        PracticeKind.fromId(json['kind'] is String ? json['kind'] as String : null);
    final at = json['completedAt'] is String
        ? DateTime.tryParse(json['completedAt'] as String)
        : null;
    if (id is! String || id.isEmpty || kind == null || at == null) return null;
    return PracticeSession(
      id: id,
      kind: kind,
      completedAt: at,
      refId: json['refId'] is String ? json['refId'] as String : '',
      durationSeconds:
          json['durationSeconds'] is int ? json['durationSeconds'] as int : 0,
      xpAwarded: json['xpAwarded'] is int ? json['xpAwarded'] as int : 0,
    );
  }
}

/// A personal milestone written by the user, e.g. "Spoke up in a meeting".
class Milestone {
  const Milestone({
    required this.id,
    required this.title,
    required this.createdAt,
    this.completedAt,
    this.xpAwarded = 0,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int xpAwarded;

  bool get isCompleted => completedAt != null;

  Milestone copyWith({DateTime? completedAt, int? xpAwarded}) => Milestone(
        id: id,
        title: title,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
        xpAwarded: xpAwarded ?? this.xpAwarded,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'xpAwarded': xpAwarded,
      };

  static Milestone? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final created =
        json['createdAt'] is String ? DateTime.tryParse(json['createdAt'] as String) : null;
    if (id is! String || id.isEmpty || title is! String || title.isEmpty) {
      return null;
    }
    if (created == null) return null;
    return Milestone(
      id: id,
      title: title,
      createdAt: created,
      completedAt: json['completedAt'] is String
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      xpAwarded: json['xpAwarded'] is int ? json['xpAwarded'] as int : 0,
    );
  }
}

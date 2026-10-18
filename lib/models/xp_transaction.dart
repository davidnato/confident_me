enum XpReason {
  challenge('challenge'),
  milestone('milestone'),
  practice('practice');

  const XpReason(this.id);
  final String id;

  static XpReason? fromId(String? id) {
    for (final r in values) {
      if (r.id == id) return r;
    }
    return null;
  }
}

/// One line in the XP history. Lines are only ever added, never edited or
/// removed, so earned XP can never go down.
class XpTransaction {
  const XpTransaction({
    required this.id,
    required this.amount,
    required this.reason,
    required this.sourceKey,
    required this.createdAt,
    this.description = '',
  });

  final String id;
  final int amount;
  final XpReason reason;

  /// Identifies what earned the XP, e.g. `challenge:<attempt id>`. Only one
  /// transaction can exist per source key, which is what prevents duplicates.
  final String sourceKey;
  final DateTime createdAt;
  final String description;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'reason': reason.id,
        'sourceKey': sourceKey,
        'createdAt': createdAt.toIso8601String(),
        'description': description,
      };

  static XpTransaction? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final amount = json['amount'];
    final key = json['sourceKey'];
    final reason =
        XpReason.fromId(json['reason'] is String ? json['reason'] as String : null);
    final created =
        json['createdAt'] is String ? DateTime.tryParse(json['createdAt'] as String) : null;
    if (id is! String || id.isEmpty) return null;
    if (amount is! int || amount <= 0) return null;
    if (key is! String || key.isEmpty) return null;
    if (reason == null || created == null) return null;
    return XpTransaction(
      id: id,
      amount: amount,
      reason: reason,
      sourceKey: key,
      createdAt: created,
      description: json['description'] is String ? json['description'] as String : '',
    );
  }
}

class EarnedAchievement {
  const EarnedAchievement({required this.achievementId, required this.earnedAt});

  final String achievementId;
  final DateTime earnedAt;

  Map<String, dynamic> toJson() => {
        'achievementId': achievementId,
        'earnedAt': earnedAt.toIso8601String(),
      };

  static EarnedAchievement? tryFromJson(Map<String, dynamic> json) {
    final id = json['achievementId'];
    final at =
        json['earnedAt'] is String ? DateTime.tryParse(json['earnedAt'] as String) : null;
    if (id is! String || id.isEmpty || at == null) return null;
    return EarnedAchievement(achievementId: id, earnedAt: at);
  }
}

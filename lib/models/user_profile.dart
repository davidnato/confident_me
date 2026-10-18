import 'package:uuid/uuid.dart';

import 'challenge_category.dart';
import 'difficulty.dart';

/// Everything here is optional to the person using the app. A guest profile is
/// just a profile with blank answers.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.createdAt,
    this.displayName = '',
    this.selectedGoals = const [],
    this.improvementFocus,
    this.socialDifficulty = 3,
    this.smallGoal = '',
    this.preferredDifficulty = Difficulty.easy,
  });

  /// A profile with no answers, used for "Continue as guest" and "Skip setup".
  factory UserProfile.guest({String? id, DateTime? now}) => UserProfile(
        id: id ?? const Uuid().v4(),
        createdAt: now ?? DateTime.now(),
      );

  static const currentSchemaVersion = 1;

  final String id;
  final DateTime createdAt;
  final String displayName;
  final List<ChallengeCategory> selectedGoals;
  final String? improvementFocus;

  /// 1 = mostly comfortable ... 5 = very challenging. Used only to choose a
  /// gentle starting difficulty, never shown as a "score".
  final int socialDifficulty;
  final String smallGoal;
  final Difficulty preferredDifficulty;

  Map<String, dynamic> toJson() => {
        'schemaVersion': currentSchemaVersion,
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'displayName': displayName,
        'selectedGoals': selectedGoals.map((c) => c.id).toList(),
        'improvementFocus': improvementFocus,
        'socialDifficulty': socialDifficulty,
        'smallGoal': smallGoal,
        'preferredDifficulty': preferredDifficulty.id,
      };

  /// Tolerant of missing, extra, or wrongly-typed fields so an old or damaged
  /// save never crashes the app.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final goals = <ChallengeCategory>[];
    final rawGoals = json['selectedGoals'];
    if (rawGoals is List) {
      for (final raw in rawGoals) {
        final category = ChallengeCategory.fromId(raw is String ? raw : null);
        if (category != null && !goals.contains(category)) goals.add(category);
      }
    }

    final rawId = json['id'];
    final rawCreated = json['createdAt'];
    final rawLevel = json['socialDifficulty'];

    return UserProfile(
      id: rawId is String && rawId.isNotEmpty ? rawId : const Uuid().v4(),
      createdAt: (rawCreated is String ? DateTime.tryParse(rawCreated) : null) ??
          DateTime.now(),
      displayName: json['displayName'] is String
          ? json['displayName'] as String
          : '',
      selectedGoals: goals,
      improvementFocus: json['improvementFocus'] is String
          ? json['improvementFocus'] as String
          : null,
      socialDifficulty:
          rawLevel is int ? rawLevel.clamp(1, 5).toInt() : 3,
      smallGoal: json['smallGoal'] is String ? json['smallGoal'] as String : '',
      preferredDifficulty: Difficulty.fromId(
        json['preferredDifficulty'] is String
            ? json['preferredDifficulty'] as String
            : null,
      ),
    );
  }
}

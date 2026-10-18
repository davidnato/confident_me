import 'challenge_category.dart';
import 'difficulty.dart';

class ConfidenceChallenge {
  const ConfidenceChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.instructions,
    required this.reflectionPrompt,
    required this.xpReward,
    this.preparation = '',
    this.easierStep = '',
  });

  /// Stable id. Titles may be reworded later; ids must never change, because
  /// saved progress refers to them.
  final String id;
  final String title;
  final String description;
  final ChallengeCategory category;
  final Difficulty difficulty;
  final int estimatedMinutes;
  final String preparation;
  final List<String> instructions;
  final String reflectionPrompt;
  final int xpReward;

  /// A smaller version of the same step, shown by "Make this easier".
  final String easierStep;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.id,
        'difficulty': difficulty.id,
        'estimatedMinutes': estimatedMinutes,
        'preparation': preparation,
        'instructions': instructions,
        'reflectionPrompt': reflectionPrompt,
        'xpReward': xpReward,
        'easierStep': easierStep,
      };

  /// Returns null when the entry is unusable (missing id, title, or a known
  /// category) so one bad entry never breaks the whole library.
  static ConfidenceChallenge? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final category =
        ChallengeCategory.fromId(json['category'] is String ? json['category'] as String : null);
    if (id is! String || id.isEmpty || title is! String || title.isEmpty) {
      return null;
    }
    if (category == null) return null;

    final difficulty = Difficulty.fromId(
      json['difficulty'] is String ? json['difficulty'] as String : null,
    );
    final minutes = json['estimatedMinutes'];
    final xp = json['xpReward'];
    final steps = json['instructions'];

    String text(String key) => json[key] is String ? json[key] as String : '';

    return ConfidenceChallenge(
      id: id,
      title: title,
      description: text('description'),
      category: category,
      difficulty: difficulty,
      estimatedMinutes: minutes is int && minutes > 0 ? minutes : 5,
      preparation: text('preparation'),
      instructions: steps is List
          ? [for (final s in steps) if (s is String && s.isNotEmpty) s]
          : const [],
      reflectionPrompt: text('reflectionPrompt'),
      xpReward: xp is int && xp >= 0 ? xp : difficulty.defaultXp,
      easierStep: text('easierStep'),
    );
  }
}

import 'package:confident_me/models/challenge_category.dart';
import 'package:confident_me/models/difficulty.dart';
import 'package:confident_me/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips through JSON', () {
    final profile = UserProfile(
      id: 'abc',
      createdAt: DateTime.utc(2026, 1, 2, 3),
      displayName: 'Alex',
      selectedGoals: const [
        ChallengeCategory.publicSpeaking,
        ChallengeCategory.assertiveness,
      ],
      improvementFocus: 'Starting conversations',
      socialDifficulty: 4,
      smallGoal: 'Say hello',
      preferredDifficulty: Difficulty.medium,
    );

    final copy = UserProfile.fromJson(profile.toJson());

    expect(copy.id, 'abc');
    expect(copy.createdAt, profile.createdAt);
    expect(copy.displayName, 'Alex');
    expect(copy.selectedGoals, profile.selectedGoals);
    expect(copy.improvementFocus, 'Starting conversations');
    expect(copy.socialDifficulty, 4);
    expect(copy.smallGoal, 'Say hello');
    expect(copy.preferredDifficulty, Difficulty.medium);
  });

  test('survives missing and invalid fields', () {
    final profile = UserProfile.fromJson({
      'selectedGoals': ['public_speaking', 'not_a_real_category', 42],
      'socialDifficulty': 99,
      'preferredDifficulty': 'nonsense',
    });

    expect(profile.id, isNotEmpty);
    expect(profile.displayName, '');
    expect(profile.selectedGoals, [ChallengeCategory.publicSpeaking]);
    expect(profile.socialDifficulty, 5);
    expect(profile.preferredDifficulty, Difficulty.easy);
  });
}

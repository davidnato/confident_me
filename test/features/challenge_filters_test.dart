import 'package:confident_me/features/challenges/challenge_filters.dart';
import 'package:confident_me/models/challenge_category.dart';
import 'package:confident_me/models/difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  final all = fixtureChallenges();

  test('no filters returns everything', () {
    expect(filterChallenges(all).length, all.length);
  });

  test('filters by category', () {
    final result =
        filterChallenges(all, category: ChallengeCategory.publicSpeaking);
    expect(result.map((c) => c.id), ['speak_hard']);
  });

  test('filters by difficulty', () {
    final result = filterChallenges(all, difficulty: Difficulty.medium);
    expect(result.map((c) => c.id), ['opin_medium', 'assert_medium']);
  });

  test('combines category and difficulty', () {
    final result = filterChallenges(
      all,
      category: ChallengeCategory.assertiveness,
      difficulty: Difficulty.medium,
    );
    expect(result.map((c) => c.id), ['assert_medium']);
  });

  test('returns an empty list when nothing matches', () {
    final result = filterChallenges(
      all,
      category: ChallengeCategory.publicSpeaking,
      difficulty: Difficulty.easy,
    );
    expect(result, isEmpty);
  });
}

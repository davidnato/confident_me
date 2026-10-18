import 'package:confident_me/models/challenge_progress.dart';
import 'package:confident_me/models/confidence_challenge.dart';
import 'package:confident_me/models/difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('challenge parsing rejects entries without id, title or category', () {
    expect(ConfidenceChallenge.tryFromJson({'title': 'x', 'category': 'assertiveness'}), isNull);
    expect(ConfidenceChallenge.tryFromJson({'id': 'a', 'category': 'assertiveness'}), isNull);
    expect(ConfidenceChallenge.tryFromJson({'id': 'a', 'title': 'x', 'category': 'nope'}), isNull);
  });

  test('challenge parsing fills safe defaults', () {
    final c = ConfidenceChallenge.tryFromJson({
      'id': 'a',
      'title': 'T',
      'category': 'assertiveness',
      'difficulty': 'hard',
      'instructions': ['one', 5, ''],
    })!;
    expect(c.estimatedMinutes, 5);
    expect(c.xpReward, Difficulty.hard.defaultXp);
    expect(c.instructions, ['one']);
  });

  test('progress records round-trip and reject bad status', () {
    final r = ChallengeProgress(
      id: 'p1',
      challengeId: 'c1',
      status: ChallengeStatus.postponed,
      updatedAt: DateTime.utc(2026, 1, 1),
      postponedUntil: DateTime.utc(2026, 1, 2),
      simplified: true,
      reflection: 'hi',
    );
    final copy = ChallengeProgress.tryFromJson(r.toJson())!;
    expect(copy.status, ChallengeStatus.postponed);
    expect(copy.postponedUntil, DateTime.utc(2026, 1, 2));
    expect(copy.simplified, isTrue);
    expect(copy.reflection, 'hi');

    expect(
      ChallengeProgress.tryFromJson({'id': 'p', 'challengeId': 'c', 'status': 'weird'}),
      isNull,
    );
  });
}

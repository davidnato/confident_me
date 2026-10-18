import 'dart:convert';
import 'dart:io';

import 'package:confident_me/data/repositories/affirmation_repository.dart';
import 'package:confident_me/data/repositories/challenge_repository.dart';
import 'package:confident_me/models/challenge_category.dart';
import 'package:confident_me/models/difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final raw = File('assets/data/challenges.json').readAsStringSync();
  final challenges = ChallengeRepository.parseChallenges(raw);

  test('every entry in challenges.json is valid and ids are unique', () {
    final rawCount = (jsonDecode(raw) as Map)['challenges'].length as int;
    expect(challenges.length, rawCount);
    expect(challenges.map((c) => c.id).toSet().length, challenges.length);
  });

  test('every category and difficulty is covered', () {
    for (final category in ChallengeCategory.values) {
      expect(challenges.where((c) => c.category == category).length,
          greaterThanOrEqualTo(3),
          reason: category.id);
    }
    for (final difficulty in Difficulty.values) {
      expect(challenges.where((c) => c.difficulty == difficulty).length,
          greaterThanOrEqualTo(3),
          reason: difficulty.id);
    }
  });

  test('every challenge has the content the screens need', () {
    for (final c in challenges) {
      expect(c.description, isNotEmpty, reason: c.id);
      expect(c.instructions.length, greaterThanOrEqualTo(3), reason: c.id);
      expect(c.reflectionPrompt, isNotEmpty, reason: c.id);
      expect(c.easierStep, isNotEmpty, reason: c.id);
      expect(c.xpReward, greaterThan(0), reason: c.id);
      expect(c.estimatedMinutes, greaterThan(0), reason: c.id);
    }
  });

  test('affirmations.json parses and is not empty', () {
    final list = AffirmationRepository.parseAffirmations(
      File('assets/data/affirmations.json').readAsStringSync(),
    );
    expect(list.length, greaterThanOrEqualTo(6));
    expect(list.map((a) => a.id).toSet().length, list.length);
  });
}

import '../../models/challenge_category.dart';
import '../../models/confidence_challenge.dart';
import '../../models/difficulty.dart';

/// `null` means "all".
List<ConfidenceChallenge> filterChallenges(
  List<ConfidenceChallenge> all, {
  ChallengeCategory? category,
  Difficulty? difficulty,
}) =>
    all
        .where((c) =>
            (category == null || c.category == category) &&
            (difficulty == null || c.difficulty == difficulty))
        .toList();

import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/confidence_challenge.dart';

/// Loads the bundled challenge library from assets/data/challenges.json.
class ChallengeRepository {
  ChallengeRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/data/challenges.json';
  final AssetBundle _bundle;

  Future<List<ConfidenceChallenge>> loadAll() async =>
      parseChallenges(await _bundle.loadString(assetPath));

  /// Skips invalid entries and duplicate ids instead of failing the whole file.
  static List<ConfidenceChallenge> parseChallenges(String raw) {
    final decoded = jsonDecode(raw);
    final list = decoded is Map<String, dynamic> ? decoded['challenges'] : decoded;
    if (list is! List) {
      throw const FormatException('challenges.json has no challenge list.');
    }
    final seen = <String>{};
    final result = <ConfidenceChallenge>[];
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) continue;
      final challenge = ConfidenceChallenge.tryFromJson(entry);
      if (challenge != null && seen.add(challenge.id)) result.add(challenge);
    }
    return result;
  }
}

import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/social_scenario.dart';

class ScenarioRepository {
  ScenarioRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/data/scenarios.json';
  final AssetBundle _bundle;

  Future<List<SocialScenario>> loadAll() async =>
      parseScenarios(await _bundle.loadString(assetPath));

  static List<SocialScenario> parseScenarios(String raw) {
    final decoded = jsonDecode(raw);
    final list = decoded is Map<String, dynamic> ? decoded['scenarios'] : decoded;
    if (list is! List) {
      throw const FormatException('scenarios.json has no scenario list.');
    }
    final seen = <String>{};
    final result = <SocialScenario>[];
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) continue;
      final s = SocialScenario.tryFromJson(entry);
      if (s != null && seen.add(s.id)) result.add(s);
    }
    return result;
  }
}

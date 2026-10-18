import 'dart:convert';
import 'dart:io';

import 'package:confident_me/data/repositories/affirmation_repository.dart';
import 'package:confident_me/data/repositories/scenario_repository.dart';
import 'package:confident_me/features/affirmations/affirmation_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final scenarios = ScenarioRepository.parseScenarios(
    File('assets/data/scenarios.json').readAsStringSync(),
  );

  test('all nine required scenarios are present with unique ids', () {
    final ids = scenarios.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(
      ids,
      containsAll([
        'intro_yourself',
        'join_conversation',
        'keep_going',
        'follow_up',
        'compliments',
        'disagree',
        'boundaries',
        'meeting',
        'awkward_pause',
      ]),
    );
    final rawCount = (jsonDecode(File('assets/data/scenarios.json').readAsStringSync())
        as Map)['scenarios'].length as int;
    expect(scenarios.length, rawCount, reason: 'no entry was rejected as invalid');
  });

  test('each scenario has everything the practice screens need', () {
    for (final s in scenarios) {
      expect(s.description, isNotEmpty, reason: s.id);
      expect(s.setting, isNotEmpty, reason: s.id);
      expect(s.conversationStarters.length, greaterThanOrEqualTo(3), reason: s.id);
      expect(s.followUpQuestions.length, greaterThanOrEqualTo(3), reason: s.id);
      expect(s.listeningTips.length, greaterThanOrEqualTo(2), reason: s.id);
      expect(s.prompts.length, greaterThanOrEqualTo(3), reason: s.id);
      for (final p in s.prompts) {
        expect(p.heard, isNotEmpty, reason: s.id);
        expect(p.suggestions.length, greaterThanOrEqualTo(2), reason: s.id);
      }
    }
  });

  test('every bundled affirmation uses a known category', () {
    final list = AffirmationRepository.parseAffirmations(
      File('assets/data/affirmations.json').readAsStringSync(),
    );
    expect(list.length, greaterThanOrEqualTo(20));
    for (final a in list) {
      expect(affirmationCategories.containsKey(a.category), isTrue,
          reason: '${a.id} has category "${a.category}"');
      expect(a.category, isNot(customCategoryId));
    }
  });

  test('scenario parsing skips unusable entries', () {
    final parsed = ScenarioRepository.parseScenarios(
      '{"scenarios":[{"id":"ok","title":"T"},{"title":"no id"},5]}',
    );
    expect(parsed.map((s) => s.id), ['ok']);
  });
}

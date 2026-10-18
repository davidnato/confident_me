import 'package:confident_me/core/utils/clock.dart';
import 'package:confident_me/data/providers.dart';
import 'package:confident_me/data/repositories/record_store.dart';
import 'package:confident_me/features/challenges/challenge_providers.dart';
import 'package:confident_me/features/gamification/achievements_controller.dart';
import 'package:confident_me/features/gamification/gamification_providers.dart';
import 'package:confident_me/features/gamification/gamification_service.dart';
import 'package:confident_me/features/journal/journal_controller.dart';
import 'package:confident_me/features/practice/practice_sessions_controller.dart';
import 'package:confident_me/models/journal_entry.dart';
import 'package:confident_me/models/practice_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fixtures.dart';

void main() {
  final now = DateTime(2026, 10, 18, 9);

  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      recordStoreFactoryProvider.overrideWithValue(InMemoryRecordStoreFactory()),
      clockProvider.overrideWithValue(() => now),
      challengesProvider.overrideWith((ref) => Future.value(fixtureChallenges())),
    ]);
    addTearDown(c.dispose);
    await c.read(challengesProvider.future);
    return c;
  }

  Set<String> earned(ProviderContainer c) =>
      c.read(earnedAchievementsProvider).map((e) => e.achievementId).toSet();

  test('a social practice session awards 5 XP and is recorded', () async {
    final c = await makeContainer();
    final r = await c.read(gamificationServiceProvider).completePracticeSession(
          kind: PracticeKind.social,
          durationSeconds: 0,
          description: 'Practice: Introducing yourself',
          refId: 'intro',
          sessionId: 's1',
        );
    expect(r.recorded, isTrue);
    expect(r.xpAwarded, 5);
    expect(c.read(totalXpProvider), 5);
    final s = c.read(practiceSessionsProvider).single;
    expect(s.refId, 'intro');
    expect(s.kind, PracticeKind.social);
    expect(s.xpAwarded, 5);
    expect(r.newAchievements.map((a) => a.id), containsAll(['first_practice', 'rehearsed']));
  });

  test('the same session id never earns XP twice', () async {
    final c = await makeContainer();
    final service = c.read(gamificationServiceProvider);
    Future<RewardResult> go() => service.completePracticeSession(
          kind: PracticeKind.breathing,
          durationSeconds: 120,
          description: 'Breathing exercise',
          sessionId: 'same',
        );
    final first = await go();
    final second = await go();
    expect(first.recorded, isTrue);
    expect(second.recorded, isFalse);
    expect(second.xpAwarded, 0);
    expect(c.read(totalXpProvider), 5);
    expect(c.read(practiceSessionsProvider).length, 1);
  });

  test('different sessions each earn their own XP', () async {
    final c = await makeContainer();
    final service = c.read(gamificationServiceProvider);
    for (final id in ['a', 'b', 'c']) {
      await service.completePracticeSession(
        kind: PracticeKind.breathing,
        durationSeconds: 60,
        description: 'Breathing exercise',
        sessionId: id,
      );
    }
    expect(c.read(totalXpProvider), 15);
  });

  test('breathing earns "A calm pause" but not "Rehearsed it first"', () async {
    final c = await makeContainer();
    await c.read(gamificationServiceProvider).completePracticeSession(
          kind: PracticeKind.breathing,
          durationSeconds: 60,
          description: 'Breathing exercise',
          sessionId: 'b1',
        );
    expect(earned(c), containsAll(['first_practice', 'calm_pause']));
    expect(earned(c), isNot(contains('rehearsed')));
  });

  test('journal achievements need real entries, and journaling earns no XP', () async {
    final c = await makeContainer();
    final j = c.read(journalProvider.notifier);
    final service = c.read(gamificationServiceProvider);

    await j.save(JournalEntry(id: 'blank', createdAt: now, updatedAt: now));
    expect((await service.afterJournalSaved()).recorded, isFalse);
    expect(earned(c), isEmpty);

    await j.save(JournalEntry(id: 'one', createdAt: now, updatedAt: now, situation: 'Hi'));
    final r = await service.afterJournalSaved();
    expect(r.recorded, isTrue);
    expect(r.newAchievements.map((a) => a.id), ['first_reflection']);
    expect(c.read(totalXpProvider), 0);

    expect((await service.afterJournalSaved()).recorded, isFalse);

    for (final id in ['two', 'three', 'four', 'five']) {
      await j.save(JournalEntry(id: id, createdAt: now, updatedAt: now, situation: id));
    }
    expect((await service.afterJournalSaved()).newAchievements.map((a) => a.id),
        ['regular_reflection']);
  });

  test('practice and journal days count toward the streak', () async {
    final c = await makeContainer();
    await c.read(journalProvider.notifier).save(
          JournalEntry(id: 'a', createdAt: now, updatedAt: now, situation: 'x'),
        );
    expect(c.read(streakProvider).current, 1);
  });
}

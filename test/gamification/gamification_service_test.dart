import 'package:confident_me/core/utils/clock.dart';
import 'package:confident_me/data/providers.dart';
import 'package:confident_me/data/repositories/record_store.dart';
import 'package:confident_me/features/challenges/challenge_providers.dart';
import 'package:confident_me/features/challenges/progress_controller.dart';
import 'package:confident_me/features/gamification/gamification_providers.dart';
import 'package:confident_me/features/gamification/gamification_service.dart';
import 'package:confident_me/features/gamification/achievements_controller.dart';
import 'package:confident_me/features/gamification/milestones_controller.dart';
import 'package:confident_me/features/gamification/xp_ledger_controller.dart';
import 'package:confident_me/features/settings_controller.dart';
import 'package:confident_me/models/challenge_progress.dart';
import 'package:confident_me/models/xp_transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fixtures.dart';

void main() {
  final easy = fixtureChallenges().firstWhere((c) => c.id == 'conv_easy'); // 10 XP
  final medium = fixtureChallenges().firstWhere((c) => c.id == 'opin_medium'); // 20 XP
  var fakeNow = DateTime(2026, 10, 18, 9);
  var records = InMemoryRecordStoreFactory();

  Future<ProviderContainer> makeContainer() async {
    fakeNow = DateTime(2026, 10, 18, 9);
    records = InMemoryRecordStoreFactory();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      recordStoreFactoryProvider.overrideWithValue(records),
      clockProvider.overrideWithValue(() => fakeNow),
      challengesProvider.overrideWith((ref) => Future.value(fixtureChallenges())),
    ]);
    addTearDown(container.dispose);
    await container.read(challengesProvider.future);
    return container;
  }

  test('completing a challenge awards its XP exactly once', () async {
    final c = await makeContainer();
    final service = c.read(gamificationServiceProvider);

    final first = await service.completeChallenge(easy);
    expect(first.recorded, isTrue);
    expect(first.xpAwarded, 10);
    expect(c.read(totalXpProvider), 10);
    expect(c.read(xpLedgerProvider).length, 1);
    expect(c.read(challengeProgressProvider).single.xpAwarded, 10);

    final second = await service.completeChallenge(easy);
    expect(second.recorded, isFalse);
    expect(second.xpAwarded, 0);
    expect(c.read(totalXpProvider), 10);
    expect(c.read(xpLedgerProvider).length, 1);
  });

  test('doing a challenge again earns XP for that new attempt only', () async {
    final c = await makeContainer();
    final service = c.read(gamificationServiceProvider);
    await service.completeChallenge(easy);
    await c.read(challengeProgressProvider.notifier).start(easy.id);
    final again = await service.completeChallenge(easy);
    expect(again.xpAwarded, 10);
    expect(c.read(totalXpProvider), 20);
    expect(c.read(xpLedgerProvider).length, 2);
  });

  test('the ledger refuses a second entry with the same source', () async {
    final c = await makeContainer();
    final ledger = c.read(xpLedgerProvider.notifier);
    XpTransaction tx(String id) => XpTransaction(
          id: id,
          amount: 10,
          reason: XpReason.practice,
          sourceKey: 'practice:one',
          createdAt: fakeNow,
        );
    expect(await ledger.award(tx('a')), isTrue);
    expect(await ledger.award(tx('b')), isFalse);
    expect(c.read(totalXpProvider), 10);
  });

  test('two awards made at the same moment still count once', () async {
    final c = await makeContainer();
    final ledger = c.read(xpLedgerProvider.notifier);
    XpTransaction tx(String id) => XpTransaction(
          id: id,
          amount: 10,
          reason: XpReason.practice,
          sourceKey: 'practice:same',
          createdAt: fakeNow,
        );
    final results = await Future.wait([ledger.award(tx('a')), ledger.award(tx('b'))]);
    expect(results.where((r) => r).length, 1);
    expect(c.read(totalXpProvider), 10);
  });

  test('skipping or postponing never removes XP', () async {
    final c = await makeContainer();
    await c.read(gamificationServiceProvider).completeChallenge(easy);
    final progress = c.read(challengeProgressProvider.notifier);
    await progress.skip(medium.id);
    await progress.postpone(medium.id);
    await progress.skip(easy.id);
    expect(c.read(totalXpProvider), 10);
  });

  test('XP is still recorded when the gamification display is off', () async {
    final c = await makeContainer();
    await c.read(settingsProvider.notifier).setGamificationEnabled(false);
    await c.read(gamificationServiceProvider).completeChallenge(easy);
    expect(c.read(totalXpProvider), 10);
  });

  test('the first completion earns the first achievement, and only once', () async {
    final c = await makeContainer();
    final service = c.read(gamificationServiceProvider);
    final first = await service.completeChallenge(easy);
    expect(first.newAchievements.map((a) => a.id), contains('first_step'));

    final second = await service.completeChallenge(medium);
    expect(second.newAchievements.map((a) => a.id), isNot(contains('first_step')));
    expect(second.newAchievements.map((a) => a.id), contains('stretch'));

    final earned = c.read(earnedAchievementsProvider).map((e) => e.achievementId);
    expect(earned.toSet().length, earned.length);
  });

  test('milestones award 50 XP once and can trigger a level-up', () async {
    final c = await makeContainer();
    final milestones = c.read(milestonesProvider.notifier);
    final service = c.read(gamificationServiceProvider);

    expect(await milestones.add('   '), isNull);
    final a = (await milestones.add('Shared an opinion'))!;
    final b = (await milestones.add('Asked for help'))!;

    final r1 = await service.completeMilestone(a.id);
    expect(r1.recorded, isTrue);
    expect(r1.xpAwarded, 50);
    expect(r1.leveledUp, isFalse);

    final repeat = await service.completeMilestone(a.id);
    expect(repeat.recorded, isFalse);
    expect(c.read(totalXpProvider), 50);

    final r2 = await service.completeMilestone(b.id);
    expect(c.read(totalXpProvider), 100);
    expect(r2.leveledUp, isTrue);
    expect(r2.levelAfter.level, 2);
  });

  test('deleting a milestone keeps the XP it earned', () async {
    final c = await makeContainer();
    final m = (await c.read(milestonesProvider.notifier).add('Spoke up'))!;
    await c.read(gamificationServiceProvider).completeMilestone(m.id);
    await c.read(milestonesProvider.notifier).remove(m.id);
    expect(c.read(milestonesProvider), isEmpty);
    expect(c.read(totalXpProvider), 50);
  });

  test('reconcile gives XP to older completions once, however often it runs',
      () async {
    final c = await makeContainer();
    // Completed without the service, like a challenge finished before XP existed.
    await c.read(challengeProgressProvider.notifier).complete(easy.id);
    expect(c.read(totalXpProvider), 0);

    final service = c.read(gamificationServiceProvider);
    await service.reconcile();
    await service.reconcile();

    expect(c.read(totalXpProvider), 10);
    expect(c.read(xpLedgerProvider).length, 1);
    expect(c.read(challengeProgressProvider).single.xpAwarded, 10);
    expect(c.read(earnedAchievementsProvider).map((e) => e.achievementId),
        contains('first_step'));
  });

  test('XP, achievements and milestones persist across a restart', () async {
    final c = await makeContainer();
    await c.read(gamificationServiceProvider).completeChallenge(medium);
    await c.read(milestonesProvider.notifier).add('Kept');

    final prefs = await SharedPreferences.getInstance();
    final restarted = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        recordStoreFactoryProvider.overrideWithValue(records),
      ],
    );
    addTearDown(restarted.dispose);
    expect(restarted.read(totalXpProvider), 20);
    expect(restarted.read(earnedAchievementsProvider), isNotEmpty);
    expect(restarted.read(milestonesProvider).single.title, 'Kept');
    expect(restarted.read(challengeProgressProvider).completedCount, 1);
  });

  test('user progress summarises the stored data', () async {
    final c = await makeContainer();
    await c.read(gamificationServiceProvider).completeChallenge(easy);
    final p = c.read(userProgressProvider);
    expect(p.totalXp, 10);
    expect(p.level, 1);
    expect(p.completedChallenges, 1);
    expect(p.currentStreak, 1);
    expect(p.longestStreak, 1);
    expect(p.earnedAchievementIds, contains('first_step'));
    expect(c.read(challengeProgressProvider).first.status, ChallengeStatus.completed);
  });
}

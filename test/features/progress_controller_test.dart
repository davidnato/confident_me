import 'package:confident_me/core/utils/clock.dart';
import 'package:confident_me/data/providers.dart';
import 'package:confident_me/features/challenges/progress_controller.dart';
import 'package:confident_me/models/challenge_progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  var fakeNow = DateTime(2026, 10, 18, 9, 30);

  Future<ProviderContainer> makeContainer() async {
    fakeNow = DateTime(2026, 10, 18, 9, 30);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => fakeNow),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('start creates one in-progress attempt and is idempotent', () async {
    final container = await makeContainer();
    final c = container.read(challengeProgressProvider.notifier);
    await c.start('x');
    await c.start('x');
    final records = container.read(challengeProgressProvider);
    expect(records.length, 1);
    expect(records.single.status, ChallengeStatus.inProgress);
  });

  test('complete records a reflection and cannot be recorded twice', () async {
    final container = await makeContainer();
    final c = container.read(challengeProgressProvider.notifier);
    await c.start('x');
    expect(await c.complete('x', reflection: '  went fine  '), isTrue);
    final firstCompletion =
        container.read(challengeProgressProvider).single.completedAt;

    fakeNow = fakeNow.add(const Duration(hours: 1));
    expect(await c.complete('x', reflection: 'again'), isFalse);

    final records = container.read(challengeProgressProvider);
    expect(records.length, 1);
    expect(records.single.status, ChallengeStatus.completed);
    expect(records.single.reflection, 'went fine');
    expect(records.single.completedAt, firstCompletion);
    expect(records.completedCount, 1);
  });

  test('complete works directly without a separate start', () async {
    final container = await makeContainer();
    final c = container.read(challengeProgressProvider.notifier);
    expect(await c.complete('x'), isTrue);
    expect(container.read(challengeProgressProvider).completedCount, 1);
  });

  test('doing a challenge again adds a new attempt', () async {
    final container = await makeContainer();
    final c = container.read(challengeProgressProvider.notifier);
    await c.complete('x');
    await c.start('x');
    expect(await c.complete('x'), isTrue);
    expect(container.read(challengeProgressProvider).completedCount, 2);
  });

  test('skip sets the status and a later start begins a new attempt', () async {
    final container = await makeContainer();
    final c = container.read(challengeProgressProvider.notifier);
    await c.skip('x');
    expect(container.read(challengeProgressProvider).latestFor('x')!.status,
        ChallengeStatus.skipped);
    await c.start('x');
    final records = container.read(challengeProgressProvider);
    expect(records.length, 2);
    expect(records.latestFor('x')!.status, ChallengeStatus.inProgress);
  });

  test('postpone sets tomorrow at midnight', () async {
    final container = await makeContainer();
    await container.read(challengeProgressProvider.notifier).postpone('x');
    final record = container.read(challengeProgressProvider).single;
    expect(record.status, ChallengeStatus.postponed);
    expect(record.postponedUntil, DateTime(2026, 10, 19));
  });

  test('setSimplified marks the current attempt', () async {
    final container = await makeContainer();
    await container.read(challengeProgressProvider.notifier).setSimplified('x');
    final record = container.read(challengeProgressProvider).single;
    expect(record.status, ChallengeStatus.inProgress);
    expect(record.simplified, isTrue);
  });

  test('progress survives an app restart', () async {
    final container = await makeContainer();
    await container
        .read(challengeProgressProvider.notifier)
        .complete('x', reflection: 'kept');

    final prefs = await SharedPreferences.getInstance();
    final restarted = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restarted.dispose);
    final records = restarted.read(challengeProgressProvider);
    expect(records.length, 1);
    expect(records.single.status, ChallengeStatus.completed);
    expect(records.single.reflection, 'kept');
  });
}

import 'package:confident_me/core/utils/clock.dart';
import 'package:confident_me/data/providers.dart';
import 'package:confident_me/data/repositories/record_store.dart';
import 'package:confident_me/features/breathing/breathing_controller.dart';
import 'package:confident_me/features/breathing/breathing_timeline.dart';
import 'package:confident_me/features/challenges/challenge_providers.dart';
import 'package:confident_me/features/gamification/gamification_providers.dart';
import 'package:confident_me/features/practice/practice_sessions_controller.dart';
import 'package:confident_me/models/practice_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fixtures.dart';

void main() {
  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      recordStoreFactoryProvider.overrideWithValue(InMemoryRecordStoreFactory()),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 18, 9)),
      challengesProvider.overrideWith((ref) => Future.value(fixtureChallenges())),
    ]);
    addTearDown(container.dispose);
    // Keep the auto-dispose controller alive for the whole test.
    container.listen(breathingControllerProvider, (_, __) {});
    return container;
  }

  BreathingState stateOf(ProviderContainer c) => c.read(breathingControllerProvider);
  BreathingController ctl(ProviderContainer c) =>
      c.read(breathingControllerProvider.notifier);

  test('starts idle with the 4-4-6 pattern and a 2 minute session', () async {
    final c = await makeContainer();
    expect(stateOf(c).status, BreathingStatus.idle);
    expect(stateOf(c).pattern.inhaleSeconds, 4);
    expect(stateOf(c).pattern.holdSeconds, 4);
    expect(stateOf(c).pattern.exhaleSeconds, 6);
    expect(stateOf(c).totalSeconds, 120);
  });

  test('ticks do nothing until the session is started', () async {
    final c = await makeContainer();
    ctl(c).tick(const Duration(seconds: 5));
    expect(stateOf(c).elapsed, Duration.zero);
  });

  test('running time follows the elapsed time passed in', () async {
    final c = await makeContainer();
    ctl(c)
      ..start()
      ..tick(const Duration(milliseconds: 1500));
    expect(stateOf(c).status, BreathingStatus.running);
    expect(stateOf(c).elapsed, const Duration(milliseconds: 1500));
  });

  test('pause freezes time and resume continues from where it stopped', () async {
    final c = await makeContainer();
    ctl(c)
      ..start()
      ..tick(const Duration(seconds: 3))
      ..pause();
    expect(stateOf(c).status, BreathingStatus.paused);

    ctl(c).tick(const Duration(seconds: 50)); // ignored while paused
    expect(stateOf(c).elapsed, const Duration(seconds: 3));

    ctl(c).resume();
    expect(stateOf(c).status, BreathingStatus.running);
    // A resumed run reports time from zero again.
    ctl(c).tick(const Duration(seconds: 2));
    expect(stateOf(c).elapsed, const Duration(seconds: 5));
  });

  test('stop returns to idle and awards nothing', () async {
    final c = await makeContainer();
    ctl(c)
      ..start()
      ..tick(const Duration(seconds: 30))
      ..stop();
    expect(stateOf(c).status, BreathingStatus.idle);
    expect(stateOf(c).elapsed, Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(totalXpProvider), 0);
    expect(c.read(practiceSessionsProvider), isEmpty);
  });

  test('finishing the session records it and awards 5 XP once', () async {
    final c = await makeContainer();
    ctl(c)
      ..setTotalSeconds(10)
      ..start()
      ..tick(const Duration(seconds: 10));
    expect(stateOf(c).status, BreathingStatus.completed);

    // Further ticks must not record a second session.
    ctl(c)
      ..tick(const Duration(seconds: 11))
      ..tick(const Duration(seconds: 12));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(c.read(totalXpProvider), 5);
    final sessions = c.read(practiceSessionsProvider);
    expect(sessions.length, 1);
    expect(sessions.single.kind, PracticeKind.breathing);
    expect(sessions.single.xpAwarded, 5);
    expect(stateOf(c).reward?.xpAwarded, 5);
  });

  test('elapsed time never runs past the session length', () async {
    final c = await makeContainer();
    ctl(c)
      ..setTotalSeconds(10)
      ..start()
      ..tick(const Duration(seconds: 99));
    expect(stateOf(c).elapsed, const Duration(seconds: 10));
  });

  test('timings can be changed only when not running, and stay in range', () async {
    final c = await makeContainer();
    ctl(c).setHold(0);
    expect(stateOf(c).pattern.holdSeconds, 0);
    ctl(c).setInhale(99);
    expect(stateOf(c).pattern.inhaleSeconds, BreathingController.maxInhale);
    ctl(c).setExhale(0);
    expect(stateOf(c).pattern.exhaleSeconds, BreathingController.minExhale);

    ctl(c).start();
    ctl(c).setInhale(3);
    expect(stateOf(c).pattern.inhaleSeconds, BreathingController.maxInhale);
    ctl(c).selectPreset(breathingPresets.first);
    expect(stateOf(c).pattern.holdSeconds, 0);
  });

  test('presets include a pattern with no breath-holding', () {
    expect(breathingPresets.any((p) => p.holdSeconds == 0), isTrue);
    expect(breathingPresets.first.holdSeconds, 4);
  });
}

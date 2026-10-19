import 'package:confident_me/features/breathing/breathing_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calm = BreathingPattern(
    id: 'calm',
    name: 'Calm',
    inhaleSeconds: 4,
    holdSeconds: 4,
    exhaleSeconds: 6,
  );
  const noHold = BreathingPattern(
    id: 'no_hold',
    name: 'No hold',
    inhaleSeconds: 4,
    holdSeconds: 0,
    exhaleSeconds: 6,
  );

  BreathingFrame at(BreathingPattern p, double seconds) =>
      breathingFrameAt(p, Duration(milliseconds: (seconds * 1000).round()));

  test('starts by breathing in with a small circle', () {
    final f = at(calm, 0);
    expect(f.phase, BreathingPhase.inhale);
    expect(f.circleScale, 0);
    expect(f.secondsLeftInPhase, 4);
    expect(f.cycleNumber, 1);
  });

  test('the circle grows while breathing in', () {
    expect(at(calm, 2).circleScale, closeTo(0.5, 0.001));
    expect(at(calm, 1).circleScale, lessThan(at(calm, 3).circleScale));
  });

  test('phases follow 4 in, 4 hold, 6 out', () {
    expect(at(calm, 3.9).phase, BreathingPhase.inhale);
    expect(at(calm, 4).phase, BreathingPhase.hold);
    expect(at(calm, 4).circleScale, 1);
    expect(at(calm, 7.9).phase, BreathingPhase.hold);
    expect(at(calm, 8).phase, BreathingPhase.exhale);
    expect(at(calm, 13.9).phase, BreathingPhase.exhale);
  });

  test('the circle shrinks while breathing out', () {
    expect(at(calm, 8).circleScale, closeTo(1, 0.001));
    expect(at(calm, 11).circleScale, closeTo(0.5, 0.001));
    expect(at(calm, 13.99).circleScale, closeTo(0, 0.01));
  });

  test('a new cycle begins after 14 seconds', () {
    final f = at(calm, 14);
    expect(f.phase, BreathingPhase.inhale);
    expect(f.cycleNumber, 2);
    expect(at(calm, 29).cycleNumber, 3);
  });

  test('seconds remaining count down and never show zero', () {
    expect(at(calm, 0.1).secondsLeftInPhase, 4);
    expect(at(calm, 1.0).secondsLeftInPhase, 3);
    expect(at(calm, 3.5).secondsLeftInPhase, 1);
    expect(at(calm, 8.0).secondsLeftInPhase, 6);
    expect(at(calm, 13.5).secondsLeftInPhase, 1);
  });

  test('a hold of zero skips the hold phase', () {
    expect(at(noHold, 3.9).phase, BreathingPhase.inhale);
    expect(at(noHold, 4).phase, BreathingPhase.exhale);
    expect(at(noHold, 9.9).phase, BreathingPhase.exhale);
    expect(at(noHold, 10).phase, BreathingPhase.inhale);
    expect(at(noHold, 10).cycleNumber, 2);
  });

  test('position depends only on elapsed time, not on how often it is asked', () {
    // Asking about 20.0 seconds directly gives the same answer however many
    // frames were skipped on the way.
    final direct = at(calm, 20);
    expect(direct.cycleNumber, 2);
    expect(direct.phase, BreathingPhase.inhale);
    expect(direct.secondsLeftInPhase, 2);
  });

  test('copyWith marks the pattern as custom and keeps other timings', () {
    final custom = calm.copyWith(holdSeconds: 0);
    expect(custom.id, 'custom');
    expect(custom.inhaleSeconds, 4);
    expect(custom.holdSeconds, 0);
    expect(custom.sameTimingAs(noHold), isTrue);
    expect(custom.cycleSeconds, 10);
  });
}

import 'package:flutter/animation.dart';

class BreathingPattern {
  const BreathingPattern({
    required this.id,
    required this.name,
    required this.inhaleSeconds,
    required this.holdSeconds,
    required this.exhaleSeconds,
  });

  final String id;
  final String name;
  final int inhaleSeconds;

  /// 0 means "no hold" (skip breath-holding).
  final int holdSeconds;
  final int exhaleSeconds;

  int get cycleSeconds => inhaleSeconds + holdSeconds + exhaleSeconds;

  BreathingPattern copyWith({int? inhaleSeconds, int? holdSeconds, int? exhaleSeconds}) =>
      BreathingPattern(
        id: 'custom',
        name: 'Custom',
        inhaleSeconds: inhaleSeconds ?? this.inhaleSeconds,
        holdSeconds: holdSeconds ?? this.holdSeconds,
        exhaleSeconds: exhaleSeconds ?? this.exhaleSeconds,
      );

  bool sameTimingAs(BreathingPattern other) =>
      inhaleSeconds == other.inhaleSeconds &&
      holdSeconds == other.holdSeconds &&
      exhaleSeconds == other.exhaleSeconds;
}

const breathingPresets = <BreathingPattern>[
  BreathingPattern(
    id: 'calm',
    name: 'Calm 4-4-6',
    inhaleSeconds: 4,
    holdSeconds: 4,
    exhaleSeconds: 6,
  ),
  BreathingPattern(
    id: 'no_hold',
    name: 'No hold 4-6',
    inhaleSeconds: 4,
    holdSeconds: 0,
    exhaleSeconds: 6,
  ),
  BreathingPattern(
    id: 'gentle',
    name: 'Gentle 3-4',
    inhaleSeconds: 3,
    holdSeconds: 0,
    exhaleSeconds: 4,
  ),
];

enum BreathingPhase { inhale, hold, exhale }

class BreathingFrame {
  const BreathingFrame({
    required this.phase,
    required this.secondsLeftInPhase,
    required this.circleScale,
    required this.cycleNumber,
  });

  final BreathingPhase phase;

  /// Whole seconds remaining in this phase, counting down (4, 3, 2, 1).
  final int secondsLeftInPhase;

  /// 0 = smallest circle, 1 = largest.
  final double circleScale;
  final int cycleNumber;
}

/// Works out what to show purely from how much time has passed. Nothing here
/// counts ticks, so a slow or dropped frame cannot make the exercise drift.
BreathingFrame breathingFrameAt(BreathingPattern pattern, Duration elapsed) {
  final cycleMs = pattern.cycleSeconds * 1000;
  final totalMs = elapsed.inMilliseconds < 0 ? 0 : elapsed.inMilliseconds;
  final ms = totalMs % cycleMs;
  final cycle = totalMs ~/ cycleMs + 1;

  final inhaleMs = pattern.inhaleSeconds * 1000;
  final holdMs = pattern.holdSeconds * 1000;
  final exhaleMs = pattern.exhaleSeconds * 1000;

  int secondsLeft(int remainingMs) => (remainingMs / 1000).ceil();

  if (ms < inhaleMs) {
    final t = ms / inhaleMs;
    return BreathingFrame(
      phase: BreathingPhase.inhale,
      secondsLeftInPhase: secondsLeft(inhaleMs - ms),
      circleScale: Curves.easeInOut.transform(t),
      cycleNumber: cycle,
    );
  }
  if (ms < inhaleMs + holdMs) {
    return BreathingFrame(
      phase: BreathingPhase.hold,
      secondsLeftInPhase: secondsLeft(inhaleMs + holdMs - ms),
      circleScale: 1,
      cycleNumber: cycle,
    );
  }
  final t = (ms - inhaleMs - holdMs) / exhaleMs;
  return BreathingFrame(
    phase: BreathingPhase.exhale,
    secondsLeftInPhase: secondsLeft(cycleMs - ms),
    circleScale: 1 - Curves.easeInOut.transform(t),
    cycleNumber: cycle,
  );
}

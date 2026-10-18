import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/practice_session.dart';
import '../gamification/gamification_service.dart';
import 'breathing_timeline.dart';

enum BreathingStatus { idle, running, paused, completed }

class BreathingState {
  const BreathingState({
    required this.pattern,
    required this.totalSeconds,
    this.status = BreathingStatus.idle,
    this.elapsed = Duration.zero,
    this.reward,
  });

  final BreathingPattern pattern;
  final int totalSeconds;
  final BreathingStatus status;

  /// Time breathed so far, not counting time spent paused.
  final Duration elapsed;

  /// Set after a completed session has been recorded.
  final RewardResult? reward;

  Duration get total => Duration(seconds: totalSeconds);
  Duration get remaining => total - elapsed;

  BreathingState copyWith({
    BreathingPattern? pattern,
    int? totalSeconds,
    BreathingStatus? status,
    Duration? elapsed,
    RewardResult? reward,
    bool clearReward = false,
  }) =>
      BreathingState(
        pattern: pattern ?? this.pattern,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        status: status ?? this.status,
        elapsed: elapsed ?? this.elapsed,
        reward: clearReward ? null : (reward ?? this.reward),
      );
}

/// Controls one breathing session. It never starts its own timer: the screen
/// passes in the time since the current run began (from a frame Ticker) and
/// the controller adds it to the time already breathed before a pause.
class BreathingController extends AutoDisposeNotifier<BreathingState> {
  static const minInhale = 2, maxInhale = 8;
  static const minHold = 0, maxHold = 8;
  static const minExhale = 2, maxExhale = 10;

  Duration _before = Duration.zero;
  String _sessionId = '';

  @override
  BreathingState build() =>
      BreathingState(pattern: breathingPresets.first, totalSeconds: 120);

  bool get _canEdit =>
      state.status == BreathingStatus.idle ||
      state.status == BreathingStatus.completed;

  void _edit(BreathingState Function(BreathingState s) change) {
    if (!_canEdit) return;
    state = change(state).copyWith(
      status: BreathingStatus.idle,
      elapsed: Duration.zero,
      clearReward: true,
    );
  }

  void selectPreset(BreathingPattern preset) =>
      _edit((s) => s.copyWith(pattern: preset));

  void setInhale(int seconds) => _edit((s) => s.copyWith(
      pattern: s.pattern.copyWith(
          inhaleSeconds: seconds.clamp(minInhale, maxInhale).toInt())));

  void setHold(int seconds) => _edit((s) => s.copyWith(
      pattern: s.pattern
          .copyWith(holdSeconds: seconds.clamp(minHold, maxHold).toInt())));

  void setExhale(int seconds) => _edit((s) => s.copyWith(
      pattern: s.pattern.copyWith(
          exhaleSeconds: seconds.clamp(minExhale, maxExhale).toInt())));

  void setTotalSeconds(int seconds) =>
      _edit((s) => s.copyWith(totalSeconds: seconds < 5 ? 5 : seconds));

  void start() {
    if (!_canEdit) return;
    _before = Duration.zero;
    _sessionId = const Uuid().v4();
    state = state.copyWith(
      status: BreathingStatus.running,
      elapsed: Duration.zero,
      clearReward: true,
    );
  }

  /// [sinceRunStart] is the time since the latest start or resume.
  void tick(Duration sinceRunStart) {
    if (state.status != BreathingStatus.running) return;
    var elapsed = _before + sinceRunStart;
    if (elapsed >= state.total) {
      elapsed = state.total;
      state = state.copyWith(status: BreathingStatus.completed, elapsed: elapsed);
      unawaited(_recordCompletion(_sessionId));
      return;
    }
    state = state.copyWith(elapsed: elapsed);
  }

  void pause() {
    if (state.status != BreathingStatus.running) return;
    _before = state.elapsed;
    state = state.copyWith(status: BreathingStatus.paused);
  }

  void resume() {
    if (state.status != BreathingStatus.paused) return;
    state = state.copyWith(status: BreathingStatus.running);
  }

  /// Ends the session without recording it or awarding anything.
  void stop() {
    _before = Duration.zero;
    _sessionId = '';
    state = state.copyWith(
      status: BreathingStatus.idle,
      elapsed: Duration.zero,
      clearReward: true,
    );
  }

  Future<void> _recordCompletion(String sessionId) async {
    final result = await ref.read(gamificationServiceProvider).completePracticeSession(
          kind: PracticeKind.breathing,
          durationSeconds: state.totalSeconds,
          description: 'Breathing exercise',
          sessionId: sessionId,
        );
    try {
      if (_sessionId == sessionId && state.status == BreathingStatus.completed) {
        state = state.copyWith(reward: result);
      }
    } catch (_) {
      // The screen was closed while saving. The session is already recorded.
    }
  }
}

final breathingControllerProvider =
    AutoDisposeNotifierProvider<BreathingController, BreathingState>(
  BreathingController.new,
);

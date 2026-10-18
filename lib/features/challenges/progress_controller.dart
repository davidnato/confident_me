import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/clock.dart';
import '../../data/providers.dart';
import '../../models/challenge_progress.dart';

/// All challenge attempts, persisted after every change.
class ChallengeProgressController extends Notifier<List<ChallengeProgress>> {
  @override
  List<ChallengeProgress> build() => ref.read(progressRepositoryProvider).load();

  DateTime _now() => ref.read(clockProvider)();

  /// State is updated first so two quick actions cannot overwrite each other,
  /// then the new list is saved.
  Future<void> _write(List<ChallengeProgress> next) async {
    state = next;
    await ref.read(progressRepositoryProvider).save(next);
  }

  ChallengeProgress _newRecord(String challengeId, ChallengeStatus status) {
    final now = _now();
    return ChallengeProgress(
      id: const Uuid().v4(),
      challengeId: challengeId,
      status: status,
      startedAt: status == ChallengeStatus.inProgress ? now : null,
      updatedAt: now,
    );
  }

  Future<void> _replace(ChallengeProgress record) =>
      _write([for (final r in state) r.id == record.id ? record : r]);

  /// Starts an attempt. If one is already in progress it is reused, so tapping
  /// twice never creates duplicates. After a completed or skipped attempt this
  /// begins a fresh one ("do it again").
  Future<ChallengeProgress> start(String challengeId) async {
    final latest = state.latestFor(challengeId);
    if (latest != null && latest.status == ChallengeStatus.inProgress) {
      return latest;
    }
    final record = _newRecord(challengeId, ChallengeStatus.inProgress);
    await _write([...state, record]);
    return record;
  }

  /// Marks the current attempt completed and returns it. Returns null (and
  /// changes nothing) if the latest attempt is already completed, so a
  /// completion can only be recorded once per attempt.
  Future<ChallengeProgress?> complete(
    String challengeId, {
    String reflection = '',
  }) async {
    final latest = state.latestFor(challengeId);
    if (latest != null && latest.status == ChallengeStatus.completed) {
      return null;
    }
    final now = _now();
    if (latest != null && latest.status == ChallengeStatus.inProgress) {
      final done = latest.copyWith(
        status: ChallengeStatus.completed,
        completedAt: now,
        updatedAt: now,
        reflection: reflection.trim(),
      );
      await _replace(done);
      return done;
    }
    final record = _newRecord(challengeId, ChallengeStatus.inProgress).copyWith(
      status: ChallengeStatus.completed,
      completedAt: now,
      reflection: reflection.trim(),
    );
    await _write([...state, record]);
    return record;
  }

  /// Remembers how much XP an attempt earned (for display in history).
  Future<void> recordXp(String recordId, int xp) async {
    for (final r in state) {
      if (r.id == recordId) {
        await _replace(r.withXpAwarded(xp));
        return;
      }
    }
  }

  Future<void> skip(String challengeId) =>
      _setAside(challengeId, ChallengeStatus.skipped);

  /// Postpones until the start of tomorrow (local time).
  Future<void> postpone(String challengeId) {
    final now = _now();
    return _setAside(
      challengeId,
      ChallengeStatus.postponed,
      until: DateTime(now.year, now.month, now.day + 1),
    );
  }

  Future<void> _setAside(
    String challengeId,
    ChallengeStatus status, {
    DateTime? until,
  }) async {
    final latest = state.latestFor(challengeId);
    final now = _now();
    if (latest != null && latest.status != ChallengeStatus.completed) {
      await _replace(latest.copyWith(
        status: status,
        updatedAt: now,
        postponedUntil: until,
        clearPostponedUntil: until == null,
      ));
    } else {
      final record = _newRecord(challengeId, status)
          .copyWith(postponedUntil: until, updatedAt: now);
      await _write([...state, record]);
    }
  }

  /// Removes every attempt. Only used by the explicit reset / delete actions.
  Future<void> clearAll() async {
    state = [];
    await ref.read(progressRepositoryProvider).clear();
  }

  /// Chooses the smaller "Make this easier" version for the current attempt.
  Future<void> setSimplified(String challengeId) async {
    final record = await start(challengeId);
    await _replace(record.copyWith(simplified: true, updatedAt: _now()));
  }
}

final challengeProgressProvider =
    NotifierProvider<ChallengeProgressController, List<ChallengeProgress>>(
  ChallengeProgressController.new,
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/xp_config.dart';
import '../../core/utils/clock.dart';
import '../../models/achievement.dart';
import '../../models/challenge_progress.dart';
import '../../models/confidence_challenge.dart';
import '../../models/xp_transaction.dart';
import '../challenges/challenge_providers.dart';
import '../journal/journal_controller.dart';
import '../practice/practice_sessions_controller.dart';
import '../../models/practice_session.dart';
import '../challenges/progress_controller.dart';
import 'achievement_catalog.dart';
import 'achievements_controller.dart';
import 'gamification_providers.dart';
import 'level_calculator.dart';
import 'milestones_controller.dart';
import 'xp_ledger_controller.dart';

/// What happened when something was completed. Used to show feedback.
class RewardResult {
  const RewardResult({
    required this.recorded,
    required this.xpAwarded,
    required this.levelBefore,
    required this.levelAfter,
    this.newAchievements = const [],
  });

  /// False when the completion was ignored (for example, already completed).
  final bool recorded;
  final int xpAwarded;
  final LevelInfo levelBefore;
  final LevelInfo levelAfter;
  final List<Achievement> newAchievements;

  bool get leveledUp => levelAfter.level > levelBefore.level;
}

/// The one place that turns "I completed something" into XP and achievements,
/// so every reward goes through the same duplicate checks.
class GamificationService {
  GamificationService(this._ref);

  final Ref _ref;

  DateTime get _now => _ref.read(clockProvider)();

  RewardResult _nothing(LevelInfo level) => RewardResult(
        recorded: false,
        xpAwarded: 0,
        levelBefore: level,
        levelAfter: level,
      );

  Future<RewardResult> completeChallenge(
    ConfidenceChallenge challenge, {
    String reflection = '',
  }) async {
    final before = _ref.read(levelInfoProvider);
    final record = await _ref
        .read(challengeProgressProvider.notifier)
        .complete(challenge.id, reflection: reflection);
    if (record == null) return _nothing(before);

    final xp = await _awardChallenge(record, challenge);
    final achievements = await checkAchievements();
    return RewardResult(
      recorded: true,
      xpAwarded: xp,
      levelBefore: before,
      levelAfter: _ref.read(levelInfoProvider),
      newAchievements: achievements,
    );
  }

  Future<RewardResult> completeMilestone(String milestoneId) async {
    final before = _ref.read(levelInfoProvider);
    final done =
        await _ref.read(milestonesProvider.notifier).markDone(milestoneId);
    if (done == null) return _nothing(before);

    final amount = _ref.read(xpConfigProvider).milestone;
    final added = await _ref.read(xpLedgerProvider.notifier).award(
          XpTransaction(
            id: const Uuid().v4(),
            amount: amount,
            reason: XpReason.milestone,
            sourceKey: 'milestone:${done.id}',
            createdAt: _now,
            description: done.title,
          ),
        );
    if (added) {
      await _ref.read(milestonesProvider.notifier).recordXp(done.id, amount);
    }
    final achievements = await checkAchievements();
    return RewardResult(
      recorded: true,
      xpAwarded: added ? amount : 0,
      levelBefore: before,
      levelAfter: _ref.read(levelInfoProvider),
      newAchievements: achievements,
    );
  }

  /// Records a finished breathing session or scenario rehearsal and awards the
  /// practice XP once. [sessionId] makes it safe to call twice: the second call
  /// is ignored.
  Future<RewardResult> completePracticeSession({
    required PracticeKind kind,
    required int durationSeconds,
    required String description,
    String refId = '',
    String? sessionId,
  }) async {
    final before = _ref.read(levelInfoProvider);
    final id = sessionId ?? const Uuid().v4();
    final added = await _ref.read(practiceSessionsProvider.notifier).add(
          PracticeSession(
            id: id,
            kind: kind,
            completedAt: _now,
            refId: refId,
            durationSeconds: durationSeconds,
          ),
        );
    if (!added) return _nothing(before);

    final amount = _ref.read(xpConfigProvider).practiceSession;
    final awarded = await _ref.read(xpLedgerProvider.notifier).award(
          XpTransaction(
            id: const Uuid().v4(),
            amount: amount,
            reason: XpReason.practice,
            sourceKey: 'practice:$id',
            createdAt: _now,
            description: description,
          ),
        );
    if (awarded) {
      await _ref.read(practiceSessionsProvider.notifier).recordXp(id, amount);
    }
    final achievements = await checkAchievements();
    return RewardResult(
      recorded: true,
      xpAwarded: awarded ? amount : 0,
      levelBefore: before,
      levelAfter: _ref.read(levelInfoProvider),
      newAchievements: achievements,
    );
  }

  /// Call when the person finishes writing a journal entry. Journaling earns
  /// no XP; this only checks for new achievements.
  Future<RewardResult> afterJournalSaved() async {
    final level = _ref.read(levelInfoProvider);
    final achievements = await checkAchievements();
    return RewardResult(
      recorded: achievements.isNotEmpty,
      xpAwarded: 0,
      levelBefore: level,
      levelAfter: level,
      newAchievements: achievements,
    );
  }

  Future<int> _awardChallenge(
    ChallengeProgress record,
    ConfidenceChallenge challenge, {
    DateTime? at,
  }) async {
    final added = await _ref.read(xpLedgerProvider.notifier).award(
          XpTransaction(
            id: const Uuid().v4(),
            amount: challenge.xpReward,
            reason: XpReason.challenge,
            sourceKey: 'challenge:${record.id}',
            createdAt: at ?? _now,
            description: challenge.title,
          ),
        );
    if (!added) return 0;
    await _ref
        .read(challengeProgressProvider.notifier)
        .recordXp(record.id, challenge.xpReward);
    return challenge.xpReward;
  }

  /// Grants any achievements that are now earned and returns the new ones.
  Future<List<Achievement>> checkAchievements() async {
    final snapshot = buildAchievementSnapshot(
      progress: _ref.read(challengeProgressProvider),
      challenges: _ref.read(challengesProvider).valueOrNull ?? const [],
      milestones: _ref.read(milestonesProvider),
      longestStreak: _ref.read(streakProvider).longest,
      practiceSessions: _ref.read(practiceSessionsProvider),
      journalEntryCount:
          _ref.read(journalProvider).where((e) => !e.isBlank).length,
    );
    final newIds = await _ref
        .read(earnedAchievementsProvider.notifier)
        .grant(eligibleAchievementIds(snapshot), at: _now);
    return [
      for (final id in newIds)
        if (achievementById(id) case final a?) a,
    ];
  }

  /// Safe to run on every launch. Gives XP to completed attempts that have no
  /// XP entry yet (for example, challenges completed before XP existed), then
  /// checks achievements. Anything already awarded is skipped.
  Future<void> reconcile() async {
    final challenges = await _ref.read(challengesProvider.future);
    final byId = {for (final c in challenges) c.id: c};
    final ledger = _ref.read(xpLedgerProvider.notifier);
    for (final record in _ref.read(challengeProgressProvider).completedRecords) {
      if (ledger.hasSource('challenge:${record.id}')) continue;
      final challenge = byId[record.challengeId];
      if (challenge == null) continue;
      await _awardChallenge(
        record,
        challenge,
        at: record.completedAt ?? record.updatedAt,
      );
    }
    await checkAchievements();
  }
}

final gamificationServiceProvider =
    Provider<GamificationService>((ref) => GamificationService(ref));


import '../../models/challenge_progress.dart';

/// Short, neutral wording for a challenge's latest attempt (or null if none).
String? challengeStatusLabel(ChallengeProgress? progress, DateTime now) {
  if (progress == null) return null;
  switch (progress.status) {
    case ChallengeStatus.completed:
      return 'Completed';
    case ChallengeStatus.inProgress:
      return 'In progress';
    case ChallengeStatus.skipped:
      return 'Skipped for now';
    case ChallengeStatus.postponed:
      final until = progress.postponedUntil;
      return (until != null && until.isAfter(now)) ? 'Postponed' : null;
  }
}

import 'dart:convert';

import '../../core/constants/app_constants.dart';
import '../../models/affirmation.dart';
import '../../models/app_settings.dart';
import '../../models/challenge_progress.dart';
import '../../models/earned_achievement.dart';
import '../../models/journal_entry.dart';
import '../../models/milestone.dart';
import '../../models/practice_session.dart';
import '../../models/user_profile.dart';
import '../../models/xp_transaction.dart';

/// Builds the "export my data" file. Everything the app stores about the
/// person is included, so it is a complete copy. The bundled challenge,
/// scenario and affirmation libraries are not (they ship with the app).
class DataExport {
  const DataExport._();

  static const format = 'confidentme-export';
  static const schemaVersion = 1;

  static Map<String, dynamic> build({
    required DateTime now,
    required UserProfile? profile,
    required AppSettings settings,
    required List<ChallengeProgress> challengeProgress,
    required List<XpTransaction> xpHistory,
    required List<EarnedAchievement> achievements,
    required List<Milestone> milestones,
    required List<PracticeSession> practiceSessions,
    required List<JournalEntry> journalEntries,
    required List<Affirmation> customAffirmations,
    required Set<String> favoriteAffirmationIds,
    required Set<String> preferredAffirmationThemes,
  }) =>
      {
        'format': format,
        'schemaVersion': schemaVersion,
        'appVersion': AppConstants.version,
        'exportedAt': now.toIso8601String(),
        'data': {
          'profile': profile?.toJson(),
          'settings': settings.toJson(),
          'challengeProgress': [for (final r in challengeProgress) r.toJson()],
          'xpHistory': [for (final t in xpHistory) t.toJson()],
          'achievements': [for (final a in achievements) a.toJson()],
          'milestones': [for (final m in milestones) m.toJson()],
          'practiceSessions': [for (final p in practiceSessions) p.toJson()],
          'journalEntries': [for (final e in journalEntries) e.toJson()],
          'customAffirmations': [for (final a in customAffirmations) a.toJson()],
          'favoriteAffirmationIds': favoriteAffirmationIds.toList()..sort(),
          'preferredAffirmationThemes': preferredAffirmationThemes.toList()..sort(),
        },
      };

  static String toPrettyJson(Map<String, dynamic> export) =>
      const JsonEncoder.withIndent('  ').convert(export);
}

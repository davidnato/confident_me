import 'dart:convert';

import 'package:confident_me/core/constants/app_constants.dart';
import 'package:confident_me/features/settings/data_export.dart';
import 'package:confident_me/models/affirmation.dart';
import 'package:confident_me/models/app_settings.dart';
import 'package:confident_me/models/challenge_progress.dart';
import 'package:confident_me/models/earned_achievement.dart';
import 'package:confident_me/models/journal_entry.dart';
import 'package:confident_me/models/milestone.dart';
import 'package:confident_me/models/practice_session.dart';
import 'package:confident_me/models/user_profile.dart';
import 'package:confident_me/models/xp_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 18, 9);

  Map<String, dynamic> buildFull() => DataExport.build(
        now: now,
        profile: UserProfile(
          id: 'u1',
          createdAt: now,
          displayName: 'Alex',
          smallGoal: 'Say hello',
        ),
        settings: const AppSettings(),
        challengeProgress: [
          ChallengeProgress(
            id: 'p1',
            challengeId: 'c1',
            status: ChallengeStatus.completed,
            updatedAt: now,
            completedAt: now,
            reflection: 'It went okay',
          ),
        ],
        xpHistory: [
          XpTransaction(
            id: 'x1',
            amount: 10,
            reason: XpReason.challenge,
            sourceKey: 'challenge:p1',
            createdAt: now,
          ),
        ],
        achievements: [EarnedAchievement(achievementId: 'first_step', earnedAt: now)],
        milestones: [Milestone(id: 'm1', title: 'Spoke up', createdAt: now)],
        practiceSessions: [
          PracticeSession(id: 's1', kind: PracticeKind.breathing, completedAt: now),
        ],
        journalEntries: [
          JournalEntry(
            id: 'j1',
            createdAt: now,
            updatedAt: now,
            situation: 'Talked to a neighbour',
            lessonsLearned: 'It was fine',
          ),
        ],
        customAffirmations: const [
          Affirmation(id: 'custom_1', text: 'Mine', category: 'custom'),
        ],
        favoriteAffirmationIds: {'b', 'a'},
        preferredAffirmationThemes: {'calm'},
      );

  test('the export is labelled and versioned', () {
    final map = buildFull();
    expect(map['format'], 'confidentme-export');
    expect(map['schemaVersion'], 1);
    expect(map['appVersion'], AppConstants.version);
    expect(map['exportedAt'], now.toIso8601String());
  });

  test('it contains every kind of stored data', () {
    final data = buildFull()['data'] as Map<String, dynamic>;
    expect(
      data.keys,
      containsAll([
        'profile',
        'settings',
        'challengeProgress',
        'xpHistory',
        'achievements',
        'milestones',
        'practiceSessions',
        'journalEntries',
        'customAffirmations',
        'favoriteAffirmationIds',
        'preferredAffirmationThemes',
      ]),
    );
    expect((data['challengeProgress'] as List).length, 1);
    expect((data['xpHistory'] as List).length, 1);
    expect((data['achievements'] as List).length, 1);
    expect((data['milestones'] as List).length, 1);
    expect((data['practiceSessions'] as List).length, 1);
    expect((data['journalEntries'] as List).length, 1);
    expect((data['customAffirmations'] as List).length, 1);
    expect(data['favoriteAffirmationIds'], ['a', 'b']);
    expect((data['profile'] as Map)['displayName'], 'Alex');
  });

  test('the pretty text is valid JSON and keeps the journal words', () {
    final text = DataExport.toPrettyJson(buildFull());
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    final entry =
        ((decoded['data'] as Map)['journalEntries'] as List).single as Map;
    expect(entry['situation'], 'Talked to a neighbour');
    expect(entry['lessonsLearned'], 'It was fine');
    expect(text, contains('\n  ')); // indented for reading
  });

  test('an empty app still exports cleanly', () {
    final map = DataExport.build(
      now: now,
      profile: null,
      settings: const AppSettings(),
      challengeProgress: const [],
      xpHistory: const [],
      achievements: const [],
      milestones: const [],
      practiceSessions: const [],
      journalEntries: const [],
      customAffirmations: const [],
      favoriteAffirmationIds: const {},
      preferredAffirmationThemes: const {},
    );
    final data = map['data'] as Map<String, dynamic>;
    expect(data['profile'], isNull);
    expect(data['journalEntries'], isEmpty);
    expect(() => jsonDecode(DataExport.toPrettyJson(map)), returnsNormally);
  });
}

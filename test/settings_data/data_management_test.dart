import 'dart:convert';

import 'package:confident_me/core/utils/clock.dart';
import 'package:confident_me/data/providers.dart';
import 'package:confident_me/data/repositories/record_store.dart';
import 'package:confident_me/features/affirmations/affirmation_providers.dart';
import 'package:confident_me/features/challenges/challenge_providers.dart';
import 'package:confident_me/features/challenges/progress_controller.dart';
import 'package:confident_me/features/gamification/achievements_controller.dart';
import 'package:confident_me/features/gamification/gamification_providers.dart';
import 'package:confident_me/features/gamification/gamification_service.dart';
import 'package:confident_me/features/gamification/milestones_controller.dart';
import 'package:confident_me/features/gamification/xp_ledger_controller.dart';
import 'package:confident_me/features/journal/journal_controller.dart';
import 'package:confident_me/features/onboarding/profile_controller.dart';
import 'package:confident_me/features/practice/practice_sessions_controller.dart';
import 'package:confident_me/features/settings/data_management_service.dart';
import 'package:confident_me/features/settings/reminder_logic.dart';
import 'package:confident_me/features/settings_controller.dart';
import 'package:confident_me/models/journal_entry.dart';
import 'package:confident_me/models/practice_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fixtures.dart';

void main() {
  final now = DateTime(2026, 10, 18, 9);
  late InMemoryRecordStoreFactory records;

  Future<ProviderContainer> makeContainer() async {
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      recordStoreFactoryProvider.overrideWithValue(records),
      clockProvider.overrideWithValue(() => now),
      challengesProvider.overrideWith((ref) => Future.value(fixtureChallenges())),
    ]);
    addTearDown(c.dispose);
    await c.read(challengesProvider.future);
    return c;
  }

  /// Puts something in every store the app has.
  Future<void> fillEverything(ProviderContainer c) async {
    final service = c.read(gamificationServiceProvider);
    await c.read(profileProvider.notifier).continueAsGuest();
    await c.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark);
    await c.read(settingsProvider.notifier).setGamificationEnabled(false);
    await service.completeChallenge(fixtureChallenges().first, reflection: 'ok');
    final m = (await c.read(milestonesProvider.notifier).add('Spoke up'))!;
    await service.completeMilestone(m.id);
    await service.completePracticeSession(
      kind: PracticeKind.breathing,
      durationSeconds: 60,
      description: 'Breathing exercise',
      sessionId: 's1',
    );
    await c.read(journalProvider.notifier).save(
          JournalEntry(id: 'j1', createdAt: now, updatedAt: now, situation: 'Hello'),
        );
    await c.read(customAffirmationsProvider.notifier).add('Mine');
    await c.read(affirmationPrefsProvider.notifier).toggleFavorite('a1');
    await c.read(affirmationPrefsProvider.notifier).toggleCategory('calm');
    await c.read(reminderDismissProvider.notifier).dismissToday();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    records = InMemoryRecordStoreFactory();
  });

  test('export includes everything that was stored', () async {
    final c = await makeContainer();
    await fillEverything(c);
    final decoded = jsonDecode(c.read(dataManagementServiceProvider).exportJson())
        as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    expect((data['journalEntries'] as List).length, 1);
    expect((data['challengeProgress'] as List).length, 1);
    expect((data['milestones'] as List).length, 1);
    expect((data['practiceSessions'] as List).length, 1);
    expect((data['customAffirmations'] as List).length, 1);
    expect((data['xpHistory'] as List).length, 3);
    expect(data['favoriteAffirmationIds'], ['a1']);
    expect((data['settings'] as Map)['themeMode'], 'dark');
  });

  test('reset progress clears progress but keeps journal, affirmations, '
      'settings and profile', () async {
    final c = await makeContainer();
    await fillEverything(c);
    expect(c.read(totalXpProvider), greaterThan(0));

    await c.read(dataManagementServiceProvider).resetProgress();

    expect(c.read(challengeProgressProvider), isEmpty);
    expect(c.read(xpLedgerProvider), isEmpty);
    expect(c.read(totalXpProvider), 0);
    expect(c.read(levelInfoProvider).level, 1);
    expect(c.read(earnedAchievementsProvider), isEmpty);
    expect(c.read(milestonesProvider), isEmpty);
    expect(c.read(practiceSessionsProvider), isEmpty);

    expect(c.read(journalProvider).length, 1);
    expect(c.read(customAffirmationsProvider).length, 1);
    expect(c.read(affirmationPrefsProvider).favoriteIds, {'a1'});
    expect(c.read(profileProvider), isNotNull);
    expect(c.read(settingsProvider).themeMode, ThemeMode.dark);
  });

  test('reset progress is permanent across a restart', () async {
    final c = await makeContainer();
    await fillEverything(c);
    await c.read(dataManagementServiceProvider).resetProgress();

    final restarted = await makeContainer();
    expect(restarted.read(challengeProgressProvider), isEmpty);
    expect(restarted.read(xpLedgerProvider), isEmpty);
    expect(restarted.read(earnedAchievementsProvider), isEmpty);
    expect(restarted.read(milestonesProvider), isEmpty);
    expect(restarted.read(practiceSessionsProvider), isEmpty);
    expect(restarted.read(journalProvider).length, 1);
  });

  test('delete all data removes everything and clears the profile', () async {
    final c = await makeContainer();
    await fillEverything(c);

    await c.read(dataManagementServiceProvider).deleteAllData();

    expect(c.read(profileProvider), isNull);
    expect(c.read(journalProvider), isEmpty);
    expect(c.read(customAffirmationsProvider), isEmpty);
    expect(c.read(affirmationPrefsProvider).favoriteIds, isEmpty);
    expect(c.read(affirmationPrefsProvider).categories, isEmpty);
    expect(c.read(reminderDismissProvider), isNull);
    expect(c.read(challengeProgressProvider), isEmpty);
    expect(c.read(totalXpProvider), 0);
    final settings = c.read(settingsProvider);
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.gamificationEnabled, isTrue);
  });

  test('delete all data is permanent across a restart', () async {
    final c = await makeContainer();
    await fillEverything(c);
    await c.read(dataManagementServiceProvider).deleteAllData();

    final restarted = await makeContainer();
    expect(restarted.read(profileProvider), isNull);
    expect(restarted.read(journalProvider), isEmpty);
    expect(restarted.read(customAffirmationsProvider), isEmpty);
    expect(restarted.read(milestonesProvider), isEmpty);
    expect(restarted.read(practiceSessionsProvider), isEmpty);
    expect(restarted.read(xpLedgerProvider), isEmpty);
    expect(restarted.read(settingsProvider).themeMode, ThemeMode.system);
    expect(restarted.read(affirmationPrefsProvider).favoriteIds, isEmpty);
  });

  test('after deleting, the app can be used again from scratch', () async {
    final c = await makeContainer();
    await fillEverything(c);
    await c.read(dataManagementServiceProvider).deleteAllData();

    await c.read(profileProvider.notifier).continueAsGuest();
    final r = await c
        .read(gamificationServiceProvider)
        .completeChallenge(fixtureChallenges().first);
    expect(r.recorded, isTrue);
    expect(c.read(totalXpProvider), 10);
  });
}

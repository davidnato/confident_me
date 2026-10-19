import 'dart:convert';

import 'package:confident_me/data/providers.dart';
import 'package:confident_me/data/repositories/profile_repository.dart';
import 'package:confident_me/data/repositories/settings_repository.dart';
import 'package:confident_me/features/onboarding/onboarding_controller.dart';
import 'package:confident_me/features/settings_controller.dart';
import 'package:confident_me/models/app_settings.dart';
import 'package:confident_me/models/difficulty.dart';
import 'package:confident_me/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> makeContainer([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<ProviderContainer> restart() async {
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('defaults are gentle: reminders off, daily challenge on', () async {
    final c = await makeContainer();
    final s = c.read(settingsProvider);
    expect(s.remindersEnabled, isFalse);
    expect(s.dailyChallengeEnabled, isTrue);
    expect(s.gamificationEnabled, isTrue);
    expect(s.themeMode, ThemeMode.system);
    expect(s.preferredDifficulty, Difficulty.easy);
  });

  test('every setting is saved and survives a restart', () async {
    final c = await makeContainer();
    final n = c.read(settingsProvider.notifier);
    await n.setThemeMode(ThemeMode.dark);
    await n.setPreferredDifficulty(Difficulty.hard);
    await n.setDailyChallengeEnabled(false);
    await n.setRemindersEnabled(true);
    await n.setReminderMinutes(8 * 60 + 15);
    await n.setGamificationEnabled(false);

    final s = (await restart()).read(settingsProvider);
    expect(s.themeMode, ThemeMode.dark);
    expect(s.preferredDifficulty, Difficulty.hard);
    expect(s.dailyChallengeEnabled, isFalse);
    expect(s.remindersEnabled, isTrue);
    expect(s.reminderMinutes, 495);
    expect(s.gamificationEnabled, isFalse);
  });

  test('the reminder time stays within a day', () async {
    final c = await makeContainer();
    await c.read(settingsProvider.notifier).setReminderMinutes(5000);
    expect(c.read(settingsProvider).reminderMinutes, 1439);
    await c.read(settingsProvider.notifier).setReminderMinutes(-1);
    expect(c.read(settingsProvider).reminderMinutes, 0);
  });

  test('reset returns to the defaults and forgets what was stored', () async {
    final c = await makeContainer();
    await c.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark);
    await c.read(settingsProvider.notifier).reset();
    expect(c.read(settingsProvider).themeMode, ThemeMode.system);
    final prefs = await SharedPreferences.getInstance();
    expect(SettingsRepository(prefs).hasStored, isFalse);
  });

  test('an earlier starting difficulty from the profile carries over when no '
      'settings were saved', () async {
    final profile = UserProfile.guest(id: 'u', now: DateTime(2026, 1, 1));
    final withMedium = UserProfile(
      id: profile.id,
      createdAt: profile.createdAt,
      preferredDifficulty: Difficulty.medium,
    );
    final c = await makeContainer({
      ProfileRepository.storageKey: jsonEncode(withMedium.toJson()),
    });
    expect(c.read(settingsProvider).preferredDifficulty, Difficulty.medium);
  });

  test('saved settings win over the profile', () async {
    final profile = UserProfile(
      id: 'u',
      createdAt: DateTime(2026, 1, 1),
      preferredDifficulty: Difficulty.medium,
    );
    final c = await makeContainer({
      ProfileRepository.storageKey: jsonEncode(profile.toJson()),
      SettingsRepository.storageKey: jsonEncode(
        const AppSettings(preferredDifficulty: Difficulty.hard).toJson(),
      ),
    });
    expect(c.read(settingsProvider).preferredDifficulty, Difficulty.hard);
  });

  test('finishing onboarding sets the starting difficulty in settings', () async {
    final c = await makeContainer();
    c.listen(onboardingControllerProvider, (_, __) {});
    final o = c.read(onboardingControllerProvider.notifier);
    o.setSocialDifficulty(1); // finds it mostly comfortable -> Intermediate
    await o.finish();
    expect(c.read(settingsProvider).preferredDifficulty, Difficulty.medium);

    final restarted = await restart();
    expect(restarted.read(settingsProvider).preferredDifficulty, Difficulty.medium);
  });
}

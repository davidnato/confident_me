import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../models/app_settings.dart';
import '../models/difficulty.dart';
import 'onboarding/profile_controller.dart';

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = repo.load();
    // Before Phase 5 the starting difficulty lived only in the profile. If no
    // settings were ever saved, carry that choice over.
    if (!repo.hasStored) {
      final profile = ref.read(profileProvider);
      if (profile != null) {
        return settings.copyWith(preferredDifficulty: profile.preferredDifficulty);
      }
    }
    return settings;
  }

  Future<void> update(AppSettings settings) async {
    state = settings;
    await ref.read(settingsRepositoryProvider).save(settings);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      update(state.copyWith(themeMode: mode));

  Future<void> setPreferredDifficulty(Difficulty difficulty) =>
      update(state.copyWith(preferredDifficulty: difficulty));

  Future<void> setDailyChallengeEnabled(bool enabled) =>
      update(state.copyWith(dailyChallengeEnabled: enabled));

  Future<void> setRemindersEnabled(bool enabled) =>
      update(state.copyWith(remindersEnabled: enabled));

  Future<void> setReminderMinutes(int minutes) =>
      update(state.copyWith(reminderMinutes: minutes.clamp(0, 1439).toInt()));

  Future<void> setGamificationEnabled(bool enabled) =>
      update(state.copyWith(gamificationEnabled: enabled));

  /// Back to defaults (used by "Delete all my data").
  Future<void> reset() async {
    state = const AppSettings();
    await ref.read(settingsRepositoryProvider).clear();
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

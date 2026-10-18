import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../models/app_settings.dart';

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsRepositoryProvider).load();

  Future<void> update(AppSettings settings) async {
    await ref.read(settingsRepositoryProvider).save(settings);
    state = settings;
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      update(state.copyWith(themeMode: mode));
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

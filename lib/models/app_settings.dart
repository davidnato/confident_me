import 'package:flutter/material.dart';

import 'difficulty.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.remindersEnabled = false,
    this.preferredDifficulty = Difficulty.easy,
    this.dailyChallengeEnabled = true,
    this.gamificationEnabled = true,
  });

  final ThemeMode themeMode;
  final bool remindersEnabled;
  final Difficulty preferredDifficulty;
  final bool dailyChallengeEnabled;
  final bool gamificationEnabled;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? remindersEnabled,
    Difficulty? preferredDifficulty,
    bool? dailyChallengeEnabled,
    bool? gamificationEnabled,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
        dailyChallengeEnabled:
            dailyChallengeEnabled ?? this.dailyChallengeEnabled,
        gamificationEnabled: gamificationEnabled ?? this.gamificationEnabled,
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'remindersEnabled': remindersEnabled,
        'preferredDifficulty': preferredDifficulty.id,
        'dailyChallengeEnabled': dailyChallengeEnabled,
        'gamificationEnabled': gamificationEnabled,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    var mode = ThemeMode.system;
    final rawMode = json['themeMode'];
    if (rawMode is String) {
      for (final m in ThemeMode.values) {
        if (m.name == rawMode) mode = m;
      }
    }
    return AppSettings(
      themeMode: mode,
      remindersEnabled: json['remindersEnabled'] == true,
      preferredDifficulty: Difficulty.fromId(
        json['preferredDifficulty'] is String
            ? json['preferredDifficulty'] as String
            : null,
      ),
      dailyChallengeEnabled: json['dailyChallengeEnabled'] != false,
      gamificationEnabled: json['gamificationEnabled'] != false,
    );
  }
}

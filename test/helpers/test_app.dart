import 'dart:convert';

import 'package:confident_me/app.dart';
import 'package:confident_me/core/utils/clock.dart';
import 'package:confident_me/data/providers.dart';
import 'package:confident_me/data/repositories/profile_repository.dart';
import 'package:confident_me/data/repositories/settings_repository.dart';
import 'package:confident_me/models/app_settings.dart';
import 'package:confident_me/data/repositories/record_store.dart';
import 'package:confident_me/features/social_practice/scenario_providers.dart';
import 'package:confident_me/features/affirmations/affirmation_providers.dart';
import 'package:confident_me/features/challenges/challenge_providers.dart';
import 'package:confident_me/models/confidence_challenge.dart';
import 'package:confident_me/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

/// Starts the real app with fixture data.
///
/// The test surface is deliberately large: flutter_test draws text with a very
/// wide font, so a phone-sized screen would push buttons off-screen.
Future<void> pumpApp(
  WidgetTester tester, {
  bool withProfile = true,
  List<ConfidenceChallenge>? challenges,
  DateTime? now,
  AppSettings? settings,
}) async {
  SharedPreferences.setMockInitialValues({
    if (settings != null)
      SettingsRepository.storageKey: jsonEncode(settings.toJson()),
    if (withProfile)
      ProfileRepository.storageKey: jsonEncode(
        UserProfile.guest(id: 'test-user', now: DateTime(2026, 1, 1)).toJson(),
      ),
  });
  final prefs = await SharedPreferences.getInstance();

  tester.view.physicalSize = const Size(1500, 3000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        recordStoreFactoryProvider.overrideWithValue(InMemoryRecordStoreFactory()),
        scenariosProvider.overrideWith((ref) => Future.value(fixtureScenarios())),
        challengesProvider.overrideWith(
          (ref) => Future.value(challenges ?? fixtureChallenges()),
        ),
        affirmationsProvider.overrideWith(
          (ref) => Future.value(fixtureAffirmations()),
        ),
        if (now != null) clockProvider.overrideWithValue(() => now),
      ],
      child: const ConfidentMeApp(),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(ConfidentMeApp)));

/// Scrolls the widget into view first. A plain tap silently misses anything
/// that is off-screen.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

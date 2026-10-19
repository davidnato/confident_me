import 'dart:convert';

import 'package:confident_me/core/constants/app_constants.dart';
import 'package:confident_me/features/challenges/progress_controller.dart';
import 'package:confident_me/features/gamification/gamification_providers.dart';
import 'package:confident_me/features/gamification/gamification_service.dart';
import 'package:confident_me/features/journal/journal_controller.dart';
import 'package:confident_me/features/settings/reminder_logic.dart';
import 'package:confident_me/features/settings_controller.dart';
import 'package:confident_me/models/app_settings.dart';
import 'package:confident_me/models/challenge_progress.dart';
import 'package:confident_me/models/difficulty.dart';
import 'package:confident_me/models/journal_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';

Future<void> openSettings(WidgetTester tester) async {
  await tapVisible(tester, find.byKey(const Key('open_settings')));
}

Future<void> addJournalEntry(WidgetTester tester) async {
  final now = DateTime.now();
  await containerOf(tester).read(journalProvider.notifier).save(
        JournalEntry(
          id: 'j1',
          createdAt: now,
          updatedAt: now,
          situation: 'Talked to a neighbour',
        ),
      );
  await tester.pumpAndSettle();
}

Future<void> completeFirstChallenge(WidgetTester tester) async {
  await containerOf(tester)
      .read(gamificationServiceProvider)
      .completeChallenge(fixtureChallenges().first);
  await tester.pumpAndSettle();
}

/// Captures what the app copies to the clipboard.
List<String> captureClipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
  return copied;
}

Finder inDialog(String text) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

void main() {
  testWidgets('settings opens from Home and shows privacy and version',
      (tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.byKey(const Key('privacy_card')), findsOneWidget);
    expect(find.textContaining('Everything you enter stays on this device'),
        findsOneWidget);
    expect(find.textContaining('no analytics'), findsOneWidget);
    expect(
        find.textContaining('does not add its own encryption'), findsOneWidget);
    final version = tester.widget<Text>(find.byKey(const Key('about_version')));
    expect(version.data, contains(AppConstants.version));
  });

  testWidgets('settings opens from the Progress tab too', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav_progress')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('progress_open_settings')));
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('theme selection changes the app theme', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    await tapVisible(tester, find.text('Dark'));
    expect(
        containerOf(tester).read(settingsProvider).themeMode, ThemeMode.dark);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark);

    await tapVisible(tester, find.text('Light'));
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light);
  });

  testWidgets('preferred difficulty can be changed', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Advanced'));
    expect(containerOf(tester).read(settingsProvider).preferredDifficulty,
        Difficulty.hard);
  });

  testWidgets('turning off the daily challenge changes Home kindly',
      (tester) async {
    await pumpApp(tester);
    expect(find.text('Try one small step'), findsOneWidget);

    await openSettings(tester);
    await tapVisible(tester, find.byKey(const Key('daily_challenge_switch')));
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('daily_off_card')), findsOneWidget);
    expect(find.text('Try one small step'), findsNothing);

    await tapVisible(tester, find.text('Browse challenges'));
    expect(find.textContaining('Showing 6 of 6'), findsOneWidget);
  });

  testWidgets(
      'reminder settings: off by default, time and message appear when on',
      (tester) async {
    await pumpApp(tester);
    await openSettings(tester);
    expect(
        containerOf(tester).read(settingsProvider).remindersEnabled, isFalse);
    expect(find.byKey(const Key('reminder_time')), findsNothing);

    await tapVisible(tester, find.byKey(const Key('reminder_switch')));
    expect(containerOf(tester).read(settingsProvider).remindersEnabled, isTrue);
    expect(find.byKey(const Key('reminder_time')), findsOneWidget);
    expect(find.textContaining(reminderMessage), findsOneWidget);
    expect(find.textContaining('Phone notifications are not set up'),
        findsOneWidget);
  });

  testWidgets(
      'the gentle reminder shows on Home and can be dismissed for today',
      (tester) async {
    await pumpApp(
      tester,
      settings: const AppSettings(remindersEnabled: true, reminderMinutes: 0),
    );
    expect(find.byKey(const Key('reminder_card')), findsOneWidget);
    expect(find.text(reminderMessage), findsOneWidget);

    await tapVisible(tester, find.text('Not today'));
    expect(find.byKey(const Key('reminder_card')), findsNothing);
    expect(containerOf(tester).read(reminderDismissProvider), isNotNull);
  });

  testWidgets('the reminder goes away once you do something', (tester) async {
    await pumpApp(
      tester,
      settings: const AppSettings(remindersEnabled: true, reminderMinutes: 0),
    );
    expect(find.byKey(const Key('reminder_card')), findsOneWidget);
    await completeFirstChallenge(tester);
    expect(find.byKey(const Key('reminder_card')), findsNothing);
  });

  testWidgets('no reminder is shown while reminders are off', (tester) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('reminder_card')), findsNothing);
  });

  testWidgets('export asks first, then copies everything', (tester) async {
    final copied = captureClipboard(tester);
    await pumpApp(tester);
    await addJournalEntry(tester);
    await openSettings(tester);

    await tapVisible(tester, find.byKey(const Key('export_button')));
    expect(find.text('Copy my data?'), findsOneWidget);
    expect(copied, isEmpty);
    await tapVisible(tester, find.text('Cancel'));
    expect(copied, isEmpty);

    await tapVisible(tester, find.byKey(const Key('export_button')));
    await tapVisible(tester, inDialog('Copy'));
    expect(copied.length, 1);
    final decoded = jsonDecode(copied.single) as Map<String, dynamic>;
    expect(decoded['format'], 'confidentme-export');
    final entries = (decoded['data'] as Map)['journalEntries'] as List;
    expect(entries.length, 1);
    expect((entries.single as Map)['situation'], 'Talked to a neighbour');
    expect(find.textContaining('Copied'), findsOneWidget);
  });

  testWidgets('reset progress: cancel keeps everything', (tester) async {
    await pumpApp(tester);
    await completeFirstChallenge(tester);
    await addJournalEntry(tester);
    await openSettings(tester);

    await tapVisible(tester, find.byKey(const Key('reset_button')));
    expect(find.text('Reset your progress?'), findsOneWidget);
    await tapVisible(tester, find.text('Cancel'));

    final c = containerOf(tester);
    expect(c.read(challengeProgressProvider).completedCount, 1);
    expect(c.read(totalXpProvider), greaterThan(0));
  });

  testWidgets('reset progress: confirm clears progress but keeps the journal',
      (tester) async {
    await pumpApp(tester);
    await completeFirstChallenge(tester);
    await addJournalEntry(tester);
    await openSettings(tester);

    await tapVisible(tester, find.byKey(const Key('reset_button')));
    await tapVisible(tester, inDialog('Reset progress'));

    final c = containerOf(tester);
    expect(c.read(challengeProgressProvider), isEmpty);
    expect(c.read(totalXpProvider), 0);
    expect(c.read(journalProvider).length, 1);
    expect(find.text('Progress reset. A fresh start.'), findsOneWidget);
  });

  testWidgets(
      'delete all data needs DELETE typed, then returns to the welcome '
      'screen', (tester) async {
    await pumpApp(tester);
    await completeFirstChallenge(tester);
    await addJournalEntry(tester);
    await openSettings(tester);

    await tapVisible(tester, find.byKey(const Key('delete_button')));
    expect(find.text('Delete all your data?'), findsOneWidget);

    FilledButton confirm() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete everything'));
    expect(confirm().onPressed, isNull);

    await tester.enterText(
        find.byKey(const Key('typed_confirm_field')), 'delete');
    await tester.pump();
    expect(confirm().onPressed, isNull);

    await tester.enterText(
        find.byKey(const Key('typed_confirm_field')), 'DELETE');
    await tester.pump();
    expect(confirm().onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete everything'));
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);
    final c = containerOf(tester);
    expect(c.read(journalProvider), isEmpty);
    expect(c.read(challengeProgressProvider), isEmpty);
    expect(c.read(totalXpProvider), 0);
  });

  testWidgets('delete all data can be cancelled', (tester) async {
    await pumpApp(tester);
    await addJournalEntry(tester);
    await openSettings(tester);

    await tapVisible(tester, find.byKey(const Key('delete_button')));
    await tapVisible(tester, find.text('Cancel'));
    expect(containerOf(tester).read(journalProvider).length, 1);
    expect(find.text('Get started'), findsNothing);
  });

  testWidgets('progress shows the weekly calendar and categories explored',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav_progress')));
    await tester.pumpAndSettle();

    for (var i = 0; i < 7; i++) {
      expect(find.byKey(Key('day_cell_$i')), findsOneWidget);
    }
    expect(find.textContaining('Nothing yet this week'), findsOneWidget);
    expect(find.text('0 of 8'), findsOneWidget);

    await completeFirstChallenge(tester);
    expect(find.text('1 step in the last 7 days.'), findsOneWidget);
    expect(find.text('1 of 8'), findsOneWidget);
    expect(find.byKey(const Key('recent_first_step')), findsOneWidget);
  });

  testWidgets('journal entries and challenges both count toward the week',
      (tester) async {
    await pumpApp(tester);
    await completeFirstChallenge(tester);
    await addJournalEntry(tester);
    await tester.tap(find.byKey(const Key('nav_progress')));
    await tester.pumpAndSettle();
    expect(find.text('2 steps in the last 7 days.'), findsOneWidget);
  });
}

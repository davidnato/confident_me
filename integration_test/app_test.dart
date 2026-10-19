// Main-workflow integration test. Run it on an emulator or a real device:
//
//   flutter test integration_test/app_test.dart -d <device id>
//
// It starts the real app with the real bundled challenge library, but with
// in-memory storage, so it never touches (or depends on) data already saved on
// the device.
import 'package:confident_me/app.dart';
import 'package:confident_me/data/providers.dart';
import 'package:confident_me/data/repositories/record_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'onboard, complete a challenge, write a journal entry, restart and keep it all',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final records = InMemoryRecordStoreFactory();

      Widget app() => ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              recordStoreFactoryProvider.overrideWithValue(records),
            ],
            child: const ConfidentMeApp(),
          );

      // 1. Welcome and onboarding.
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Get started'), findsOneWidget);
      await tapVisible(tester, find.text('Get started'));
      await tester.enterText(find.byType(TextField), 'Sam');
      for (var i = 0; i < 4; i++) {
        await tapVisible(tester, find.text('Continue'));
      }
      await tapVisible(tester, find.text('Finish'));

      // 2. Home shows a personal greeting and today's suggestion.
      final greeting = tester.widget<Text>(find.byKey(const Key('home_greeting')));
      expect(greeting.data, endsWith(', Sam'));
      expect(find.byKey(const Key('todays_challenge_title')), findsOneWidget);

      // 3. Open it, start it, and complete it with a reflection.
      await tapVisible(tester, find.text('Try one small step'));
      await tapVisible(tester, find.text('Start this challenge'));
      await tapVisible(tester, find.text('Mark as completed'));
      await tester.enterText(find.byType(TextField), 'That went okay.');
      await tapVisible(tester, find.text('Save and finish'));
      expect(find.text('Something to celebrate'), findsOneWidget);
      await tapVisible(tester, find.text('Continue'));
      expect(find.byKey(const Key('completed_card')), findsOneWidget);

      // 4. Progress shows the completion and the XP.
      await tapVisible(tester, find.byKey(const Key('nav_progress')));
      expect(find.text('1 challenge completed'), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);

      // 5. Write a journal entry.
      await tapVisible(tester, find.byKey(const Key('nav_journal')));
      await tapVisible(tester, find.byKey(const Key('new_entry_fab')));
      await tester.enterText(
          find.byKey(const Key('journal_field_0')), 'I tried something new');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Done'));
      await tapVisible(tester, find.text('Continue'));
      expect(find.text('I tried something new'), findsOneWidget);

      // 6. Restart the app with the same stored data.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_greeting')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('nav_progress')));
      expect(find.text('1 challenge completed'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('nav_journal')));
      expect(find.text('I tried something new'), findsOneWidget);
    },
  );
}

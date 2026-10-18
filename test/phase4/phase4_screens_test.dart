import 'package:confident_me/features/affirmations/affirmation_providers.dart';
import 'package:confident_me/features/breathing/breathing_controller.dart';
import 'package:confident_me/features/gamification/gamification_providers.dart';
import 'package:confident_me/features/journal/journal_controller.dart';
import 'package:confident_me/features/practice/practice_sessions_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

Future<void> openTab(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

String phaseText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('breathing_phase'))).data!;

void main() {
  testWidgets('practice hub lists breathing, affirmations and scenarios',
      (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'nav_practice');
    expect(find.text('Breathing exercise'), findsOneWidget);
    expect(find.text('Affirmations'), findsOneWidget);
    expect(find.text('Introducing yourself'), findsOneWidget);
    expect(find.text('Handling an awkward pause'), findsOneWidget);
  });

  testWidgets('breathing: start, pause, resume and stop all work', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'nav_practice');
    await tapVisible(tester, find.byKey(const Key('link_breathing')));

    expect(find.text('Start'), findsOneWidget);
    expect(find.textContaining('dizzy'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(phaseText(tester), 'Breathe in');

    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Resume'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(phaseText(tester), 'Hold gently');

    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
    expect(containerOf(tester).read(totalXpProvider), 0);
  });

  testWidgets('breathing: pattern settings can be changed and holds skipped',
      (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'nav_practice');
    await tapVisible(tester, find.byKey(const Key('link_breathing')));

    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'No hold 4-6'));
    final state = containerOf(tester).read(breathingControllerProvider);
    expect(state.pattern.holdSeconds, 0);

    await tapVisible(tester, find.widgetWithText(ChoiceChip, '5 min'));
    expect(containerOf(tester).read(breathingControllerProvider).totalSeconds, 300);
  });

  testWidgets('breathing: finishing shows a kind message and awards 5 XP once',
      (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'nav_practice');
    await tapVisible(tester, find.byKey(const Key('link_breathing')));

    containerOf(tester).read(breathingControllerProvider.notifier).setTotalSeconds(10);
    await tester.pump();

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('breathing_complete')), findsOneWidget);
    expect(find.text('+5 XP'), findsOneWidget);
    expect(containerOf(tester).read(totalXpProvider), 5);
    expect(containerOf(tester).read(practiceSessionsProvider).length, 1);
    expect(find.text('Go again'), findsOneWidget);
  });

  testWidgets('conversation practice: view a scenario and rehearse it', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'nav_practice');
    await tapVisible(tester, find.text('Introducing yourself'));

    expect(find.text('Ways to start'), findsOneWidget);
    expect(find.text('Hi, I am [name].'), findsOneWidget);
    expect(find.text('Follow-up questions'), findsOneWidget);
    expect(find.text('Active listening tips'), findsOneWidget);

    await tapVisible(tester, find.text('Rehearse this'));
    expect(find.text('Nice to meet you!'), findsOneWidget);
    expect(find.text('Moment 1 of 2'), findsOneWidget);

    await tapVisible(tester, find.text('Nice to meet you too.'));
    await tapVisible(tester, find.text('Next'));
    expect(find.text('What do you do?'), findsOneWidget);

    await tapVisible(tester, find.text('Finish'));
    expect(find.text('Something to celebrate'), findsOneWidget);
    await tapVisible(tester, find.text('Continue'));

    expect(find.text('Ways to start'), findsOneWidget); // back on the scenario page
    expect(containerOf(tester).read(totalXpProvider), 5);
    expect(containerOf(tester).read(practiceSessionsProvider).single.refId, 'intro');
  });

  testWidgets('leaving a rehearsal early records nothing', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'nav_practice');
    await tapVisible(tester, find.text('Introducing yourself'));
    await tapVisible(tester, find.text('Rehearse this'));
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Ways to start'), findsOneWidget);
    expect(containerOf(tester).read(practiceSessionsProvider), isEmpty);
    expect(containerOf(tester).read(totalXpProvider), 0);
  });

  testWidgets('journal: create, edit, browse and delete an entry', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'nav_journal');
    expect(find.byKey(const Key('journal_empty')), findsOneWidget);
    expect(find.textContaining('only on this device'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('new_entry_fab')));
    await tester.enterText(
        find.byKey(const Key('journal_field_0')), 'Spoke to a neighbour');
    await tester.enterText(
        find.byKey(const Key('journal_field_4')), 'It was fine');
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(journalProvider).length, 1);

    await tapVisible(tester, find.text('Done'));
    expect(find.text('Something to celebrate'), findsOneWidget);
    await tapVisible(tester, find.text('Continue'));

    expect(find.text('Spoke to a neighbour'), findsOneWidget);
    expect(find.byKey(const Key('journal_empty')), findsNothing);

    await tapVisible(tester, find.text('Spoke to a neighbour'));
    await tester.enterText(
        find.byKey(const Key('journal_field_0')), 'Spoke to two neighbours');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Done'));

    expect(find.text('Spoke to two neighbours'), findsOneWidget);
    final saved = containerOf(tester).read(journalProvider).single;
    expect(saved.lessonsLearned, 'It was fine');

    await tapVisible(tester, find.byTooltip('Delete entry'));
    expect(find.text('Delete this entry?'), findsOneWidget);
    await tapVisible(tester, find.text('Delete'));
    expect(find.byKey(const Key('journal_empty')), findsOneWidget);
    expect(containerOf(tester).read(journalProvider), isEmpty);
  });

  testWidgets('journal: a new entry with no text is not saved', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'nav_journal');
    await tapVisible(tester, find.byKey(const Key('new_entry_fab')));
    await tapVisible(tester, find.text('Done'));
    expect(containerOf(tester).read(journalProvider), isEmpty);
    expect(find.byKey(const Key('journal_empty')), findsOneWidget);
  });

  testWidgets('journal: cancelling the delete confirmation keeps the entry',
      (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'nav_journal');
    await tapVisible(tester, find.byKey(const Key('new_entry_fab')));
    await tester.enterText(find.byKey(const Key('journal_field_1')), 'Nervous');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Done'));
    await tapVisible(tester, find.text('Continue'));

    await tapVisible(tester, find.byTooltip('Delete entry'));
    await tapVisible(tester, find.text('Cancel'));
    expect(find.text('Nervous'), findsOneWidget);
    expect(containerOf(tester).read(journalProvider).length, 1);
  });

  testWidgets('affirmations: favorite, add your own, filter and delete',
      (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'nav_practice');
    await tapVisible(tester, find.byKey(const Key('link_affirmations')));
    expect(find.text('Fixture affirmation text.'), findsWidgets);

    await tapVisible(tester, find.byTooltip('Add to favorites'));
    expect(containerOf(tester).read(affirmationPrefsProvider).favoriteIds.length, 1);

    await tester.enterText(
        find.byKey(const Key('affirmation_field')), 'I am learning');
    await tapVisible(tester, find.text('Add affirmation'));
    expect(find.text('I am learning'), findsWidgets);
    expect(containerOf(tester).read(customAffirmationsProvider).length, 1);

    await tapVisible(tester, find.widgetWithText(FilterChip, 'Staying calm'));
    expect(find.text('Nothing matches these themes yet.'), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(FilterChip, 'Staying calm'));

    await tapVisible(tester, find.byTooltip('Delete affirmation'));
    await tapVisible(tester, find.text('Delete'));
    expect(containerOf(tester).read(customAffirmationsProvider), isEmpty);
  });

  testWidgets('progress counts practice sessions and journal entries', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'nav_progress');
    expect(find.text('0 practice sessions completed'), findsOneWidget);
    expect(find.text('0 journal entries'), findsOneWidget);
  });
}

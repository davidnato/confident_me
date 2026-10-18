import 'package:confident_me/features/challenges/progress_controller.dart';
import 'package:confident_me/models/challenge_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

Future<void> openLibrary(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav_challenges')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('library lists challenges and filters by category', (tester) async {
    await pumpApp(tester);
    await openLibrary(tester);
    expect(find.text('Showing 6 of 6 challenges'), findsOneWidget);

    await tapVisible(
        tester, find.widgetWithText(ChoiceChip, 'Public speaking'));
    expect(find.text('Showing 1 of 6 challenges'), findsOneWidget);
    expect(find.text('Title speak_hard'), findsOneWidget);
    expect(find.text('Title conv_easy'), findsNothing);
  });

  testWidgets('library filters by difficulty and shows an empty state',
      (tester) async {
    await pumpApp(tester);
    await openLibrary(tester);

    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Intermediate'));
    expect(find.text('Showing 2 of 6 challenges'), findsOneWidget);

    await tapVisible(
        tester, find.widgetWithText(ChoiceChip, 'Handling awkward moments'));
    expect(find.text('No challenges match these filters.'), findsOneWidget);

    await tapVisible(tester, find.text('Clear filters'));
    expect(find.text('Showing 6 of 6 challenges'), findsOneWidget);
  });

  testWidgets('start, complete with a reflection, and no double completion',
      (tester) async {
    await pumpApp(tester);
    await openLibrary(tester);
    await tapVisible(tester, find.text('Title conv_easy'));

    expect(find.text('Start this challenge'), findsOneWidget);
    await tapVisible(tester, find.text('Start this challenge'));
    expect(find.text('Mark as completed'), findsOneWidget);

    await tapVisible(tester, find.text('Mark as completed'));
    await tester.enterText(find.byType(TextField), 'It went okay');
    await tapVisible(tester, find.text('Save and finish'));

    // The first completion earns an achievement, so a gentle dialog appears.
    expect(find.text('Something to celebrate'), findsOneWidget);
    expect(find.text('First small step'), findsOneWidget);
    await tapVisible(tester, find.text('Continue'));

    expect(find.byKey(const Key('completed_card')), findsOneWidget);
    final records = containerOf(tester).read(challengeProgressProvider);
    expect(records.length, 1);
    expect(records.single.status, ChallengeStatus.completed);
    expect(records.single.reflection, 'It went okay');
    expect(records.completedCount, 1);

    // No completion button remains, so a second completion is not possible.
    expect(find.text('Mark as completed'), findsNothing);
    expect(find.text('Do it again'), findsOneWidget);
  });

  testWidgets('"Make this easier" offers the smaller step and saves the choice',
      (tester) async {
    await pumpApp(tester);
    await openLibrary(tester);
    await tapVisible(tester, find.text('Title conv_easy'));

    await tapVisible(tester, find.text('Make this easier'));
    expect(find.text('A smaller version of conv_easy'), findsOneWidget);
    await tapVisible(tester, find.text('Use the smaller step'));

    expect(find.byKey(const Key('simplified_card')), findsOneWidget);
    final record = containerOf(tester).read(challengeProgressProvider).single;
    expect(record.simplified, isTrue);
  });

  testWidgets('skipping and postponing are recorded without judgement',
      (tester) async {
    await pumpApp(tester);
    await openLibrary(tester);
    await tapVisible(tester, find.text('Title conv_easy'));

    await tapVisible(tester, find.text('Skip for now'));
    expect(
      containerOf(tester).read(challengeProgressProvider).single.status,
      ChallengeStatus.skipped,
    );

    await tapVisible(tester, find.text('Postpone'));
    expect(
      containerOf(tester).read(challengeProgressProvider).single.status,
      ChallengeStatus.postponed,
    );
  });
}

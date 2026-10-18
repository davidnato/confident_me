import 'package:confident_me/features/gamification/gamification_providers.dart';
import 'package:confident_me/features/gamification/gamification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';

Future<void> openProgress(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav_progress')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('progress shows level, XP and achievements after a completion',
      (tester) async {
    await pumpApp(tester);
    await containerOf(tester)
        .read(gamificationServiceProvider)
        .completeChallenge(fixtureChallenges().first);
    await tester.pumpAndSettle();
    await openProgress(tester);

    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('10 of 100 XP to level 2'), findsOneWidget);
    expect(find.text('1 challenge completed'), findsOneWidget);
    expect(find.text('First small step'), findsOneWidget);
  });

  testWidgets('milestones: add, mark done for XP, and delete with confirmation',
      (tester) async {
    await pumpApp(tester);
    await openProgress(tester);

    await tester.enterText(find.byKey(const Key('milestone_field')), 'Spoke up');
    await tapVisible(tester, find.text('Add milestone'));
    expect(find.text('Spoke up'), findsOneWidget);

    await tapVisible(tester, find.textContaining('Mark done'));
    expect(find.text('Something to celebrate'), findsOneWidget);
    await tapVisible(tester, find.text('Continue'));
    expect(find.text('50 of 100 XP to level 2'), findsOneWidget);

    await tapVisible(tester, find.byIcon(Icons.delete_outline_rounded));
    expect(find.text('Delete this milestone?'), findsOneWidget);
    await tapVisible(tester, find.text('Delete'));
    expect(find.text('Spoke up'), findsNothing);
    expect(containerOf(tester).read(totalXpProvider), 50);
  });

  testWidgets('cancelling the delete confirmation keeps the milestone',
      (tester) async {
    await pumpApp(tester);
    await openProgress(tester);
    await tester.enterText(find.byKey(const Key('milestone_field')), 'Keep me');
    await tapVisible(tester, find.text('Add milestone'));

    await tapVisible(tester, find.byIcon(Icons.delete_outline_rounded));
    await tapVisible(tester, find.text('Cancel'));
    expect(find.text('Keep me'), findsOneWidget);
  });

  testWidgets('turning gamification off hides XP but keeps it saved',
      (tester) async {
    await pumpApp(tester);
    await containerOf(tester)
        .read(gamificationServiceProvider)
        .completeChallenge(fixtureChallenges().first);
    await tester.pumpAndSettle();
    await openProgress(tester);
    expect(find.byKey(const Key('level_title')), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('gamification_switch')));
    expect(find.byKey(const Key('level_title')), findsNothing);
    expect(find.text('Achievements'), findsNothing);
    expect(containerOf(tester).read(totalXpProvider), 10);

    await tapVisible(tester, find.byKey(const Key('gamification_switch')));
    expect(find.byKey(const Key('level_title')), findsOneWidget);
  });
}

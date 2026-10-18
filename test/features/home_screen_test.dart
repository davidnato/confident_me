import 'package:confident_me/features/challenges/progress_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('home shows today\'s challenge, affirmation and empty progress',
      (tester) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('todays_challenge_title')), findsOneWidget);
    expect(find.text('Try one small step'), findsOneWidget);
    expect(find.text('Fixture affirmation text.'), findsOneWidget);
    expect(find.text('0 challenges completed'), findsOneWidget);
    expect(find.byKey(const Key('home_level')), findsOneWidget);
  });

  testWidgets('"Try one small step" opens the suggested challenge',
      (tester) async {
    await pumpApp(tester);
    final title = tester
        .widget<Text>(find.byKey(const Key('todays_challenge_title')))
        .data!;
    await tapVisible(tester, find.text('Try one small step'));
    expect(find.text(title), findsOneWidget);
    expect(find.text('Start this challenge'), findsOneWidget);
  });

  testWidgets('completing a challenge updates the count and shows kind feedback',
      (tester) async {
    await pumpApp(tester);
    await containerOf(tester)
        .read(challengeProgressProvider.notifier)
        .complete('conv_easy');
    await tester.pumpAndSettle();

    expect(find.text('1 challenge completed'), findsOneWidget);
    expect(find.byKey(const Key('done_today_card')), findsOneWidget);
  });
}

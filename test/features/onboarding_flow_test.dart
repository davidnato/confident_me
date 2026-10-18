import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('new users see the welcome screen', (tester) async {
    await pumpApp(tester, withProfile: false);
    expect(find.text('ConfidentMe'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets('guest mode goes straight to home', (tester) async {
    await pumpApp(tester, withProfile: false);
    await tapVisible(tester, find.text('Continue as guest'));
    expect(find.byKey(const Key('home_greeting')), findsOneWidget);
  });

  testWidgets('full onboarding saves the name and shows it on home',
      (tester) async {
    await pumpApp(tester, withProfile: false);
    await tapVisible(tester, find.text('Get started'));

    await tester.enterText(find.byType(TextField), 'Sam');
    for (var i = 0; i < 4; i++) {
      await tapVisible(tester, find.text('Continue'));
    }
    await tapVisible(tester, find.text('Finish'));

    final greeting =
        tester.widget<Text>(find.byKey(const Key('home_greeting')));
    expect(greeting.data, endsWith(', Sam'));
  });

  testWidgets('skip setup works without answering anything', (tester) async {
    await pumpApp(tester, withProfile: false);
    await tapVisible(tester, find.text('Get started'));
    await tapVisible(tester, find.text('Skip setup'));
    expect(find.byKey(const Key('home_greeting')), findsOneWidget);
  });
}

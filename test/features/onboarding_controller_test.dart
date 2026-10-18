import 'package:confident_me/data/providers.dart';
import 'package:confident_me/features/onboarding/onboarding_controller.dart';
import 'package:confident_me/features/onboarding/profile_controller.dart';
import 'package:confident_me/models/challenge_category.dart';
import 'package:confident_me/models/difficulty.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> makeContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  // Keep the auto-dispose provider alive for the whole test.
  container.listen(onboardingControllerProvider, (_, __) {});
  return container;
}

void main() {
  test('starts with no profile', () async {
    final container = await makeContainer();
    expect(container.read(profileProvider), isNull);
  });

  test('toggles goals on and off and unselects focus on second tap', () async {
    final container = await makeContainer();
    final c = container.read(onboardingControllerProvider.notifier);

    c.toggleGoal(ChallengeCategory.publicSpeaking);
    expect(container.read(onboardingControllerProvider).goals,
        {ChallengeCategory.publicSpeaking});
    c.toggleGoal(ChallengeCategory.publicSpeaking);
    expect(container.read(onboardingControllerProvider).goals, isEmpty);

    c.setFocus('Handling awkward moments');
    expect(container.read(onboardingControllerProvider).focus,
        'Handling awkward moments');
    c.setFocus('Handling awkward moments');
    expect(container.read(onboardingControllerProvider).focus, isNull);
  });

  test('steps stay within bounds', () async {
    final container = await makeContainer();
    final c = container.read(onboardingControllerProvider.notifier);

    c.back();
    expect(container.read(onboardingControllerProvider).step, 0);
    for (var i = 0; i < 10; i++) {
      c.next();
    }
    expect(container.read(onboardingControllerProvider).step,
        OnboardingController.stepCount - 1);
  });

  test('finish saves a trimmed profile that persists across restarts', () async {
    final container = await makeContainer();
    final c = container.read(onboardingControllerProvider.notifier);
    c.setName('  Alex ');
    c.toggleGoal(ChallengeCategory.publicSpeaking);
    c.setSocialDifficulty(4);
    c.setSmallGoal('Say hello');
    await c.finish();

    final saved = container.read(profileProvider)!;
    expect(saved.displayName, 'Alex');
    expect(saved.selectedGoals, [ChallengeCategory.publicSpeaking]);
    expect(saved.preferredDifficulty, Difficulty.easy);

    // Simulate restarting the app: new container, same stored preferences.
    final prefs = await SharedPreferences.getInstance();
    final restarted = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restarted.dispose);
    expect(restarted.read(profileProvider)?.displayName, 'Alex');
    expect(restarted.read(profileProvider)?.id, saved.id);
  });

  test('comfortable users start at Intermediate', () {
    expect(OnboardingController.difficultyFor(1), Difficulty.medium);
    expect(OnboardingController.difficultyFor(2), Difficulty.medium);
    expect(OnboardingController.difficultyFor(3), Difficulty.easy);
    expect(OnboardingController.difficultyFor(5), Difficulty.easy);
  });

  test('continue as guest creates a blank profile; clear removes it', () async {
    final container = await makeContainer();
    await container.read(profileProvider.notifier).continueAsGuest();
    expect(container.read(profileProvider), isNotNull);
    expect(container.read(profileProvider)!.displayName, '');

    await container.read(profileProvider.notifier).clear();
    expect(container.read(profileProvider), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../models/challenge_category.dart';
import 'onboarding_controller.dart';
import 'onboarding_options.dart';
import 'profile_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(onboardingControllerProvider);
    _nameController = TextEditingController(text: initial.name);
    _goalController = TextEditingController(text: initial.smallGoal);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider.notifier).finish();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  /// "Skip setup" for new users saves blank answers (same as guest mode).
  /// When editing an existing profile it simply leaves without changes.
  Future<void> _skipAll() async {
    if (ref.read(profileProvider) != null) {
      context.go(AppRoutes.home);
      return;
    }
    await ref.read(profileProvider.notifier).continueAsGuest();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final editing = ref.watch(profileProvider) != null;
    final isLast = state.step == OnboardingController.stepCount - 1;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: state.step > 0
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: controller.back,
              )
            : null,
        title: Text(
          'Step ${state.step + 1} of ${OnboardingController.stepCount}',
        ),
        actions: [
          TextButton(
            onPressed: _skipAll,
            child: Text(editing ? 'Cancel' : 'Skip setup'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LinearProgressIndicator(
                value: (state.step + 1) / OnboardingController.stepCount,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                semanticsLabel: 'Setup progress',
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: SingleChildScrollView(
                      key: ValueKey(state.step),
                      padding: const EdgeInsets.all(24),
                      child: _buildPage(state, controller),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  if (state.step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.back,
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: isLast ? _finish : controller.next,
                      child: Text(isLast ? 'Finish' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingState s, OnboardingController c) {
    switch (s.step) {
      case 0:
        return _QuestionPage(
          title: 'What should we call you?',
          subtitle: 'Optional. A first name or nickname is plenty, or leave '
              'this blank.',
          child: TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            maxLength: 30,
            decoration: const InputDecoration(labelText: 'Name or nickname'),
            onChanged: c.setName,
          ),
        );
      case 1:
        return _QuestionPage(
          title: 'What situations would you like to feel more confident in?',
          subtitle: 'Choose any that fit, or none. You can change this later.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in ChallengeCategory.values)
                FilterChip(
                  label: Text(category.label),
                  selected: s.goals.contains(category),
                  onSelected: (_) => c.toggleGoal(category),
                ),
            ],
          ),
        );
      case 2:
        return _QuestionPage(
          title: 'What would you most like to improve?',
          subtitle: 'Pick one if something stands out. Tap again to unselect.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in improvementFocusOptions)
                ChoiceChip(
                  label: Text(option),
                  selected: s.focus == option,
                  onSelected: (_) => c.setFocus(option),
                ),
            ],
          ),
        );
      case 3:
        final label = socialDifficultyLabels[s.socialDifficulty - 1];
        return _QuestionPage(
          title: 'How challenging do social situations feel right now?',
          subtitle: 'There is no right answer. This only helps us suggest a '
              'gentle starting point, and it is not a score.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Slider(
                value: s.socialDifficulty.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: label,
                semanticFormatterCallback: (v) =>
                    socialDifficultyLabels[v.round() - 1],
                onChanged: (v) => c.setSocialDifficulty(v.round()),
              ),
              Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        );
      default:
        return _QuestionPage(
          title: 'What is one small goal you would like to achieve?',
          subtitle: 'Keep it small and kind. For example, one friendly hello.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _goalController,
                maxLines: 3,
                maxLength: 140,
                decoration: const InputDecoration(labelText: 'My small goal'),
                onChanged: c.setSmallGoal,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final idea in smallGoalSuggestions)
                    ActionChip(
                      label: Text(idea),
                      onPressed: () {
                        _goalController.text = idea;
                        c.setSmallGoal(idea);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
    }
  }
}

class _QuestionPage extends StatelessWidget {
  const _QuestionPage({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}

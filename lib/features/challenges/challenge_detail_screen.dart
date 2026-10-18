import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../models/challenge_progress.dart';
import '../../models/confidence_challenge.dart';
import '../../shared/widgets/async_states.dart';
import '../../shared/widgets/info_chip.dart';
import '../../shared/widgets/soft_card.dart';
import '../settings_controller.dart';
import 'challenge_providers.dart';
import 'progress_controller.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = ref.watch(challengeByIdProvider(challengeId));
    final loading = ref.watch(challengesProvider).isLoading;

    if (challenge == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Challenge')),
        body: loading
            ? const LoadingView()
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('We could not find that challenge.'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.go(AppRoutes.challenges),
                        child: const Text('Back to challenges'),
                      ),
                    ],
                  ),
                ),
              ),
      );
    }

    final theme = Theme.of(context);
    final latest = ref.watch(challengeProgressProvider).latestFor(challengeId);
    final showXp = ref.watch(settingsProvider).gamificationEnabled;
    final completed = latest?.status == ChallengeStatus.completed;
    final inProgress = latest?.status == ChallengeStatus.inProgress;
    final simplified = inProgress && latest!.simplified;

    return Scaffold(
      appBar: AppBar(title: const Text('Challenge')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                Text(
                  challenge.title,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(challenge.category.label, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoChip(label: challenge.difficulty.label),
                    InfoChip(
                      label: '${challenge.estimatedMinutes} min',
                      icon: Icons.schedule_rounded,
                    ),
                    if (showXp)
                      InfoChip(
                        label: '${challenge.xpReward} XP when completed',
                        icon: Icons.star_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(challenge.description, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                SoftCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.favorite_outline_rounded,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This is always your choice. You never have to '
                          'approach strangers, share private details, or do '
                          'anything that feels unsafe. Stop, simplify, or '
                          'skip at any time.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                if (simplified) ...[
                  const SizedBox(height: 12),
                  SoftCard(
                    child: Column(
                      key: const Key('simplified_card'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your smaller step',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(challenge.easierStep),
                      ],
                    ),
                  ),
                ],
                if (challenge.preparation.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _Section(
                    title: 'Getting ready',
                    child: Text(challenge.preparation),
                  ),
                ],
                const SizedBox(height: 20),
                _Section(
                  title: 'Steps',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < challenge.instructions.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(challenge.instructions[i])),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (challenge.reflectionPrompt.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Section(
                    title: 'Afterwards, you might reflect on',
                    child: Text(challenge.reflectionPrompt),
                  ),
                ],
                const SizedBox(height: 24),
                if (completed)
                  _CompletedCard(progress: latest!, challenge: challenge)
                else
                  _InProgressActions(challenge: challenge, inProgress: inProgress),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          child,
        ],
      );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _CompletedCard extends ConsumerWidget {
  const _CompletedCard({required this.progress, required this.challenge});

  final ChallengeProgress progress;
  final ConfidenceChallenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final date = progress.completedAt == null
        ? ''
        : MaterialLocalizations.of(context).formatMediumDate(progress.completedAt!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          child: Column(
            key: const Key('completed_card'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: theme.colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      date.isEmpty ? 'Completed' : 'Completed on $date',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('You took a step. That is what builds confidence.'),
              if (progress.reflection.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Your reflection', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(progress.reflection),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () async {
            await ref.read(challengeProgressProvider.notifier).start(challenge.id);
            if (context.mounted) {
              _snack(context, 'Started again. Go at your own pace.');
            }
          },
          child: const Text('Do it again'),
        ),
      ],
    );
  }
}

class _InProgressActions extends ConsumerWidget {
  const _InProgressActions({required this.challenge, required this.inProgress});

  final ConfidenceChallenge challenge;
  final bool inProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(challengeProgressProvider.notifier);

    Future<void> complete() async {
      final reflection = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _ReflectionSheet(prompt: challenge.reflectionPrompt),
      );
      if (reflection == null) return; // dismissed: not completed
      final recorded =
          await controller.complete(challenge.id, reflection: reflection);
      if (context.mounted && recorded) {
        _snack(context, 'Nicely done. Taking a step counts, however small.');
      }
    }

    Future<void> makeEasier() async {
      final useSmaller = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (_) => _EasierSheet(step: challenge.easierStep),
      );
      if (useSmaller == true) {
        await controller.setSimplified(challenge.id);
        if (context.mounted) {
          _snack(context, 'Smaller step chosen. That is a great place to start.');
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: inProgress
              ? complete
              : () async {
                  await controller.start(challenge.id);
                },
          child: Text(inProgress ? 'Mark as completed' : 'Start this challenge'),
        ),
        if (challenge.easierStep.isNotEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: makeEasier,
            child: const Text('Make this easier'),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () async {
                  await controller.skip(challenge.id);
                  if (context.mounted) {
                    _snack(context,
                        'No problem. We will suggest something gentler next.');
                  }
                },
                child: const Text('Skip for now'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () async {
                  await controller.postpone(challenge.id);
                  if (context.mounted) {
                    _snack(context, 'Okay. We will bring this back tomorrow.');
                  }
                },
                child: const Text('Postpone'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReflectionSheet extends StatefulWidget {
  const _ReflectionSheet({required this.prompt});

  final String prompt;

  @override
  State<_ReflectionSheet> createState() => _ReflectionSheetState();
}

class _ReflectionSheetState extends State<_ReflectionSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Well done for trying',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(widget.prompt.isEmpty
                ? 'Would you like to note anything about how it went? This is optional.'
                : '${widget.prompt} (Optional)'),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'My reflection'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_controller.text),
              child: const Text('Save and finish'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(''),
              child: const Text('Finish without writing'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EasierSheet extends StatelessWidget {
  const _EasierSheet({required this.step});

  final String step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'A smaller step',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(step, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Use the smaller step'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep the original'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/greeting.dart';
import '../../models/challenge_category.dart';
import '../../models/challenge_progress.dart';
import '../../models/confidence_challenge.dart';
import '../../shared/widgets/async_states.dart';
import '../../shared/widgets/info_chip.dart';
import '../../shared/widgets/soft_card.dart';
import '../affirmations/affirmation_providers.dart';
import '../challenges/challenge_providers.dart';
import '../challenges/progress_controller.dart';
import '../onboarding/profile_controller.dart';
import '../settings_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    if (profile == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider)();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                Text(
                  buildGreeting(now, profile.displayName),
                  key: const Key('home_greeting'),
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(AppConstants.philosophy, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 20),
                const _TodayCard(),
                const SizedBox(height: 16),
                const _AffirmationCard(),
                const SizedBox(height: 16),
                const _ProgressCard(),
                const SizedBox(height: 16),
                const _QuickLinks(),
                const SizedBox(height: 16),
                _FocusCard(
                  goals: profile.selectedGoals,
                  focus: profile.improvementFocus,
                  smallGoal: profile.smallGoal,
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.selfHelpDisclaimer,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(challengesProvider);
    final challenge = ref.watch(todaysChallengeProvider);
    final doneToday = ref.watch(completedTodayProvider);
    final showXp = ref.watch(settingsProvider).gamificationEnabled;

    return async.when(
      loading: () => const SoftCard(child: LoadingView()),
      error: (_, __) => SoftCard(
        child: ErrorView(
          message: 'Today\'s challenge could not be loaded.',
          onRetry: () => ref.invalidate(challengesProvider),
        ),
      ),
      data: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (doneToday != null) ...[
            SoftCard(
              child: Row(
                key: const Key('done_today_card'),
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: theme.colorScheme.tertiary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You took a small step today. That counts, and it is '
                      'enough. Another one is optional.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SoftCard(
            child: challenge == null
                ? const Text('No challenges are available right now.')
                : _TodayContent(challenge: challenge, showXp: showXp),
          ),
        ],
      ),
    );
  }
}

class _TodayContent extends StatelessWidget {
  const _TodayContent({required this.challenge, required this.showXp});

  final ConfidenceChallenge challenge;
  final bool showXp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's small step", style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        Text(
          challenge.title,
          key: const Key('todays_challenge_title'),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(challenge.description, style: theme.textTheme.bodyMedium),
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
              InfoChip(label: '${challenge.xpReward} XP', icon: Icons.star_rounded),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.go(AppRoutes.challengeDetail(challenge.id)),
          child: const Text('Try one small step'),
        ),
        const SizedBox(height: 8),
        Text(
          'You can skip, postpone, or make it easier whenever you like.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _AffirmationCard extends ConsumerWidget {
  const _AffirmationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final affirmation = ref.watch(todaysAffirmationProvider);
    if (affirmation == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's affirmation", style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  affirmation.text,
                  key: const Key('todays_affirmation'),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends ConsumerWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(challengeProgressProvider);
    final challenges = ref.watch(challengesProvider).valueOrNull ?? const [];
    final completed = progress.completedRecords;

    final byId = {for (final c in challenges) c.id: c};
    final explored = <ChallengeCategory>{
      for (final r in completed)
        if (byId[r.challengeId] != null) byId[r.challengeId]!.category,
    };
    final total = ChallengeCategory.values.length;
    final recent = completed.reversed.take(3).toList();

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your progress',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            '${completed.length} ${completed.length == 1 ? 'challenge' : 'challenges'} completed',
            key: const Key('completed_count'),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Categories explored: ${explored.length} of $total',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: explored.length / total,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            semanticsLabel: 'Categories explored',
            semanticsValue: '${explored.length} of $total',
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Text(
              'Your first small step is waiting whenever you feel ready.',
              style: theme.textTheme.bodyMedium,
            )
          else ...[
            Text('Recent', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final r in recent)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.check_rounded,
                        size: 18, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        byId[r.challengeId]?.title ?? 'A challenge',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickLink(
            icon: Icons.air_rounded,
            label: 'Breathing',
            onTap: () => context.go(AppRoutes.practice),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickLink(
            icon: Icons.forum_rounded,
            label: 'Practice',
            onTap: () => context.go(AppRoutes.practice),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickLink(
            icon: Icons.edit_note_rounded,
            label: 'Journal',
            onTap: () => context.go(AppRoutes.journal),
          ),
        ),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: theme.textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.goals,
    required this.focus,
    required this.smallGoal,
  });

  final List<ChallengeCategory> goals;
  final String? focus;
  final String smallGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your focus',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (goals.isEmpty)
            Text(
              'No focus areas chosen yet, and that is completely fine.',
              style: theme.textTheme.bodyMedium,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final g in goals) Chip(label: Text(g.label))],
            ),
          if (focus != null) ...[
            const SizedBox(height: 12),
            Text('Most like to improve: $focus', style: theme.textTheme.bodyMedium),
          ],
          if (smallGoal.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Your small goal: $smallGoal', style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push(AppRoutes.onboarding),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Change my answers'),
            ),
          ),
        ],
      ),
    );
  }
}

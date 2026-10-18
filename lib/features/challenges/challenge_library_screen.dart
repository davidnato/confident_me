import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/utils/clock.dart';
import '../../models/challenge_category.dart';
import '../../models/confidence_challenge.dart';
import '../../models/difficulty.dart';
import '../../shared/widgets/async_states.dart';
import '../../shared/widgets/info_chip.dart';
import '../../shared/widgets/soft_card.dart';
import '../../models/challenge_progress.dart';
import '../settings_controller.dart';
import 'challenge_filters.dart';
import 'challenge_providers.dart';
import 'challenge_status_label.dart';
import 'progress_controller.dart';

class ChallengeLibraryScreen extends ConsumerStatefulWidget {
  const ChallengeLibraryScreen({super.key});

  @override
  ConsumerState<ChallengeLibraryScreen> createState() =>
      _ChallengeLibraryScreenState();
}

class _ChallengeLibraryScreenState
    extends ConsumerState<ChallengeLibraryScreen> {
  ChallengeCategory? _category;
  Difficulty? _difficulty;

  void _clearFilters() => setState(() {
        _category = null;
        _difficulty = null;
      });

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(challengesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: SafeArea(
        child: async.when(
          loading: () => const LoadingView(),
          error: (_, __) => ErrorView(
            message: 'The challenge library could not be loaded.',
            onRetry: () => ref.invalidate(challengesProvider),
          ),
          data: _buildLibrary,
        ),
      ),
    );
  }

  Widget _buildLibrary(List<ConfidenceChallenge> all) {
    final theme = Theme.of(context);
    final filtered =
        filterChallenges(all, category: _category, difficulty: _difficulty);
    final progress = ref.watch(challengeProgressProvider);
    final now = ref.watch(clockProvider)();
    final showXp = ref.watch(settingsProvider).gamificationEnabled;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(
          'Pick anything that feels doable. You can skip, postpone, or make '
          'any challenge easier.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text('Category', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _ChipRow(
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _category == null,
              onSelected: (_) => setState(() => _category = null),
            ),
            for (final c in ChallengeCategory.values)
              ChoiceChip(
                label: Text(c.label),
                selected: _category == c,
                onSelected: (_) => setState(() => _category = c),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Difficulty', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _ChipRow(
          children: [
            ChoiceChip(
              label: const Text('Any'),
              selected: _difficulty == null,
              onSelected: (_) => setState(() => _difficulty = null),
            ),
            for (final d in Difficulty.values)
              ChoiceChip(
                label: Text(d.label),
                selected: _difficulty == d,
                onSelected: (_) => setState(() => _difficulty = d),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Text(
            'Showing ${filtered.length} of ${all.length} challenges',
            style: theme.textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          _EmptyResults(onClear: _clearFilters)
        else
          for (final challenge in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChallengeTile(
                challenge: challenge,
                statusLabel: challengeStatusLabel(
                  progress.latestFor(challenge.id),
                  now,
                ),
                showXp: showXp,
              ),
            ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: children,
      );
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => SoftCard(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 36),
            const SizedBox(height: 8),
            const Text(
              'No challenges match these filters.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onClear, child: const Text('Clear filters')),
          ],
        ),
      );
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({
    required this.challenge,
    required this.statusLabel,
    required this.showXp,
  });

  final ConfidenceChallenge challenge;
  final String? statusLabel;
  final bool showXp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.go(AppRoutes.challengeDetail(challenge.id)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                challenge.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                challenge.category.label,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                challenge.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
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
                      label: '${challenge.xpReward} XP',
                      icon: Icons.star_rounded,
                    ),
                  if (statusLabel != null)
                    InfoChip(
                      label: statusLabel!,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

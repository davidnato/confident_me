import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/constants/xp_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/clock.dart';
import '../../models/challenge_category.dart';
import '../../models/milestone.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/soft_card.dart';
import '../challenges/progress_controller.dart';
import '../journal/journal_controller.dart';
import '../practice/practice_sessions_controller.dart';
import '../gamification/achievement_catalog.dart';
import '../gamification/achievement_icons.dart';
import '../gamification/achievements_controller.dart';
import '../gamification/gamification_providers.dart';
import '../gamification/gamification_service.dart';
import '../gamification/level_calculator.dart';
import '../gamification/milestones_controller.dart';
import '../gamification/reward_feedback.dart';
import '../gamification/xp_ledger_controller.dart';
import '../settings_controller.dart';
import 'weekly_activity.dart';
import '../../models/challenge_progress.dart';

const _milestoneIdeas = <String>[
  'Started a conversation',
  'Shared an opinion',
  'Attended an event',
  'Asked for help',
  'Spoke in a meeting',
];

/// Progress: level and streak, a weekly activity calendar, categories explored,
/// personal milestones, achievements and XP history.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(
      settingsProvider.select((s) => s.gamificationEnabled),
    );
    final completed = ref.watch(challengeProgressProvider).completedCount;
    final practice = ref.watch(practiceSessionsProvider).length;
    final journal = ref.watch(journalProvider).where((e) => !e.isBlank).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            key: const Key('progress_open_settings'),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SoftCard(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: SwitchListTile(
                      key: const Key('gamification_switch'),
                      title: const Text('Show XP, levels and streaks'),
                      subtitle: const Text(
                        'Your progress is always saved. This only changes '
                        'what you see.',
                      ),
                      value: gamification,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .setGamificationEnabled(v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (gamification) ...[
                    const _LevelCard(),
                    const SizedBox(height: 16),
                  ],
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completed ${completed == 1 ? 'challenge' : 'challenges'} completed',
                          key: const Key('progress_completed'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$practice practice ${practice == 1 ? 'session' : 'sessions'} completed',
                          key: const Key('progress_practice'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$journal journal ${journal == 1 ? 'entry' : 'entries'}',
                          key: const Key('progress_journal'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _WeeklyCalendar(),
                  const SizedBox(height: 16),
                  const _CategoriesCard(),
                  const SizedBox(height: 16),
                  const _MilestonesSection(),
                  if (gamification) ...[
                    const SizedBox(height: 16),
                    const _AchievementsSection(),
                    const SizedBox(height: 16),
                    const _XpHistorySection(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends ConsumerWidget {
  const _LevelCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final LevelInfo level = ref.watch(levelInfoProvider);
    final streak = ref.watch(streakProvider);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Level ${level.level}',
            key: const Key('level_title'),
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: level.progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
            semanticsLabel: 'Progress to next level',
            semanticsValue: '${level.xpIntoLevel} of ${level.xpForNextLevel} XP',
          ),
          const SizedBox(height: 8),
          Text(
            '${level.xpIntoLevel} of ${level.xpForNextLevel} XP to level ${level.level + 1}',
            key: const Key('level_xp_text'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text('Lifetime XP: ${level.totalXp}', style: theme.textTheme.bodySmall),
          const Divider(height: 24),
          Text(
            streak.current == 0
                ? 'No current streak. Your next step starts a new one.'
                : 'Current streak: ${streak.current} ${streak.current == 1 ? 'day' : 'days'}',
            key: const Key('streak_text'),
            style: theme.textTheme.bodyLarge,
          ),
          Text(
            'Longest streak: ${streak.longest} ${streak.longest == 1 ? 'day' : 'days'}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'XP only ever goes up. Skipping a challenge or missing a day never '
            'takes anything away.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MilestonesSection extends ConsumerStatefulWidget {
  const _MilestonesSection();

  @override
  ConsumerState<_MilestonesSection> createState() => _MilestonesSectionState();
}

class _MilestonesSectionState extends ConsumerState<_MilestonesSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add(String title) async {
    final added = await ref.read(milestonesProvider.notifier).add(title);
    if (added != null) _controller.clear();
  }

  Future<void> _markDone(Milestone m) async {
    final result =
        await ref.read(gamificationServiceProvider).completeMilestone(m.id);
    if (!mounted) return;
    await showRewardFeedback(
      context,
      result,
      showGamification: ref.read(settingsProvider).gamificationEnabled,
      message: 'Milestone reached. That took courage.',
    );
  }

  Future<void> _delete(Milestone m) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete this milestone?',
      message: 'This removes "${m.title}" from your list. Any XP you already '
          'earned from it is kept.',
      confirmLabel: 'Delete',
    );
    if (ok) await ref.read(milestonesProvider.notifier).remove(m.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final milestones = ref.watch(milestonesProvider);
    final gamification = ref.watch(
      settingsProvider.select((s) => s.gamificationEnabled),
    );
    final reward = ref.watch(xpConfigProvider).milestone;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal milestones',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Write something you want to do or have done, in your own words.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('milestone_field'),
            controller: _controller,
            maxLength: MilestonesController.maxTitleLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'My milestone'),
            onSubmitted: _add,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
              onPressed: () => _add(_controller.text),
              child: const Text('Add milestone'),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final idea in _milestoneIdeas)
                ActionChip(
                  label: Text(idea),
                  onPressed: () => _controller.text = idea,
                ),
            ],
          ),
          if (milestones.isNotEmpty) const Divider(height: 24),
          for (final m in milestones)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    m.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: m.isCompleted
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.title, style: theme.textTheme.bodyLarge),
                        if (m.isCompleted)
                          Text(
                            'Done ${MaterialLocalizations.of(context).formatShortDate(m.completedAt!)}',
                            style: theme.textTheme.bodySmall,
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: TextButton(
                              onPressed: () => _markDone(m),
                              child: Text(gamification
                                  ? 'Mark done  (+$reward XP)'
                                  : 'Mark done'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete milestone',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _delete(m),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AchievementsSection extends ConsumerWidget {
  const _AchievementsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final earned = {
      for (final e in ref.watch(earnedAchievementsProvider)) e.achievementId: e,
    };
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${earned.length} of ${achievementCatalog.length} earned. These '
            'celebrate effort. They are not a score.',
            style: theme.textTheme.bodyMedium,
          ),
          if (earned.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Recent', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final e in (earned.values.toList()
                  ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt)))
                .take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${achievementById(e.achievementId)?.title ?? e.achievementId}'
                  '  ·  ${MaterialLocalizations.of(context).formatShortDate(e.earnedAt)}',
                  key: Key('recent_${e.achievementId}'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
          ],
          const SizedBox(height: 12),
          for (final def in achievementCatalog)
            Builder(builder: (context) {
              final a = def.achievement;
              final got = earned[a.id];
              return Semantics(
                label: '${a.title}, ${got != null ? 'earned' : 'not earned yet'}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        got != null ? achievementIcon(a.iconKey) : Icons.lock_outline_rounded,
                        color: got != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: theme.textTheme.titleSmall),
                            Text(
                              got != null ? a.description : a.requirement,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _XpHistorySection extends ConsumerWidget {
  const _XpHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recent = ref.watch(xpLedgerProvider).reversed.take(15).toList();
    final loc = MaterialLocalizations.of(context);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'XP history',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            Text('Nothing here yet.', style: theme.textTheme.bodyMedium)
          else
            for (final t in recent)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.description.isEmpty ? t.reason.id : t.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('+${t.amount} XP · ${loc.formatShortDate(t.createdAt)}',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _WeeklyCalendar extends ConsumerWidget {
  const _WeeklyCalendar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    final now = ref.watch(clockProvider)();
    final days = weeklyActivity(ref.watch(activityEventsProvider), now);
    final total = days.fold<int>(0, (sum, d) => sum + d.count);

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'Nothing yet this week, and that is okay.'
                : '$total ${total == 1 ? 'step' : 'steps'} in the last 7 days.',
            key: const Key('week_total'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: _DayCell(
                    key: Key('day_cell_$i'),
                    day: days[i],
                    isToday: i == days.length - 1,
                    label: loc.narrowWeekdays[days[i].day.weekday % 7],
                    semantics:
                        '${loc.formatMediumDate(days[i].day)}: ${days[i].count == 0 ? 'no activity' : '${days[i].count} ${days[i].count == 1 ? 'step' : 'steps'}'}',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Steps include challenges, practice, journal entries and milestones. '
            'There is no pressure to fill every day.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.day,
    required this.isToday,
    required this.label,
    required this.semantics,
  });

  final DayActivity day;
  final bool isToday;
  final String label;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: day.active ? scheme.primary : Colors.transparent,
              border: Border.all(
                color: isToday ? scheme.primary : scheme.outlineVariant,
                width: isToday ? 2 : 1,
              ),
            ),
            child: day.active
                ? Text(
                    '${day.count}',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _CategoriesCard extends ConsumerWidget {
  const _CategoriesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final explored = ref.watch(exploredCategoriesProvider);
    final total = ChallengeCategory.values.length;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories explored',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${explored.length} of $total',
            key: const Key('categories_explored'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in ChallengeCategory.values)
                Chip(
                  avatar: explored.contains(c)
                      ? const Icon(Icons.check_rounded, size: 18)
                      : null,
                  label: Text(c.label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

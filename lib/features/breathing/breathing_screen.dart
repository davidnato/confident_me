import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/soft_card.dart';
import '../settings_controller.dart';
import 'breathing_controller.dart';
import 'breathing_timeline.dart';

class BreathingScreen extends ConsumerStatefulWidget {
  const BreathingScreen({super.key});

  @override
  ConsumerState<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends ConsumerState<BreathingScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    // The ticker reports real elapsed time on every frame. The controller turns
    // that into the breathing phase, so the animation cannot drift.
    _ticker = createTicker(
      (elapsed) => ref.read(breathingControllerProvider.notifier).tick(elapsed),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _syncTicker(BreathingStatus status) {
    if (status == BreathingStatus.running) {
      if (_ticker.isActive) _ticker.stop();
      _ticker.start(); // elapsed restarts at zero for each run
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BreathingStatus>(
      breathingControllerProvider.select((s) => s.status),
      (previous, next) => _syncTicker(next),
    );
    final status = ref.watch(breathingControllerProvider.select((s) => s.status));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Breathing')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BreathingVisual(),
                  const SizedBox(height: 16),
                  _Controls(status: status),
                  const SizedBox(height: 16),
                  if (status == BreathingStatus.completed)
                    const _CompletionCard()
                  else if (status == BreathingStatus.idle)
                    const _SettingsCard(),
                  const SizedBox(height: 16),
                  Text(
                    'Slow breathing can help some people feel calmer, but it '
                    'does not work the same way for everyone and it is not a '
                    'treatment. If you feel dizzy or uncomfortable, stop and '
                    'return to normal breathing.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatClock(Duration d) {
  final seconds = d.inSeconds < 0 ? 0 : d.inSeconds;
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

class _BreathingVisual extends ConsumerWidget {
  const _BreathingVisual();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(breathingControllerProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final active = state.status == BreathingStatus.running ||
        state.status == BreathingStatus.paused;
    final frame = breathingFrameAt(state.pattern, state.elapsed);

    String title;
    String? detail;
    switch (state.status) {
      case BreathingStatus.idle:
        title = 'Ready when you are';
      case BreathingStatus.completed:
        title = 'Well done';
      case BreathingStatus.running:
      case BreathingStatus.paused:
        title = switch (frame.phase) {
          BreathingPhase.inhale => 'Breathe in',
          BreathingPhase.hold => 'Hold gently',
          BreathingPhase.exhale => 'Breathe out',
        };
        detail = state.status == BreathingStatus.paused
            ? 'Paused'
            : '${frame.secondsLeftInPhase}';
    }

    // With "reduce motion" on, the circle stays still and the words do the work.
    final scale = !active ? 0.5 : (reduceMotion ? 0.7 : frame.circleScale);
    const maxSize = 240.0;
    const minSize = 120.0;
    final size = minSize + (maxSize - minSize) * scale;

    return Column(
      children: [
        SizedBox(
          height: maxSize + 8,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: maxSize,
                  height: maxSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant, width: 2),
                  ),
                ),
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primaryContainer,
                  ),
                ),
                Semantics(
                  liveRegion: true,
                  label: detail == null ? title : '$title, $detail',
                  excludeSemantics: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        key: const Key('breathing_phase'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      if (detail != null)
                        Text(
                          detail,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          active
              ? '${_formatClock(state.remaining)} left'
              : 'Session: ${_formatClock(state.total)}',
          key: const Key('breathing_timer'),
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.status});

  final BreathingStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.read(breathingControllerProvider.notifier);
    switch (status) {
      case BreathingStatus.idle:
      case BreathingStatus.completed:
        return FilledButton(
          onPressed: c.start,
          child: Text(status == BreathingStatus.completed ? 'Go again' : 'Start'),
        );
      case BreathingStatus.running:
      case BreathingStatus.paused:
        return Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: status == BreathingStatus.running ? c.pause : c.resume,
                child: Text(status == BreathingStatus.running ? 'Pause' : 'Resume'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(onPressed: c.stop, child: const Text('Stop')),
            ),
          ],
        );
    }
  }
}

class _CompletionCard extends ConsumerWidget {
  const _CompletionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reward = ref.watch(breathingControllerProvider.select((s) => s.reward));
    final gamification = ref.watch(settingsProvider).gamificationEnabled;
    return SoftCard(
      child: Column(
        key: const Key('breathing_complete'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You took a moment for yourself.',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text('Notice how you feel right now, without judging it.'),
          if (gamification && reward != null && reward.xpAwarded > 0) ...[
            const SizedBox(height: 8),
            Text('+${reward.xpAwarded} XP'),
          ],
        ],
      ),
    );
  }
}

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(breathingControllerProvider);
    final c = ref.read(breathingControllerProvider.notifier);
    final p = state.pattern;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pattern',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in breathingPresets)
                ChoiceChip(
                  label: Text(preset.name),
                  selected: p.sameTimingAs(preset),
                  onSelected: (_) => c.selectPreset(preset),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _Stepper(
            label: 'Breathe in',
            value: p.inhaleSeconds,
            min: BreathingController.minInhale,
            max: BreathingController.maxInhale,
            onChanged: c.setInhale,
          ),
          _Stepper(
            label: 'Hold (0 to skip)',
            value: p.holdSeconds,
            min: BreathingController.minHold,
            max: BreathingController.maxHold,
            onChanged: c.setHold,
          ),
          _Stepper(
            label: 'Breathe out',
            value: p.exhaleSeconds,
            min: BreathingController.minExhale,
            max: BreathingController.maxExhale,
            onChanged: c.setExhale,
          ),
          const Divider(height: 24),
          Text('Session length',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final minutes in const [1, 2, 3, 5])
                ChoiceChip(
                  label: Text('$minutes min'),
                  selected: state.totalSeconds == minutes * 60,
                  onSelected: (_) => c.setTotalSeconds(minutes * 60),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          tooltip: 'Decrease $label',
          icon: const Icon(Icons.remove_circle_outline_rounded),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 40,
          child: Text('$value s', textAlign: TextAlign.center),
        ),
        IconButton(
          tooltip: 'Increase $label',
          icon: const Icon(Icons.add_circle_outline_rounded),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

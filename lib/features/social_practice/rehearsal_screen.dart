import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../models/practice_session.dart';
import '../../shared/widgets/async_states.dart';
import '../../shared/widgets/soft_card.dart';
import '../gamification/gamification_service.dart';
import '../gamification/reward_feedback.dart';
import '../settings_controller.dart';
import 'scenario_providers.dart';
import 'scenario_screen.dart';

/// Step-by-step rehearsal. Nothing typed here is saved or sent anywhere, and
/// leaving early is always fine (it just does not count as a finished session).
class RehearsalScreen extends ConsumerStatefulWidget {
  const RehearsalScreen({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  ConsumerState<RehearsalScreen> createState() => _RehearsalScreenState();
}

class _RehearsalScreenState extends ConsumerState<RehearsalScreen> {
  final _controller = TextEditingController();
  final String _sessionId = const Uuid().v4();
  int _index = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish(String title, int promptCount) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final result = await ref.read(gamificationServiceProvider).completePracticeSession(
          kind: PracticeKind.social,
          durationSeconds: 0,
          description: 'Practice: $title',
          refId: widget.scenarioId,
          sessionId: _sessionId,
        );
    if (!mounted) return;
    await showRewardFeedback(
      context,
      result,
      showGamification: ref.read(settingsProvider).gamificationEnabled,
      message: 'You rehearsed all $promptCount moments. Practice builds comfort.',
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scenario = ref.watch(scenarioByIdProvider(widget.scenarioId));
    if (scenario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rehearse')),
        body: const LoadingView(),
      );
    }
    final theme = Theme.of(context);
    final prompts = scenario.prompts;
    final prompt = prompts[_index];
    final isLast = _index == prompts.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text('Moment ${_index + 1} of ${prompts.length}')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(scenario.title, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('They say', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(
                          prompt.heard,
                          key: const Key('rehearsal_heard'),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('rehearsal_field'),
                    controller: _controller,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Your reply (or say it aloud)',
                      helperText: 'Optional. What you type is not saved.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (prompt.suggestions.isNotEmpty) ...[
                    Text('Ideas to try', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final idea in prompt.suggestions)
                          ActionChip(
                            label: Text(idea),
                            onPressed: () => _controller.text = idea,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _finishing
                        ? null
                        : () {
                            if (isLast) {
                              _finish(scenario.title, prompts.length);
                            } else {
                              setState(() {
                                _index++;
                                _controller.clear();
                              });
                            }
                          },
                    child: Text(isLast ? 'Finish' : 'Next'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$scenarioDisclaimer You can leave at any time.',
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

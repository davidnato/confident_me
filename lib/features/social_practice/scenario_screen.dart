import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../shared/widgets/async_states.dart';
import '../../shared/widgets/soft_card.dart';
import 'scenario_providers.dart';

const scenarioDisclaimer =
    'These are examples to help you rehearse. Real people respond in all kinds '
    'of ways, so nothing here predicts how a real conversation will go.';

class ScenarioScreen extends ConsumerWidget {
  const ScenarioScreen({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenario = ref.watch(scenarioByIdProvider(scenarioId));
    final loading = ref.watch(scenariosProvider).isLoading;
    if (scenario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Practice')),
        body: loading
            ? const LoadingView()
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('We could not find that scenario.'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.go(AppRoutes.practice),
                        child: const Text('Back to practice'),
                      ),
                    ],
                  ),
                ),
              ),
      );
    }

    final theme = Theme.of(context);
    Widget section(String title, List<String> items) => items.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2, right: 8),
                            child: Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          ),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                Text(
                  scenario.title,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(scenario.description, style: theme.textTheme.bodyLarge),
                if (scenario.setting.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Setting: ${scenario.setting}',
                      style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 16),
                if (scenario.prompts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FilledButton(
                      onPressed: () => context
                          .go(AppRoutes.scenarioRehearse(scenario.id)),
                      child: const Text('Rehearse this'),
                    ),
                  ),
                section('Ways to start', scenario.conversationStarters),
                section('Follow-up questions', scenario.followUpQuestions),
                section('Active listening tips', scenario.listeningTips),
                Text(scenarioDisclaimer,
                    style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

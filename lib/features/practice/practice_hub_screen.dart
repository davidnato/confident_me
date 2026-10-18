import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../shared/widgets/async_states.dart';
import '../../shared/widgets/soft_card.dart';
import '../social_practice/scenario_providers.dart';

class PracticeHubScreen extends ConsumerWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scenarios = ref.watch(scenariosProvider);

    Widget linkCard(IconData icon, String title, String subtitle, String route,
            {Key? key}) =>
        SoftCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(24),
            onTap: () => context.go(route),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(subtitle, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                linkCard(Icons.air_rounded, 'Breathing exercise',
                    'Slow, guided breathing at your own pace.',
                    AppRoutes.breathing,
                    key: const Key('link_breathing')),
                const SizedBox(height: 12),
                linkCard(Icons.favorite_outline_rounded, 'Affirmations',
                    'Realistic, encouraging thoughts. Add your own.',
                    AppRoutes.affirmations,
                    key: const Key('link_affirmations')),
                const SizedBox(height: 24),
                Text('Conversation practice',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Rehearse common situations in a private, low-pressure way.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                scenarios.when(
                  loading: () => const LoadingView(),
                  error: (_, __) => ErrorView(
                    message: 'The practice scenarios could not be loaded.',
                    onRetry: () => ref.invalidate(scenariosProvider),
                  ),
                  data: (list) => Column(
                    children: [
                      for (final s in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: linkCard(
                            Icons.forum_outlined,
                            s.title,
                            s.setting.isEmpty ? s.description : s.setting,
                            AppRoutes.scenario(s.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

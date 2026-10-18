import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routing/app_router.dart';
import 'profile_controller.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primaryContainer, scheme.surface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      label: 'ConfidentMe logo',
                      child: Container(
                        alignment: Alignment.center,
                        height: 88,
                        width: 88,
                        margin: const EdgeInsets.symmetric(horizontal: 100),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Icon(
                          Icons.spa_rounded,
                          size: 48,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.tagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome. This is a calm, private space to take small '
                      'steps toward feeling more comfortable around people. '
                      'You set the pace.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    const _HowItWorksRow(
                      icon: Icons.flag_rounded,
                      title: 'Try one small step',
                      text: 'Pick from gentle challenges. Skip, postpone, or '
                          'make any of them easier.',
                    ),
                    const _HowItWorksRow(
                      icon: Icons.air_rounded,
                      title: 'Practise and breathe',
                      text: 'Rehearse conversations and use calming breathing '
                          'exercises.',
                    ),
                    const _HowItWorksRow(
                      icon: Icons.edit_note_rounded,
                      title: 'Reflect and notice growth',
                      text: 'Write down what you learned and see your effort '
                          'add up.',
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.onboarding),
                      child: const Text('Get started'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(profileProvider.notifier)
                          .continueAsGuest(),
                      child: const Text('Continue as guest'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 18, color: scheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppConstants.privacyShort,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.selfHelpDisclaimer,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HowItWorksRow extends StatelessWidget {
  const _HowItWorksRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.tertiaryContainer,
            child: Icon(icon, color: theme.colorScheme.onTertiaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

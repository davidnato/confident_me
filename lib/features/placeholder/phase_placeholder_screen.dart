import 'package:flutter/material.dart';

import '../../shared/widgets/soft_card.dart';

/// Honest stand-in for tabs that are built in later phases. It has no buttons,
/// so nothing pretends to work. Each one is replaced in its own phase.
class PhasePlaceholderScreen extends StatelessWidget {
  const PhasePlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.phase,
    required this.description,
  });

  final String title;
  final IconData icon;
  final int phase;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SoftCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Coming in build phase $phase',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium,
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

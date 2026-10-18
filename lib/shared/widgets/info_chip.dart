import 'package:flutter/material.dart';

/// Small pill used for difficulty, duration, XP and status labels.
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: scheme.onSecondaryContainer),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'achievement_icons.dart';
import 'gamification_service.dart';

/// Gentle feedback after completing something.
///
/// With gamification on, a level-up or new achievement gets a small dialog
/// (no flashing or confetti); otherwise a snackbar. With it off, only the
/// plain message is shown.
Future<void> showRewardFeedback(
  BuildContext context,
  RewardResult result, {
  required bool showGamification,
  required String message,
}) async {
  if (!result.recorded) return;
  final celebrate =
      showGamification && (result.leveledUp || result.newAchievements.isNotEmpty);

  if (!celebrate) {
    final xpText = showGamification && result.xpAwarded > 0
        ? ' +${result.xpAwarded} XP'
        : '';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$message$xpText')));
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: Text(
          result.leveledUp
              ? 'You reached level ${result.levelAfter.level}'
              : 'Something to celebrate',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (result.xpAwarded > 0) ...[
                const SizedBox(height: 8),
                Text('+${result.xpAwarded} XP',
                    style: theme.textTheme.titleMedium),
              ],
              if (result.leveledUp) ...[
                const SizedBox(height: 8),
                const Text('Your effort is adding up.'),
              ],
              for (final a in result.newAchievements) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(achievementIcon(a.iconKey),
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: theme.textTheme.titleSmall),
                          Text(a.description),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../models/journal_entry.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/soft_card.dart';
import 'journal_controller.dart';

String journalExcerpt(JournalEntry e) {
  for (final text in [
    e.situation,
    e.feelings,
    e.actualOutcome,
    e.lessonsLearned,
    e.anticipatedOutcome,
    e.nextStep,
  ]) {
    final t = text.trim();
    if (t.isNotEmpty) return t;
  }
  return 'Empty entry';
}

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entries = ref.watch(journalProvider);
    final loc = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new_entry_fab'),
        onPressed: () => context.go(AppRoutes.journalNew),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New entry'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
              children: [
                SoftCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your journal is private. Entries are stored only on '
                          'this device, in a database inside the app, and are '
                          'not sent anywhere. Uninstalling the app or clearing '
                          'its data deletes them.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (entries.isEmpty)
                  SoftCard(
                    child: Column(
                      key: const Key('journal_empty'),
                      children: [
                        const Icon(Icons.edit_note_rounded, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'Nothing here yet.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Writing about what happened, what you feared, and '
                          'what you learned can help you notice your progress. '
                          'Start whenever you like.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  for (final e in entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SoftCard(
                        padding: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => context.go(AppRoutes.journalEdit(e.id)),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(loc.formatMediumDate(e.createdAt),
                                          style: theme.textTheme.labelLarge),
                                      const SizedBox(height: 4),
                                      Text(
                                        journalExcerpt(e),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete entry',
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  onPressed: () async {
                                    final ok = await confirmDialog(
                                      context,
                                      title: 'Delete this entry?',
                                      message:
                                          'This permanently deletes the entry from this device.',
                                      confirmLabel: 'Delete',
                                    );
                                    if (ok) {
                                      await ref
                                          .read(journalProvider.notifier)
                                          .delete(e.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
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

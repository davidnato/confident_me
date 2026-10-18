import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/routing/app_router.dart';
import '../../core/utils/clock.dart';
import '../../models/journal_entry.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../gamification/gamification_service.dart';
import '../gamification/reward_feedback.dart';
import '../settings_controller.dart';
import 'journal_controller.dart';

const journalPrompts = <String>[
  'What went better than you expected?',
  'What did you do even though it felt difficult?',
  'What would you tell a friend in the same situation?',
  'What is one thing you learned?',
];

/// Creates or edits one entry. Changes are saved as you type, so nothing is
/// lost if you leave the screen. A new entry is only saved once it has text.
class JournalEditorScreen extends ConsumerStatefulWidget {
  const JournalEditorScreen({super.key, this.entryId});

  /// null means a new entry.
  final String? entryId;

  @override
  ConsumerState<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  static const _labels = <String>[
    'What happened?',
    'What did I feel?',
    'What did I fear might happen?',
    'What actually happened?',
    'What did I learn?',
    'What would I like to try next time?',
  ];

  late final String _id;
  late final DateTime _createdAt;
  late final List<TextEditingController> _fields;
  late final JournalController _journal;
  bool _persisted = false;
  bool _missing = false;

  @override
  void initState() {
    super.initState();
    _journal = ref.read(journalProvider.notifier);
    final existing =
        widget.entryId == null ? null : _journal.find(widget.entryId!);
    _missing = widget.entryId != null && existing == null;
    _persisted = existing != null;
    _id = existing?.id ?? const Uuid().v4();
    _createdAt = existing?.createdAt ?? ref.read(clockProvider)();
    _fields = [
      TextEditingController(text: existing?.situation ?? ''),
      TextEditingController(text: existing?.feelings ?? ''),
      TextEditingController(text: existing?.anticipatedOutcome ?? ''),
      TextEditingController(text: existing?.actualOutcome ?? ''),
      TextEditingController(text: existing?.lessonsLearned ?? ''),
      TextEditingController(text: existing?.nextStep ?? ''),
    ];
  }

  @override
  void dispose() {
    for (final f in _fields) {
      f.dispose();
    }
    super.dispose();
  }

  JournalEntry _current() => JournalEntry(
        id: _id,
        createdAt: _createdAt,
        updatedAt: _createdAt,
        situation: _fields[0].text,
        feelings: _fields[1].text,
        anticipatedOutcome: _fields[2].text,
        actualOutcome: _fields[3].text,
        lessonsLearned: _fields[4].text,
        nextStep: _fields[5].text,
      );

  Future<void> _save() async {
    final entry = _current();
    if (!_persisted && entry.isBlank) return;
    _persisted = true;
    await _journal.save(entry);
  }

  Future<void> _done() async {
    await _save();
    if (!mounted) return;
    final result = await ref.read(gamificationServiceProvider).afterJournalSaved();
    if (!mounted) return;
    await showRewardFeedback(
      context,
      result,
      showGamification: ref.read(settingsProvider).gamificationEnabled,
      message: 'Your entry is saved.',
    );
    if (mounted) context.go(AppRoutes.journal);
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Delete this entry?',
      message: 'This permanently deletes the entry from this device.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    await _journal.delete(_id);
    if (mounted) context.go(AppRoutes.journal);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_missing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Journal entry')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('We could not find that entry.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.journal),
                  child: const Text('Back to journal'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entryId == null ? 'New entry' : 'Edit entry'),
        actions: [
          if (_persisted)
            IconButton(
              tooltip: 'Delete entry',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
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
                  Text(
                    'Write as much or as little as you like. Every part is '
                    'optional, and your words save automatically.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    title: const Text('Need a nudge? Optional prompts'),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final p in journalPrompts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(p),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _fields.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        key: Key('journal_field_$i'),
                        controller: _fields[i],
                        minLines: 2,
                        maxLines: 6,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(labelText: _labels[i]),
                        onChanged: (_) => _save(),
                      ),
                    ),
                  FilledButton(onPressed: _done, child: const Text('Done')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

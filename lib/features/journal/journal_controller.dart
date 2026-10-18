import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/clock.dart';
import '../../data/providers.dart';
import '../../models/journal_entry.dart';

/// Journal entries, newest first, stored in Hive on this device.
class JournalController extends Notifier<List<JournalEntry>> {
  @override
  List<JournalEntry> build() =>
      _sorted(ref.read(journalStoreProvider).loadAll());

  static List<JournalEntry> _sorted(List<JournalEntry> list) =>
      [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  JournalEntry? find(String id) {
    for (final e in state) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Creates the entry or updates it if the id already exists.
  Future<JournalEntry> save(JournalEntry entry) async {
    final saved = entry.copyWith(updatedAt: ref.read(clockProvider)());
    final exists = state.any((e) => e.id == saved.id);
    state = _sorted([
      if (exists)
        for (final e in state) e.id == saved.id ? saved : e
      else ...[...state, saved],
    ]);
    await ref.read(journalStoreProvider).put(saved);
    return saved;
  }

  Future<void> delete(String id) async {
    state = [for (final e in state) if (e.id != id) e];
    await ref.read(journalStoreProvider).delete(id);
  }

  Future<void> clearAll() async {
    state = [];
    await ref.read(journalStoreProvider).clear();
  }
}

final journalProvider =
    NotifierProvider<JournalController, List<JournalEntry>>(
  JournalController.new,
);

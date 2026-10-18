import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../models/practice_session.dart';

class PracticeSessionsController extends Notifier<List<PracticeSession>> {
  @override
  List<PracticeSession> build() =>
      ref.read(practiceStoreProvider).loadAll()
        ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

  /// Returns false (and saves nothing) if a session with this id exists.
  Future<bool> add(PracticeSession session) async {
    if (state.any((s) => s.id == session.id)) return false;
    state = [...state, session];
    await ref.read(practiceStoreProvider).put(session);
    return true;
  }

  Future<void> recordXp(String id, int xp) async {
    for (final s in state) {
      if (s.id == id) {
        final updated = s.withXp(xp);
        state = [for (final x in state) x.id == id ? updated : x];
        await ref.read(practiceStoreProvider).put(updated);
        return;
      }
    }
  }

  Future<void> clearAll() async {
    state = [];
    await ref.read(practiceStoreProvider).clear();
  }
}

final practiceSessionsProvider =
    NotifierProvider<PracticeSessionsController, List<PracticeSession>>(
  PracticeSessionsController.new,
);

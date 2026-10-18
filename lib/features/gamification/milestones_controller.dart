import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/clock.dart';
import '../../data/providers.dart';
import '../../models/milestone.dart';

class MilestonesController extends Notifier<List<Milestone>> {
  static const maxTitleLength = 100;

  @override
  List<Milestone> build() => ref.read(milestoneStoreProvider).load();

  Future<void> _write(List<Milestone> next) async {
    state = next;
    await ref.read(milestoneStoreProvider).save(next);
  }

  Milestone? _find(String id) {
    for (final m in state) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Returns null if the title is blank.
  Future<Milestone?> add(String title) async {
    var text = title.trim();
    if (text.isEmpty) return null;
    if (text.length > maxTitleLength) text = text.substring(0, maxTitleLength);
    final milestone = Milestone(
      id: const Uuid().v4(),
      title: text,
      createdAt: ref.read(clockProvider)(),
    );
    await _write([...state, milestone]);
    return milestone;
  }

  /// Marks a milestone done. Returns null if it is missing or already done.
  Future<Milestone?> markDone(String id) async {
    final m = _find(id);
    if (m == null || m.isCompleted) return null;
    final done = m.copyWith(completedAt: ref.read(clockProvider)());
    await _write([for (final x in state) x.id == id ? done : x]);
    return done;
  }

  Future<void> recordXp(String id, int xp) async {
    final m = _find(id);
    if (m == null) return;
    await _write([for (final x in state) x.id == id ? m.copyWith(xpAwarded: xp) : x]);
  }

  /// Removes the milestone from the list. XP already earned is kept.
  Future<void> remove(String id) =>
      _write([for (final m in state) if (m.id != id) m]);

  Future<void> clearAll() async {
    state = [];
    await ref.read(milestoneStoreProvider).clear();
  }
}

final milestonesProvider =
    NotifierProvider<MilestonesController, List<Milestone>>(
  MilestonesController.new,
);

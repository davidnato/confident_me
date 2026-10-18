import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../models/earned_achievement.dart';

class EarnedAchievementsController extends Notifier<List<EarnedAchievement>> {
  @override
  List<EarnedAchievement> build() => ref.read(achievementStoreProvider).load();

  /// Records any of [ids] not already earned and returns just the new ones.
  Future<List<String>> grant(Set<String> ids, {required DateTime at}) async {
    final have = {for (final e in state) e.achievementId};
    final fresh = [for (final id in ids) if (!have.contains(id)) id];
    if (fresh.isEmpty) return const [];
    final next = [
      ...state,
      for (final id in fresh) EarnedAchievement(achievementId: id, earnedAt: at),
    ];
    state = next;
    await ref.read(achievementStoreProvider).save(next);
    return fresh;
  }

  Future<void> clearAll() async {
    state = [];
    await ref.read(achievementStoreProvider).clear();
  }
}

final earnedAchievementsProvider =
    NotifierProvider<EarnedAchievementsController, List<EarnedAchievement>>(
  EarnedAchievementsController.new,
);

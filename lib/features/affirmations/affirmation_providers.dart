import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/clock.dart';
import '../../core/utils/stable_hash.dart';
import '../../data/providers.dart';
import '../../models/affirmation.dart';

final affirmationsProvider = FutureProvider<List<Affirmation>>(
  (ref) => ref.watch(affirmationRepositoryProvider).loadAll(),
);

/// Same affirmation all day, a different one tomorrow.
Affirmation? pickDailyAffirmation(List<Affirmation> all, DateTime now) {
  if (all.isEmpty) return null;
  final index = stableHash('${now.year}-${now.month}-${now.day}') % all.length;
  return all[index];
}

final todaysAffirmationProvider = Provider<Affirmation?>((ref) {
  final all = ref.watch(affirmationsProvider).valueOrNull;
  if (all == null) return null;
  return pickDailyAffirmation(all, ref.watch(clockProvider)());
});

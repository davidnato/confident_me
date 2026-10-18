import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../models/social_scenario.dart';

final scenariosProvider = FutureProvider<List<SocialScenario>>(
  (ref) => ref.watch(scenarioRepositoryProvider).loadAll(),
);

final scenarioByIdProvider = Provider.family<SocialScenario?, String>((ref, id) {
  final all = ref.watch(scenariosProvider).valueOrNull;
  if (all == null) return null;
  for (final s in all) {
    if (s.id == id) return s;
  }
  return null;
});

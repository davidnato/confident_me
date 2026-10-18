import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/clock.dart';
import '../../core/utils/stable_hash.dart';
import '../../data/providers.dart';
import '../../models/affirmation.dart';

/// Category ids (as used in assets/data/affirmations.json) and their labels.
const affirmationCategories = <String, String>{
  'calm': 'Staying calm',
  'self_acceptance': 'Self-acceptance',
  'progress': 'Progress',
  'connection': 'Connection',
  'custom': 'My own',
};

const customCategoryId = 'custom';
const maxCustomAffirmationLength = 160;

/// The bundled library.
final affirmationsProvider = FutureProvider<List<Affirmation>>(
  (ref) => ref.watch(affirmationRepositoryProvider).loadAll(),
);

/// Affirmations the person wrote. Stored in Hive on this device.
class CustomAffirmationsController extends Notifier<List<Affirmation>> {
  @override
  List<Affirmation> build() => ref.read(customAffirmationStoreProvider).loadAll();

  /// Returns null if the text is blank.
  Future<Affirmation?> add(String text) async {
    var t = text.trim();
    if (t.isEmpty) return null;
    if (t.length > maxCustomAffirmationLength) {
      t = t.substring(0, maxCustomAffirmationLength);
    }
    final a = Affirmation(id: 'custom_${const Uuid().v4()}', text: t, category: customCategoryId);
    state = [...state, a];
    await ref.read(customAffirmationStoreProvider).put(a);
    return a;
  }

  Future<void> remove(String id) async {
    state = [for (final a in state) if (a.id != id) a];
    await ref.read(customAffirmationStoreProvider).delete(id);
  }

  Future<void> clearAll() async {
    state = [];
    await ref.read(customAffirmationStoreProvider).clear();
  }
}

final customAffirmationsProvider =
    NotifierProvider<CustomAffirmationsController, List<Affirmation>>(
  CustomAffirmationsController.new,
);

class AffirmationPrefs {
  const AffirmationPrefs({this.favoriteIds = const {}, this.categories = const {}});

  final Set<String> favoriteIds;

  /// Themes the person wants. Empty means "all themes".
  final Set<String> categories;
}

/// Favorites and preferred themes (small settings, kept in SharedPreferences).
class AffirmationPrefsController extends Notifier<AffirmationPrefs> {
  static const favoritesKey = 'affirmation_favorites_v1';
  static const categoriesKey = 'affirmation_categories_v1';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AffirmationPrefs build() => AffirmationPrefs(
        favoriteIds: (_prefs.getStringList(favoritesKey) ?? const []).toSet(),
        categories: (_prefs.getStringList(categoriesKey) ?? const []).toSet(),
      );

  Future<void> toggleFavorite(String id) async {
    final next = {...state.favoriteIds};
    if (!next.add(id)) next.remove(id);
    state = AffirmationPrefs(favoriteIds: next, categories: state.categories);
    await _prefs.setStringList(favoritesKey, next.toList());
  }

  Future<void> toggleCategory(String id) async {
    final next = {...state.categories};
    if (!next.add(id)) next.remove(id);
    state = AffirmationPrefs(favoriteIds: state.favoriteIds, categories: next);
    await _prefs.setStringList(categoriesKey, next.toList());
  }

  Future<void> clearCategories() async {
    state = AffirmationPrefs(favoriteIds: state.favoriteIds);
    await _prefs.remove(categoriesKey);
  }

  Future<void> clearAll() async {
    state = const AffirmationPrefs();
    await _prefs.remove(favoritesKey);
    await _prefs.remove(categoriesKey);
  }
}

final affirmationPrefsProvider =
    NotifierProvider<AffirmationPrefsController, AffirmationPrefs>(
  AffirmationPrefsController.new,
);

/// Bundled plus custom affirmations.
final allAffirmationsProvider = Provider<List<Affirmation>>((ref) => [
      ...(ref.watch(affirmationsProvider).valueOrNull ?? const <Affirmation>[]),
      ...ref.watch(customAffirmationsProvider),
    ]);

/// The affirmations that match the chosen themes (all of them if none chosen
/// or if the chosen themes currently have nothing in them).
List<Affirmation> filterByCategories(List<Affirmation> all, Set<String> categories) {
  if (categories.isEmpty) return all;
  final matching = all.where((a) => categories.contains(a.category)).toList();
  return matching.isEmpty ? all : matching;
}

/// Same affirmation all day, a different one tomorrow.
Affirmation? pickDailyAffirmation(List<Affirmation> pool, DateTime now) {
  if (pool.isEmpty) return null;
  final index = stableHash('${now.year}-${now.month}-${now.day}') % pool.length;
  return pool[index];
}

final todaysAffirmationProvider = Provider<Affirmation?>((ref) {
  final prefs = ref.watch(affirmationPrefsProvider);
  final pool = filterByCategories(ref.watch(allAffirmationsProvider), prefs.categories);
  return pickDailyAffirmation(pool, ref.watch(clockProvider)());
});

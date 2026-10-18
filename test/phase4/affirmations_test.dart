import 'package:confident_me/core/utils/clock.dart';
import 'package:confident_me/data/providers.dart';
import 'package:confident_me/data/repositories/record_store.dart';
import 'package:confident_me/features/affirmations/affirmation_providers.dart';
import 'package:confident_me/models/affirmation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const bundled = [
    Affirmation(id: 'c1', text: 'Calm one', category: 'calm'),
    Affirmation(id: 'c2', text: 'Calm two', category: 'calm'),
    Affirmation(id: 'p1', text: 'Progress one', category: 'progress'),
  ];
  late InMemoryRecordStoreFactory records;

  Future<ProviderContainer> makeContainer({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      recordStoreFactoryProvider.overrideWithValue(records),
      affirmationsProvider.overrideWith((ref) => Future.value(bundled)),
      clockProvider.overrideWithValue(() => now ?? DateTime(2026, 10, 18)),
    ]);
    addTearDown(c.dispose);
    await c.read(affirmationsProvider.future);
    return c;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    records = InMemoryRecordStoreFactory();
  });

  test('custom affirmations: add, trim, reject blank, shorten, and delete', () async {
    final c = await makeContainer();
    final custom = c.read(customAffirmationsProvider.notifier);

    expect(await custom.add('   '), isNull);
    final a = (await custom.add('  I am doing my best.  '))!;
    expect(a.text, 'I am doing my best.');
    expect(a.category, customCategoryId);
    expect(a.id, startsWith('custom_'));

    final long = (await custom.add('x' * 500))!;
    expect(long.text.length, maxCustomAffirmationLength);

    await custom.remove(a.id);
    expect(c.read(customAffirmationsProvider).map((x) => x.id), [long.id]);
  });

  test('custom affirmations are still there after a restart', () async {
    final c = await makeContainer();
    await c.read(customAffirmationsProvider.notifier).add('Kept for later');
    final restarted = await makeContainer();
    expect(restarted.read(customAffirmationsProvider).single.text, 'Kept for later');
  });

  test('favorites toggle on and off and persist', () async {
    final c = await makeContainer();
    final prefs = c.read(affirmationPrefsProvider.notifier);
    await prefs.toggleFavorite('c1');
    await prefs.toggleFavorite('p1');
    expect(c.read(affirmationPrefsProvider).favoriteIds, {'c1', 'p1'});
    await prefs.toggleFavorite('c1');
    expect(c.read(affirmationPrefsProvider).favoriteIds, {'p1'});

    final restarted = await makeContainer();
    expect(restarted.read(affirmationPrefsProvider).favoriteIds, {'p1'});
  });

  test('preferred categories toggle, clear, and persist', () async {
    final c = await makeContainer();
    final prefs = c.read(affirmationPrefsProvider.notifier);
    await prefs.toggleCategory('calm');
    await prefs.toggleCategory('progress');
    expect(c.read(affirmationPrefsProvider).categories, {'calm', 'progress'});

    final restarted = await makeContainer();
    expect(restarted.read(affirmationPrefsProvider).categories, {'calm', 'progress'});

    await prefs.clearCategories();
    expect(c.read(affirmationPrefsProvider).categories, isEmpty);
  });

  test('category filtering shows everything when nothing useful is selected', () {
    expect(filterByCategories(bundled, {}).length, 3);
    expect(filterByCategories(bundled, {'calm'}).map((a) => a.id), ['c1', 'c2']);
    expect(filterByCategories(bundled, {'connection'}).length, 3);
  });

  test('the daily affirmation is stable within a day and uses the chosen themes',
      () async {
    final c = await makeContainer();
    await c.read(affirmationPrefsProvider.notifier).toggleCategory('calm');

    final first = c.read(todaysAffirmationProvider)!;
    expect(first.category, 'calm');
    expect(c.read(todaysAffirmationProvider)!.id, first.id);

    for (var day = 1; day <= 20; day++) {
      final other = await makeContainer(now: DateTime(2026, 10, day));
      await other.read(affirmationPrefsProvider.notifier).toggleCategory('calm');
      expect(other.read(todaysAffirmationProvider)!.category, 'calm');
    }
  });

  test('custom affirmations join the daily pool', () async {
    final c = await makeContainer();
    await c.read(customAffirmationsProvider.notifier).add('Mine');
    await c.read(affirmationPrefsProvider.notifier).toggleCategory(customCategoryId);
    expect(c.read(todaysAffirmationProvider)!.text, 'Mine');
  });

  test('pickDailyAffirmation handles an empty pool', () {
    expect(pickDailyAffirmation(const [], DateTime(2026)), isNull);
  });
}

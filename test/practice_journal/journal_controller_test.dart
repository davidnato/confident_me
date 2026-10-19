import 'package:confident_me/core/utils/clock.dart';
import 'package:confident_me/data/providers.dart';
import 'package:confident_me/data/repositories/record_store.dart';
import 'package:confident_me/features/journal/journal_controller.dart';
import 'package:confident_me/models/journal_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  var now = DateTime(2026, 10, 18, 9);
  late InMemoryRecordStoreFactory records;

  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      recordStoreFactoryProvider.overrideWithValue(records),
      clockProvider.overrideWithValue(() => now),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  JournalEntry newEntry(String id, DateTime created, {String situation = ''}) =>
      JournalEntry(id: id, createdAt: created, updatedAt: created, situation: situation);

  setUp(() {
    now = DateTime(2026, 10, 18, 9);
    records = InMemoryRecordStoreFactory();
  });

  test('creates an entry and keeps it newest first', () async {
    final c = await makeContainer();
    final j = c.read(journalProvider.notifier);
    await j.save(newEntry('old', DateTime(2026, 10, 1), situation: 'older'));
    await j.save(newEntry('new', DateTime(2026, 10, 17), situation: 'newer'));
    expect(c.read(journalProvider).map((e) => e.id), ['new', 'old']);
  });

  test('editing updates the entry and its updatedAt, not createdAt', () async {
    final c = await makeContainer();
    final j = c.read(journalProvider.notifier);
    final created = DateTime(2026, 10, 1, 8);
    await j.save(newEntry('a', created, situation: 'before'));

    now = DateTime(2026, 10, 18, 15);
    final saved = await j.save(
      c.read(journalProvider).single.copyWith(situation: 'after'),
    );

    final entries = c.read(journalProvider);
    expect(entries.length, 1);
    expect(entries.single.situation, 'after');
    expect(entries.single.createdAt, created);
    expect(saved.updatedAt, now);
  });

  test('deleting removes the entry', () async {
    final c = await makeContainer();
    final j = c.read(journalProvider.notifier);
    await j.save(newEntry('a', DateTime(2026, 10, 1), situation: 'x'));
    await j.save(newEntry('b', DateTime(2026, 10, 2), situation: 'y'));
    await j.delete('a');
    expect(c.read(journalProvider).map((e) => e.id), ['b']);
    expect(j.find('a'), isNull);
  });

  test('entries are still there after a restart', () async {
    final c = await makeContainer();
    await c
        .read(journalProvider.notifier)
        .save(newEntry('a', DateTime(2026, 10, 1), situation: 'kept'));

    final restarted = await makeContainer(); // same stores
    expect(restarted.read(journalProvider).single.situation, 'kept');
  });

  test('a deletion also persists', () async {
    final c = await makeContainer();
    await c
        .read(journalProvider.notifier)
        .save(newEntry('a', DateTime(2026, 10, 1), situation: 'gone soon'));
    await c.read(journalProvider.notifier).delete('a');

    final restarted = await makeContainer();
    expect(restarted.read(journalProvider), isEmpty);
  });

  test('isBlank ignores whitespace', () {
    expect(newEntry('a', DateTime(2026)).isBlank, isTrue);
    expect(newEntry('a', DateTime(2026), situation: '   ').isBlank, isTrue);
    expect(newEntry('a', DateTime(2026), situation: 'hi').isBlank, isFalse);
  });

  test('entries round-trip through JSON and tolerate missing fields', () {
    final e = JournalEntry(
      id: 'x',
      createdAt: DateTime.utc(2026, 1, 2),
      updatedAt: DateTime.utc(2026, 1, 3),
      situation: 's',
      feelings: 'f',
      anticipatedOutcome: 'a',
      actualOutcome: 'o',
      lessonsLearned: 'l',
      nextStep: 'n',
    );
    final copy = JournalEntry.tryFromJson(e.toJson())!;
    expect(copy.situation, 's');
    expect(copy.feelings, 'f');
    expect(copy.anticipatedOutcome, 'a');
    expect(copy.actualOutcome, 'o');
    expect(copy.lessonsLearned, 'l');
    expect(copy.nextStep, 'n');
    expect(copy.createdAt, e.createdAt);
    expect(copy.updatedAt, e.updatedAt);

    expect(JournalEntry.tryFromJson({'situation': 'no id'}), isNull);
    expect(JournalEntry.tryFromJson({'id': 'only id'})!.feelings, '');
  });
}

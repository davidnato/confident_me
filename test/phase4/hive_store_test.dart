import 'dart:io';

import 'package:confident_me/data/repositories/record_store.dart';
import 'package:confident_me/models/journal_entry.dart';
import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('confidentme_hive_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  HiveRecordStore<JournalEntry> storeFor(Box<String> box) =>
      HiveRecordStore<JournalEntry>(
        box: box,
        fromJson: JournalEntry.tryFromJson,
        toJson: (e) => e.toJson(),
        idOf: (e) => e.id,
      );

  JournalEntry entry(String id, String text) => JournalEntry(
        id: id,
        createdAt: DateTime(2026, 10, 18, 9),
        updatedAt: DateTime(2026, 10, 18, 9),
        situation: text,
      );

  test('saves, updates and deletes records', () async {
    final box = await Hive.openBox<String>('journal_entries');
    final store = storeFor(box);

    await store.put(entry('a', 'first'));
    await store.put(entry('b', 'second'));
    expect(store.loadAll().length, 2);

    await store.put(entry('a', 'first, edited'));
    final all = store.loadAll();
    expect(all.length, 2);
    expect(all.firstWhere((e) => e.id == 'a').situation, 'first, edited');

    await store.delete('b');
    expect(store.loadAll().map((e) => e.id), ['a']);

    await store.clear();
    expect(store.loadAll(), isEmpty);
  });

  test('records are still there after the box is closed and reopened', () async {
    var box = await Hive.openBox<String>('journal_entries');
    await storeFor(box).put(entry('a', 'kept'));
    await box.close();

    box = await Hive.openBox<String>('journal_entries');
    final loaded = storeFor(box).loadAll();
    expect(loaded.single.id, 'a');
    expect(loaded.single.situation, 'kept');
  });

  test('a damaged record is skipped and the others still load', () async {
    final box = await Hive.openBox<String>('journal_entries');
    final store = storeFor(box);
    await store.put(entry('good', 'fine'));
    await box.put('bad', 'this is not json');
    await box.put('also_bad', '{"no_id": true}');

    final loaded = store.loadAll();
    expect(loaded.length, 1);
    expect(loaded.single.id, 'good');
  });

  test('an older record that lacks newer fields still loads', () async {
    final box = await Hive.openBox<String>('journal_entries');
    await box.put('old', '{"id":"old","situation":"from an older version"}');
    final loaded = storeFor(box).loadAll();
    expect(loaded.single.situation, 'from an older version');
    expect(loaded.single.nextStep, '');
  });

  test('the factory refuses a box that was never opened', () {
    final factory = HiveRecordStoreFactory({});
    expect(
      () => factory.create<JournalEntry>(
        HiveRecordStoreFactory.journalBox,
        fromJson: JournalEntry.tryFromJson,
        toJson: (e) => e.toJson(),
        idOf: (e) => e.id,
      ),
      throwsStateError,
    );
  });
}

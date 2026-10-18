import 'dart:convert';

import 'package:hive/hive.dart';

/// A small keyed collection of records (journal entries, practice sessions...).
/// Screens never use this directly; they go through controllers.
abstract class RecordStore<T> {
  List<T> loadAll();
  Future<void> put(T item);
  Future<void> delete(String id);
  Future<void> clear();
}

typedef FromJson<T> = T? Function(Map<String, dynamic> json);
typedef ToJson<T> = Map<String, dynamic> Function(T item);
typedef IdOf<T> = String Function(T item);

/// Creates stores by name. The app uses Hive; tests use memory.
abstract class RecordStoreFactory {
  RecordStore<T> create<T>(
    String name, {
    required FromJson<T> fromJson,
    required ToJson<T> toJson,
    required IdOf<T> idOf,
  });
}

/// Hive-backed store. Each record is saved as a JSON string under its id, so
/// no generated adapters are needed and an old record missing a newer field
/// still loads (the model's `tryFromJson` fills in defaults).
class HiveRecordStore<T> implements RecordStore<T> {
  HiveRecordStore({
    required Box<String> box,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
  }) : _box = box;

  final Box<String> _box;
  final FromJson<T> fromJson;
  final ToJson<T> toJson;
  final IdOf<T> idOf;

  @override
  List<T> loadAll() {
    final result = <T>[];
    for (final raw in _box.values) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final item = fromJson(decoded);
          if (item != null) result.add(item);
        }
      } catch (_) {
        // Skip a damaged record instead of losing everything.
      }
    }
    return result;
  }

  @override
  Future<void> put(T item) => _box.put(idOf(item), jsonEncode(toJson(item)));

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}

class HiveRecordStoreFactory implements RecordStoreFactory {
  HiveRecordStoreFactory(this._boxes);

  /// Boxes the app needs. All are opened once at startup in main().
  static const boxNames = <String>[
    journalBox,
    practiceBox,
    customAffirmationBox,
  ];
  static const journalBox = 'journal_entries';
  static const practiceBox = 'practice_sessions';
  static const customAffirmationBox = 'custom_affirmations';

  final Map<String, Box<String>> _boxes;

  @override
  RecordStore<T> create<T>(
    String name, {
    required FromJson<T> fromJson,
    required ToJson<T> toJson,
    required IdOf<T> idOf,
  }) {
    final box = _boxes[name];
    if (box == null) {
      throw StateError('Hive box "$name" was not opened at startup.');
    }
    return HiveRecordStore<T>(
      box: box,
      fromJson: fromJson,
      toJson: toJson,
      idOf: idOf,
    );
  }
}

class InMemoryRecordStore<T> implements RecordStore<T> {
  InMemoryRecordStore({required this.idOf});

  final IdOf<T> idOf;
  final Map<String, T> _items = {};

  @override
  List<T> loadAll() => _items.values.toList();

  @override
  Future<void> put(T item) async => _items[idOf(item)] = item;

  @override
  Future<void> delete(String id) async => _items.remove(id);

  @override
  Future<void> clear() async => _items.clear();
}

/// Same name returns the same store, so a "restarted" test container that
/// shares this factory sees the data saved earlier.
class InMemoryRecordStoreFactory implements RecordStoreFactory {
  final Map<String, Object> _stores = {};

  @override
  RecordStore<T> create<T>(
    String name, {
    required FromJson<T> fromJson,
    required ToJson<T> toJson,
    required IdOf<T> idOf,
  }) =>
      _stores.putIfAbsent(name, () => InMemoryRecordStore<T>(idOf: idOf))
          as RecordStore<T>;
}

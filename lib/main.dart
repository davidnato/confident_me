import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/providers.dart';
import 'data/repositories/record_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Small settings and Phase 2-3 progress live in SharedPreferences.
  final prefs = await SharedPreferences.getInstance();

  // Journal entries, practice sessions and custom affirmations live in Hive,
  // a local database stored in the app's private folder on this device.
  await Hive.initFlutter();
  final boxes = <String, Box<String>>{
    for (final name in HiveRecordStoreFactory.boxNames)
      name: await Hive.openBox<String>(name),
  };

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        recordStoreFactoryProvider
            .overrideWithValue(HiveRecordStoreFactory(boxes)),
      ],
      child: const ConfidentMeApp(),
    ),
  );
}

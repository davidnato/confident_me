import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/gamification/gamification_service.dart';
import 'features/settings_controller.dart';

class ConfidentMeApp extends ConsumerStatefulWidget {
  const ConfidentMeApp({super.key});

  @override
  ConsumerState<ConfidentMeApp> createState() => _ConfidentMeAppState();
}

class _ConfidentMeAppState extends ConsumerState<ConfidentMeApp> {
  @override
  void initState() {
    super.initState();
    // Gives XP to anything completed before XP existed. Safe to repeat.
    Future<void>.microtask(() async {
      try {
        await ref.read(gamificationServiceProvider).reconcile();
      } catch (_) {
        // If the library cannot load, the home screen shows its own error.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}

import 'dart:convert';
import 'dart:math';

import 'package:confident_me/core/theme/app_palette.dart';
import 'package:confident_me/core/theme/app_theme.dart';
import 'package:confident_me/data/providers.dart';
import 'package:confident_me/features/settings_controller.dart';
import 'package:confident_me/models/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

/// WCAG contrast ratio between two colours (1 = identical, 21 = black/white).
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  test('palette ids are unique and every palette has a label', () {
    final ids = AppPalette.values.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final p in AppPalette.values) {
      expect(p.label, isNotEmpty);
    }
    expect(AppPalette.values.length, greaterThanOrEqualTo(4));
  });

  test('unknown or missing ids fall back to Lavender', () {
    expect(AppPalette.fromId('ocean'), AppPalette.ocean);
    expect(AppPalette.fromId('nope'), AppPalette.lavender);
    expect(AppPalette.fromId(null), AppPalette.lavender);
  });

  test('the palette is saved with the settings and older settings still load',
      () {
    const s = AppSettings(palette: AppPalette.rose);
    expect(AppSettings.fromJson(s.toJson()).palette, AppPalette.rose);
    expect(AppSettings.fromJson({'themeMode': 'dark'}).palette,
        AppPalette.lavender);
    expect(AppSettings.fromJson({'palette': 42}).palette, AppPalette.lavender);
    expect(
        AppSettings.fromJson({'palette': 'gone'}).palette, AppPalette.lavender);
    expect(const AppSettings().palette, AppPalette.lavender);
  });

  for (final palette in AppPalette.values) {
    for (final brightness in Brightness.values) {
      test('${palette.id} (${brightness.name}) meets text contrast guidelines',
          () {
        final theme = brightness == Brightness.light
            ? AppTheme.light(palette)
            : AppTheme.dark(palette);
        final c = theme.colorScheme;
        expect(theme.useMaterial3, isTrue);

        // Body text pairs: at least 4.5:1.
        final textPairs = <String, List<Color>>{
          'onPrimary on primary': [c.onPrimary, c.primary],
          'onPrimaryContainer on primaryContainer': [
            c.onPrimaryContainer,
            c.primaryContainer
          ],
          'onSecondaryContainer on secondaryContainer': [
            c.onSecondaryContainer,
            c.secondaryContainer
          ],
          'onTertiaryContainer on tertiaryContainer': [
            c.onTertiaryContainer,
            c.tertiaryContainer
          ],
          'onSurface on surface': [c.onSurface, c.surface],
          'onSurfaceVariant on surface': [c.onSurfaceVariant, c.surface],
          'onError on error': [c.onError, c.error],
        };
        textPairs.forEach((name, pair) {
          expect(contrast(pair[0], pair[1]), greaterThanOrEqualTo(4.5),
              reason: name);
        });

        // Icons and controls drawn on the page background: at least 3:1.
        expect(contrast(c.primary, c.surface), greaterThanOrEqualTo(3.0),
            reason: 'primary on surface');
        expect(contrast(c.tertiary, c.surface), greaterThanOrEqualTo(3.0),
            reason: 'tertiary on surface');
      });
    }
  }

  test('each palette gives a different primary color', () {
    final primaries = {
      for (final p in AppPalette.values) AppTheme.light(p).colorScheme.primary,
    };
    expect(primaries.length, AppPalette.values.length);
  });

  test('buttons are touch-friendly in every palette', () {
    for (final p in AppPalette.values) {
      final theme = AppTheme.light(p);
      final filled = theme.filledButtonTheme.style!.minimumSize!.resolve({})!;
      final text = theme.textButtonTheme.style!.minimumSize!.resolve({})!;
      expect(filled.height, greaterThanOrEqualTo(48));
      expect(text.height, greaterThanOrEqualTo(48));
      expect(text.width, greaterThanOrEqualTo(48));
    }
  });

  test('the default theme is Lavender', () {
    expect(AppTheme.light().colorScheme.primary,
        AppTheme.light(AppPalette.lavender).colorScheme.primary);
    expect(AppTheme.dark().colorScheme.primary,
        AppTheme.dark(AppPalette.lavender).colorScheme.primary);
  });

  test('a chosen palette survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer make() {
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      return c;
    }

    await make().read(settingsProvider.notifier).setPalette(AppPalette.mint);
    expect(make().read(settingsProvider).palette, AppPalette.mint);
    expect(jsonDecode(prefs.getString('app_settings_v1')!)['palette'], 'mint');
  });

  testWidgets(
      'choosing a palette in Settings recolors the app and is remembered',
      (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.byKey(const Key('open_settings')));

    expect(find.byKey(const Key('palette_check_lavender')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('palette_ocean')));

    expect(find.byKey(const Key('palette_check_ocean')), findsOneWidget);
    expect(find.byKey(const Key('palette_check_lavender')), findsNothing);
    expect(
        containerOf(tester).read(settingsProvider).palette, AppPalette.ocean);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.colorScheme.primary,
        AppTheme.light(AppPalette.ocean).colorScheme.primary);
    expect(app.darkTheme!.colorScheme.primary,
        AppTheme.dark(AppPalette.ocean).colorScheme.primary);
  });

  testWidgets('palette and light/dark mode work together', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.byKey(const Key('open_settings')));
    await tapVisible(tester, find.text('Dark'));
    await tapVisible(tester, find.byKey(const Key('palette_rose')));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme!.colorScheme.primary,
        AppTheme.dark(AppPalette.rose).colorScheme.primary);
  });

  testWidgets('every palette can be selected', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.byKey(const Key('open_settings')));
    for (final p in AppPalette.values) {
      await tapVisible(tester, find.byKey(Key('palette_${p.id}')));
      expect(find.byKey(Key('palette_check_${p.id}')), findsOneWidget);
      expect(containerOf(tester).read(settingsProvider).palette, p);
    }
  });
}

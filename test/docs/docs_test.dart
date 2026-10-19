import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps the documentation honest: the files exist, every file path the docs
/// mention exists, and the docs make no promises about features that are not
/// in the app.
void main() {
  const requiredDocs = [
    'README.md',
    'docs/SETUP.md',
    'docs/USER_GUIDE.md',
    'docs/ARCHITECTURE.md',
    'docs/DATA_AND_PRIVACY.md',
    'docs/TROUBLESHOOTING.md',
    'docs/DEPLOYMENT.md',
  ];

  String read(String path) => File(path).readAsStringSync();

  test('every required document exists and is not empty', () {
    for (final path in requiredDocs) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(read(path).trim().length, greaterThan(500), reason: path);
    }
  });

  // Paths the docs mention on purpose even though they are not in the project:
  // two made-up files from the "how to add a feature" example, and the sample
  // test that `flutter create` generates and the setup guide says to delete.
  const intentionallyMissing = {
    'lib/models/gratitude_note.dart',
    'lib/features/gratitude/gratitude_controller.dart',
    'test/widget_test.dart',
  };

  test('every project file mentioned in the docs exists', () {
    final inlineCode = RegExp(r'`([^`\n]+)`');
    final projectFile =
        RegExp(r'^(?:lib|assets|test|integration_test|docs)/[A-Za-z0-9_./-]+\.[a-z]+$');
    final missing = <String>[];
    for (final doc in requiredDocs) {
      // Look only at inline code, not at fenced command blocks.
      final text = read(doc).replaceAll(RegExp(r'```[\s\S]*?```'), '');
      for (final m in inlineCode.allMatches(text)) {
        final candidate = m.group(1)!;
        if (projectFile.hasMatch(candidate) &&
            !intentionallyMissing.contains(candidate) &&
            !File(candidate).existsSync()) {
          missing.add('$doc -> $candidate');
        }
      }
    }
    expect(missing, isEmpty, reason: 'docs mention files that do not exist');
  });

  test('the README links every other document', () {
    final readme = read('README.md');
    for (final path in requiredDocs.where((p) => p.startsWith('docs/'))) {
      expect(readme, contains(path), reason: path);
    }
  });

  test('the setup guide covers every step with the real commands', () {
    final setup = read('docs/SETUP.md');
    for (final command in [
      'flutter doctor',
      'flutter pub get',
      'flutter devices',
      'flutter run',
      'flutter analyze',
      'flutter test',
      'flutter test integration_test/app_test.dart',
      'flutter build apk --release',
      'flutter build appbundle --release',
    ]) {
      expect(setup, contains(command), reason: command);
    }
  });

  test('the architecture guide has a Mermaid diagram', () {
    expect(read('docs/ARCHITECTURE.md'), contains('```mermaid'));
  });

  test('docs do not give setup commands for features that do not exist', () {
    final all = requiredDocs.map(read).join('\n').toLowerCase();
    for (final forbidden in [
      'flutterfire configure',
      'firebase deploy',
      'firebase init',
      'flutter pub add firebase',
      'flutter_local_notifications',
      'google-services.json" to',
    ]) {
      expect(all, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test('the dependencies listed in the setup guide are the real ones', () {
    final pubspec = read('pubspec.yaml');
    final setup = read('docs/SETUP.md');
    for (final package in [
      'flutter_riverpod',
      'go_router',
      'shared_preferences',
      'hive',
      'hive_flutter',
      'uuid',
    ]) {
      expect(pubspec, contains('$package:'), reason: '$package in pubspec');
      expect(setup, contains('`$package`'), reason: '$package in SETUP.md');
    }
    expect(pubspec, isNot(contains('firebase')));
  });

  test('the privacy document names every storage key the app really uses', () {
    final privacy = read('docs/DATA_AND_PRIVACY.md');
    for (final key in [
      'user_profile_v1',
      'app_settings_v1',
      'challenge_progress_v1',
      'xp_ledger_v1',
      'earned_achievements_v1',
      'milestones_v1',
      'affirmation_favorites_v1',
      'affirmation_categories_v1',
      'reminder_dismissed_on_v1',
      'journal_entries',
      'practice_sessions',
      'custom_affirmations',
    ]) {
      expect(privacy, contains(key), reason: key);
      // ...and the key really exists in the code.
      final inCode = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .any((f) => f.readAsStringSync().contains("'$key'"));
      expect(inCode, isTrue, reason: '$key is documented but not in lib/');
    }
  });
}

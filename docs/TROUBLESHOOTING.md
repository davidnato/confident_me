# Troubleshooting

Each entry gives the symptom, what is usually behind it, and exact steps to fix
it. Two commands help with almost everything:

```
flutter doctor -v     # checks your whole setup
flutter clean         # deletes build files; follow with: flutter pub get
```

## `flutter: command not found`

**Cause:** Flutter's `bin` folder is not on your `PATH`, or the terminal was open
before you installed it.

1. Close the terminal and open a new one.
2. Find where Flutter is installed (for example `~/development/flutter`) and add
   its `bin` folder to `PATH`.
   - macOS/Linux (bash or zsh): add `export PATH="$PATH:$HOME/development/flutter/bin"`
     to `~/.bashrc` or `~/.zshrc`, then `source ~/.bashrc`.
   - Snap install: make sure `/snap/bin` is on your `PATH`.
   - Windows: Start menu > "Edit environment variables" > Path > New > add the
     `flutter\bin` folder.
3. Check with `flutter --version`.

## `flutter doctor` shows errors

Run `flutter doctor -v` and read the line under the red ✗.

| Message | Fix |
| --- | --- |
| `cmdline-tools component is missing` | Android Studio > SDK Manager > SDK Tools > tick **Android SDK Command-line Tools** > Apply |
| `Android license status unknown` / `Some Android licenses not accepted` | `flutter doctor --android-licenses` and answer `y` |
| `Unable to locate Android SDK` | see the next entry |
| `Unable to find bundled Java version` / Java errors | install Android Studio (it bundles Java), then `flutter config --jdk-dir "<path to Android Studio's jbr folder>"` |
| Chrome / Linux toolchain / Visual Studio problems | ignore them; this app targets Android |

## Android SDK missing

**Symptom:** `Unable to locate Android SDK`, or builds fail with "SDK location
not found".

1. Install Android Studio and finish its first-run wizard (it downloads the SDK).
2. Or, if you already have an SDK, point Flutter at it:
   `flutter config --android-sdk "/path/to/Android/Sdk"`.
3. In the project's `android/local.properties` the line `sdk.dir=...` must point at
   the same folder. Flutter writes this file; running `flutter pub get` again
   usually repairs it.

## Emulator or phone not detected

Run `flutter devices`. If your device is missing:

- **Emulator:** `flutter emulators` lists them. Start one with
  `flutter emulators --launch <emulator id>`, or press play in Android Studio's
  Device Manager. Wait until the home screen appears, then run `flutter devices`.
- **Phone:** turn on Developer options and **USB debugging**, use a data-capable
  cable, and accept the prompt on the phone. `adb devices` should list it as
  `device`. If it says `unauthorized`, unplug it, revoke USB debugging
  authorizations in Developer options, and plug it in again.
- **Linux:** if `adb devices` says `no permissions`, add the udev rule for your
  phone's vendor or run `adb kill-server` and try again.
- Restart the adb server: `adb kill-server` then `adb start-server`.

## Dependency problems

**Symptom:** `flutter pub get` says `version solving failed`, or a package
"requires SDK version ...".

1. Check your Flutter is recent: `flutter --version`. The project needs Dart 3.3
   or newer. If it is older, run `flutter upgrade`.
2. Try `flutter pub upgrade` (it picks the newest versions allowed by
   `pubspec.yaml`).
3. If the message names a specific package, open `pubspec.yaml` and loosen that
   package's version (for example, `hive: ^2.2.3` is fine to leave; change only
   the one that conflicts).
4. Delete `pubspec.lock` and run `flutter pub get` again.
5. `flutter pub outdated` shows what could be updated.

> The versions in `pubspec.yaml` could not be checked against pub.dev when the
> project was written, so a mismatch with a very new Flutter is possible. Steps 2
> and 3 resolve it.

## Missing assets

**Symptoms:**

- `Error: unable to find directory entry in pubspec.yaml: assets/data/`
- The app shows "The challenge library could not be loaded" (or the scenarios or
  affirmations) with a **Try again** button.

**Fix:**

1. Check the files exist: `assets/data/challenges.json`, `scenarios.json`,
   `affirmations.json`.
2. In `pubspec.yaml` the `assets:` entry must be indented under `flutter:` exactly
   like this (two spaces, then four):
   ```
   flutter:
     uses-material-design: true
     assets:
       - assets/data/
   ```
3. Stop the app and run `flutter clean`, `flutter pub get`, `flutter run`. Hot
   reload never picks up new assets.

## App icon did not change

Android caches launcher icons.

1. Make sure you ran `dart run flutter_launcher_icons` after `flutter pub get`
   (it prints `Successfully generated launcher icons`).
2. Uninstall the app from the phone or emulator, then `flutter run` again. A
   normal reinstall over the old app often keeps the old icon.
3. If the command says it cannot find `android/`, create the platform folders
   first (`flutter create --org com.example --project-name confident_me .`).
4. Still the old icon? Restart the emulator, or on a phone restart the launcher.

## Incorrect import paths

**Symptom:** `Target of URI doesn't exist` or `Undefined class`.

- Inside `lib/`, files import each other with relative paths (for example
  `import '../../models/journal_entry.dart';`). Count the `../` carefully; moving a
  file changes them all.
- Tests import the app as `package:confident_me/...`. That only works if the
  `name:` at the top of `pubspec.yaml` is `confident_me`. If you created the
  project under another name, change it back (or update the imports).
- After renaming or moving files, run `flutter analyze`; it lists every broken
  import with its file and line.

## Build failures

First try the clean rebuild:

```
flutter clean
flutter pub get
flutter run
```

Still failing? Read the **first** error in the output, not the last.

- **`Minimum supported Gradle version is X`** or **`Unsupported class file major
  version`:** your Java and Gradle versions disagree. `flutter doctor -v` shows the
  Java Flutter uses. Use the Java that comes with Android Studio, and let Flutter's
  Gradle files be regenerated by creating a fresh project and copying `lib/`,
  `test/`, `assets/` and `pubspec.yaml` into it.
- **`SDK location not found`:** see "Android SDK missing".
- **`Execution failed for task ':app:...'` after a package change:** run
  `cd android && ./gradlew --stop` (Windows: `gradlew.bat --stop`), go back, and
  `flutter clean`.
- **`Could not resolve ...` / network errors:** Gradle needs the internet the first
  time it builds. Check your connection or proxy.
- **Out of memory:** close other programs, or add `org.gradle.jvmargs=-Xmx2g` to
  `android/gradle.properties`.

## The app crashes or shows a red screen on startup

1. Run `flutter run -v` (verbose) and read the first exception.
2. **After adding or changing packages**, do a full stop and `flutter run`.
   `MissingPluginException` means the app is running an old build; hot restart is
   not enough.
3. **`Hive box "..." was not opened at startup`** (a `StateError`): a new Hive box
   was added without its name being in `HiveRecordStoreFactory.boxNames`
   (`lib/data/repositories/record_store.dart`). `main.dart` opens every name in
   that list.
4. **`sharedPreferencesProvider must be overridden`** or **`recordStoreFactoryProvider
   must be overridden`:** the app (or a test) was started without the
   `ProviderScope` overrides that `lib/main.dart` sets up. Start the app from
   `main.dart`, and in tests use `pumpApp` from `test/helpers/test_app.dart`.
5. **Crashes only on your phone, only since an update:** saved data may be damaged.
   Clear the app's storage (Android: Settings > Apps > ConfidentMe > Storage >
   Clear storage). This deletes your data. The app is built to skip unreadable
   records, so please report it if this happens.

## Data not persisting

- **You uninstalled the app or cleared its storage.** That deletes everything.
- **You ran a different build.** A debug build and a release build signed with a
  different key are different installs on the phone, each with its own data.
- **The emulator was wiped.** Emulators started with "Cold Boot" or "Wipe Data"
  start fresh.
- **You used "Delete all my data" or "Reset progress"** in Settings.
- **Tests:** tests deliberately use in-memory storage, so nothing persists between
  test runs.
- To check storage is working: complete a challenge, close the app fully (swipe it
  away), reopen it, and check Progress.

## Firebase configuration errors

Firebase is not part of this version of ConfidentMe (see
`docs/DATA_AND_PRIVACY.md`), so there is no `google-services.json` and nothing to
configure. If you see Firebase errors, they come from code added to your copy of
the project, not from ConfidentMe itself.

## Tests failing

Run one file at a time to find the problem: `flutter test test/features/daily_planner_test.dart`.

| Message | Cause and fix |
| --- | --- |
| `test/widget_test.dart ... The name 'MyApp' isn't a class` | `flutter create` added a sample test. Delete `test/widget_test.dart`. |
| A tap does nothing, or `Warning: A call to tap() ... derived an Offset ... that would not hit test` | The widget is off screen. Use `tapVisible` from `test/helpers/test_app.dart` (it scrolls first) and keep the large test screen that `pumpApp` sets. |
| `pumpAndSettle timed out` | Something is animating forever, usually a running breathing session. In those tests use `tester.pump(Duration(...))` while it runs and `pumpAndSettle` only after stopping. |
| `A Timer is still pending even after the widget tree was disposed` | A test left a timer or ticker running. Stop the session or finish the flow before the test ends. |
| `UnimplementedError: sharedPreferencesProvider must be overridden` | The test built a `ProviderContainer` without the overrides. Copy the setup from an existing test (for example `test/features/progress_controller_test.dart`). |
| Dates behave oddly | Tests that depend on "today" must override `clockProvider` or use the current date. Check the test builds its dates from the same clock. |
| Hive tests fail with a file or path error | `test/practice_journal/hive_store_test.dart` creates a temporary folder and calls `Hive.init`. Make sure the temp folder is writable. |
| `integration_test` cannot find a device | Start an emulator or connect a phone, then pass its id: `flutter test integration_test/app_test.dart -d <id>`. |

If a test fails and you are not sure why, run it alone with `flutter test <file>
--plain-name "<part of the test name>"` and read the first failure, which includes
the exact expected and actual values.

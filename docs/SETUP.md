# Setup guide

This guide takes you from nothing installed to ConfidentMe running on an
Android emulator or phone. Every command is meant to be typed exactly as shown.
The "expected output" blocks show what you should see; your exact numbers and
wording will differ a little.

ConfidentMe runs entirely on your device. It needs **no accounts, no API keys
and no internet connection** to work.

## What the project uses

Packages (from `pubspec.yaml`):

| Package | Used for |
| --- | --- |
| `flutter_riverpod` | state management and dependency injection |
| `go_router` | navigation |
| `shared_preferences` | small settings and progress records |
| `hive`, `hive_flutter` | local database for journal entries, practice history and your own affirmations |
| `uuid` | unique ids for records |

Dev-only: `flutter_test`, `integration_test`, `flutter_lints`, and
`flutter_launcher_icons` (a tool that installs the app icon; it is not part of the
app).

The project needs a Flutter version that includes **Dart 3.3 or newer**
(Flutter 3.19 or newer). A current stable Flutter is the best choice.

> Package versions in `pubspec.yaml` were chosen to be mutually compatible, but
> they could not be checked against pub.dev while writing this project. If
> `flutter pub get` reports a conflict, see `docs/TROUBLESHOOTING.md`.

---

## 1. Install Flutter

Follow the official guide for your system: <https://docs.flutter.dev/get-started/install>

Quick versions:

- **Windows / macOS:** download the Flutter SDK zip from the guide, unzip it
  somewhere you own (for example `C:\src\flutter` or `~/development/flutter`),
  and add its `bin` folder to your `PATH`.
- **Linux (snap):**
  ```
  sudo snap install flutter --classic
  ```

Check it worked (open a **new** terminal first so the PATH change is picked up):

```
flutter --version
```

Expected output (similar to):

```
Flutter 3.xx.x • channel stable • ...
Dart SDK version: 3.x.x ...
```

## 2. Install Android Studio (or configure an Android SDK)

Android Studio is the easiest way to get the Android SDK and emulators.

1. Download it from <https://developer.android.com/studio> and install it.
2. Open it once and finish the setup wizard (it downloads the Android SDK).
3. Open **More Actions > SDK Manager** (or **Settings > Languages & Frameworks >
   Android SDK**). On the **SDK Tools** tab make sure these are ticked, then
   click **Apply**:
   - Android SDK Command-line Tools (latest)
   - Android SDK Platform-Tools
   - Android Emulator
4. Accept the Android licenses:
   ```
   flutter doctor --android-licenses
   ```
   Type `y` and press Enter each time you are asked.

Already have an Android SDK somewhere else? Tell Flutter where it is:

```
flutter config --android-sdk "/path/to/your/Android/Sdk"
```

## 3. Install Visual Studio Code

Download it from <https://code.visualstudio.com/> and install it.

## 4. Install the Flutter and Dart extensions

1. In VS Code open the Extensions panel (`Ctrl+Shift+X`, or `Cmd+Shift+X` on
   macOS).
2. Search for **Flutter** and click **Install**. The **Dart** extension is
   installed automatically with it.
3. Restart VS Code.

## 5. Check your installation with `flutter doctor`

```
flutter doctor
```

Expected output (similar to):

```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.xx.x, ...)
[✓] Android toolchain - develop for Android devices (Android SDK version 34.x.x)
[✓] Android Studio (version 2024.x)
[✓] VS Code (version 1.xx)
[✓] Connected device (1 available)
[✓] Network resources

• No issues found!
```

You can ignore problems about **Chrome**, **Linux desktop** or **Visual Studio**
(Windows desktop) because this app is for Android. A red ✗ on **Android
toolchain** must be fixed. Common fixes:

| Message | Fix |
| --- | --- |
| `cmdline-tools component is missing` | SDK Manager > SDK Tools > install **Android SDK Command-line Tools** |
| `Android license status unknown` / `licenses not accepted` | `flutter doctor --android-licenses` |
| `Unable to locate Android SDK` | install Android Studio, or `flutter config --android-sdk <path>` |

More help: `docs/TROUBLESHOOTING.md`.

## 6. Create or open the project

1. Unzip the project so you have a folder named `confident_me` that contains
   `lib/`, `test/`, `assets/` and `pubspec.yaml`.
2. Open a terminal **inside that folder**:
   ```
   cd confident_me
   ```
3. If the folder does not yet contain `android/` (the zip only has the app code,
   not the generated platform folders), create them:
   ```
   flutter create --org com.example --project-name confident_me .
   ```
   Expected output ends with something like `All done!`. This does not touch
   your `lib/` code. To generate Android only, add `--platforms=android`.
4. `flutter create` adds a sample test that does not belong to this app. Delete
   it, or `flutter analyze` will report an error about `MyApp`:
   ```
   rm test/widget_test.dart
   ```
   (Windows PowerShell: `del test\widget_test.dart`.)
5. Open the folder in VS Code: **File > Open Folder...** and choose
   `confident_me`.

## 7. Install dependencies

```
flutter pub get
```

Expected output ends with:

```
Got dependencies!
```

**Install the app icon (once, after step 6).** The icon artwork is in
`assets/icon/`. This command copies it into the Android project:

```
dart run flutter_launcher_icons
```

Expected output ends with something like `Successfully generated launcher icons`.
Run it again whenever you change the artwork. The icon changes the next time you
install the app (see "App icon did not change" in `docs/TROUBLESHOOTING.md`).

## 8. Connect an Android emulator or phone

**Emulator (easiest):**

1. In Android Studio open **More Actions > Virtual Device Manager**.
2. Click **Create Device**, pick a phone (for example *Pixel 6*), pick a recent
   system image (download it if asked), and finish.
3. Click the play button next to the device to start it.

**Real phone:**

1. On the phone open **Settings > About phone** and tap **Build number** seven
   times to turn on Developer options.
2. Open **Settings > Developer options** and turn on **USB debugging**.
3. Plug the phone into your computer and accept the "Allow USB debugging?"
   prompt on the phone.

Check Flutter can see it:

```
flutter devices
```

Expected output (similar to):

```
2 connected devices:

sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64 • Android 14 (API 34)
Pixel 6 (mobile)             • 1A2B3C4D5E    • android-arm64 • Android 13 (API 33)
```

Nothing listed? See "Emulator not detected" in `docs/TROUBLESHOOTING.md`.

## 9. Run the app with `flutter run`

```
flutter run
```

If more than one device is connected, Flutter asks which to use; type its
number. The first build takes a few minutes. Expected output (similar to):

```
Launching lib/main.dart on sdk gphone64 x86 64 in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk
Syncing files to device ...

Flutter run key commands.
r Hot reload.
R Hot restart.
q Quit (terminate the application on the device).
```

The app opens on the welcome screen. While it runs, press `r` after editing code
to hot reload. **After changing `pubspec.yaml` or anything in `assets/`, press
`q` and run again**; hot reload does not pick those up.

## 10. Run it from VS Code (Run and Debug)

1. Open the `confident_me` folder in VS Code.
2. Pick your device in the blue status bar at the bottom right (it says
   something like *No Device* until you choose one).
3. Open the **Run and Debug** panel (`Ctrl+Shift+D`) and click **Run and Debug**,
   or press `F5`. If asked to choose an environment, choose **Dart & Flutter**.
4. Use the toolbar that appears to hot reload (lightning bolt), hot restart, or
   stop.

## 11. Analyze and test

```
flutter analyze
```

Expected output: `No issues found!`

```
flutter test
```

Expected output ends with: `All tests passed!`

This runs the unit and widget tests in `test/`.

The main-workflow integration test needs a running emulator or phone:

```
flutter test integration_test/app_test.dart -d <device id>
```

Use the device id from `flutter devices` (for example `emulator-5554`). It
installs a test build, walks through onboarding, completes a challenge, writes
a journal entry, restarts the app, and checks everything is still there.

## 12. Create a release build

Debug builds are for development. To build the release version of the app:

```
flutter build apk --release
```

The file appears at `build/app/outputs/flutter-apk/app-release.apk`.

For Google Play you need an app bundle instead:

```
flutter build appbundle --release
```

The file appears at `build/app/outputs/bundle/release/app-release.aab`.

A release meant for other people must be signed with your own key (otherwise it
is signed with a debug key). Signing, Google Play preparation and testing a
release build are covered in `docs/DEPLOYMENT.md`.

## 13. Firebase (optional cloud features)

**Not included in this version.** ConfidentMe is local-only: there is no sign-in,
no cloud sync, no `google-services.json`, and no Firebase setup to do. Nothing
in this guide depends on it. See `docs/DATA_AND_PRIVACY.md` for what that means
for your data.

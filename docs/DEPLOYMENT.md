# Deployment

How to run ConfidentMe on Android, build it for release, sign it, and prepare it
for Google Play.

> **Verification status.** The release steps below follow Flutter's and Google's
> standard process, but a release build and a Play submission have **not** been
> performed for this project. Gradle files and Play Console screens change between
> versions, so where it matters this guide points to the official page. Test your
> own release build (last section) before sharing it.

Start with `docs/SETUP.md` if you have not installed Flutter and Android tools.

## 1. Run on Android

```
flutter devices                # find your emulator or phone
flutter run -d <device id>     # debug build, with hot reload
```

A debug build is slower and larger than a release build and is not meant to be
shared. To see how the app really performs, use a release build on a real phone:

```
flutter run --release -d <device id>
```

## 2. Before you publish: make the project your own

These are one-time edits in the Android project that `flutter create` generated.

1. **Application id.** The default (`com.example.confident_me`) is a placeholder
   and Google Play does not accept `com.example`. Choose your own, such as
   `com.yourname.confidentme`. The easiest way is to do this before the first
   build, when creating the project:
   ```
   flutter create --org com.yourname --project-name confident_me .
   ```
   For a project that already exists, change `applicationId` (and `namespace`) in
   `android/app/build.gradle` (or `build.gradle.kts`). The id can never be
   changed after you publish.
2. **App name.** In `android/app/src/main/AndroidManifest.xml` set
   `android:label="ConfidentMe"` on the `<application>` element.
3. **Icon.** The project includes a lotus icon in `assets/icon/`. Install it with
   `dart run flutter_launcher_icons` (see `docs/SETUP.md`). To use your own
   artwork, replace the three PNGs in `assets/icon/` (or edit and run
   `tool/make_icon.py`) and run the command again. Google Play also needs a
   512 x 512 store icon, which you can export from `assets/icon/icon.png`.
4. **Version.** In `pubspec.yaml`, `version: 0.7.0+7` means version name `0.7.0` and
   build number `7`. **Every upload to Google Play needs a higher build number**
   (the number after `+`). Raise it before each release.
5. **System backup (privacy).** By default Android may include app data in a
   backup tied to the user's Google account. The app tells users it keeps data on
   the device only, so decide deliberately. To switch system backup off, add
   `android:allowBackup="false"` to the `<application>` element in
   `android/app/src/main/AndroidManifest.xml`. See `docs/DATA_AND_PRIVACY.md`.
6. **No internet permission.** The app does not use the network. The release
   manifest (`android/app/src/main/AndroidManifest.xml`) should not contain
   `android.permission.INTERNET`. (Flutter adds it only to the debug and profile
   manifests.)

## 3. Build an APK

An APK installs directly on a phone and is good for testing or sharing outside
Google Play:

```
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

To make smaller files, one per processor type:

```
flutter build apk --release --split-per-abi
```

## 4. Build an Android App Bundle

Google Play requires an app bundle for new apps:

```
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## 5. Configure signing securely

Without a signing setup the release build is signed with a debug key, which Google
Play rejects. Follow Flutter's guide for the exact current steps:
<https://docs.flutter.dev/deployment/android#sign-the-app>

The outline:

1. **Create an upload key** (keep it **outside** the project folder):
   ```
   keytool -genkey -v -keystore ~/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   On Windows PowerShell use `-keystore $env:USERPROFILE\upload-keystore.jks`.
   `keytool` comes with Java (and Android Studio). Choose strong passwords and
   write them somewhere safe.
2. **Create `android/key.properties`** with the key's details:
   ```
   storePassword=<the keystore password>
   keyPassword=<the key password>
   keyAlias=upload
   storeFile=/full/path/to/upload-keystore.jks
   ```
3. **Keep secrets out of version control.** Add these lines to `.gitignore` (the
   project's `.gitignore` or `android/.gitignore`):
   ```
   key.properties
   *.jks
   *.keystore
   ```
4. **Tell Gradle to use it.** In `android/app/build.gradle` (Groovy) or
   `android/app/build.gradle.kts` (Kotlin DSL; newer Flutter versions use this)
   read `key.properties`, add a `release` signing config, and set the `release`
   build type to use it. The exact code differs between the two formats and
   Flutter versions, so copy it from the official page above rather than from
   memory.
5. Rebuild: `flutter build appbundle --release`.

Never put a keystore, a password, or `key.properties` in a screenshot, chat or
repository. If you lose the upload key, Play can reset it (when you use Play App
Signing, which new apps do by default); if you lose the signing key of an app that
manages its own signing, you can never update that app.

## 6. Prepare for Google Play

Google's requirements change, so check the Play Console's current checklist. In
general you will need:

1. **A Play Console developer account** (a one-time registration fee applies) at
   <https://play.google.com/console>.
2. **A new app** in the console, with its default language and name.
3. **Your signed `.aab`**, uploaded first to **Internal testing** so you can install
   it from Play on your own phone before releasing to anyone else.
4. **Store listing:** title, short and full descriptions, a high-resolution icon,
   a feature graphic, and phone screenshots. Describe the app honestly as a
   self-help and confidence-building tool. **Do not claim it treats, cures or
   diagnoses social anxiety or any condition.**
5. **Privacy policy URL.** Publish a short policy page; `docs/DATA_AND_PRIVACY.md`
   is a good basis. It should say the app stores data only on the device, sends
   nothing to a server, and has no analytics.
6. **Data safety form.** Answer it from how the app actually behaves: it collects
   no data and shares none, because everything stays on the device. Re-check this
   against your final build, especially if you add any package that uses the
   network.
7. **Content rating questionnaire** and **target audience.** Think carefully about
   the age range you choose, because choosing a young audience brings extra
   requirements.
8. **App category and any health-related declarations** the console asks for. The
   app makes no medical claims, which keeps these straightforward.
9. **Target API level.** Google requires new apps to target a recent Android API
   level. Current Flutter versions meet this by default; if the console complains,
   upgrade Flutter and rebuild.
10. Roll out gradually (internal, then closed or open testing, then production).

## 7. Firebase and other cloud services

Not part of this version, so there is nothing to configure and no
`google-services.json` to add.

## 8. Test a release build

Do this on a real phone, with a build you made the same way you will publish:

```
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

(`adb` is in the Android SDK's `platform-tools` folder.) Then check:

- **Launch and onboarding:** the welcome screen appears, onboarding and "Continue as
  guest" both work.
- **Core flow:** complete a challenge, see the XP and any celebration dialog, open
  Progress.
- **Persistence:** swipe the app away, reopen it, and confirm your progress,
  journal entry and settings are still there.
- **Breathing:** start, pause, resume, stop, and let one short session finish.
- **Journal:** create, edit and delete an entry.
- **Settings:** switch theme and color, try the reminder card, copy your data, and
  try reset and delete (on test data only).
- **Looks:** rotate the screen, try a small phone or emulator, try the largest font
  size in Android's display settings, and try dark mode.
- **Accessibility:** turn on TalkBack for a minute and move through Home and a
  challenge.
- **Permissions:** open the app's info page in Android settings; it should list no
  permissions.

You can also run the end-to-end test against a device:
`flutter test integration_test/app_test.dart -d <device id>`.

## Platform-specific limitations

- **Android only has been considered.** The `ios/` folder that `flutter create`
  generates is untouched and untested. Publishing to the App Store needs a Mac,
  Xcode and an Apple Developer account, and the steps are not covered here.
- **Reminders are in-app only.** The app does not schedule phone notifications, so
  it asks for no notification permission.
- **Export is by clipboard.** There is no file save or share sheet.
- **System backup** may include app data unless you disable it (section 2).
- **No cloud sync.** Data lives on one device and is lost if the app's data is
  cleared.

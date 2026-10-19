# ConfidentMe

*Confidence grows through practice, not perfection.*

ConfidentMe is a Flutter app that helps people take small, optional steps toward
feeling more comfortable in social situations. It combines gentle challenges,
guided breathing, conversation practice, affirmations and a private journal, with
a supportive, non-judgmental tone and a simple record of effort (not a score).

It is **local-first**: no account, no analytics, no server. Everything stays on the
device.

> ConfidentMe is a self-help and confidence-building tool. It is not a substitute
> for professional mental health care, and it does not diagnose, treat or cure
> social anxiety disorder or any other condition.

## Features

- **Onboarding** with five optional questions, guest mode, and the option to
  change answers later
- **28 challenges** in 8 categories, filterable by category and difficulty, with
  steps, preparation, a reflection prompt, and the reward shown before you begin.
  Complete, skip, postpone, make easier, or repeat any of them
- **Daily suggestion** chosen by documented, deterministic rules (not AI)
- **Guided breathing** (4-4-6 with an optional hold, presets and custom timings,
  start / pause / resume / stop, driven by elapsed time)
- **Conversation practice**: 9 local scenarios with starters, follow-up questions,
  listening tips and a step-by-step rehearsal (nothing you type is saved)
- **Affirmations**: 24 bundled, favorites, themes, and your own
- **Private journal** with six reflective prompts, autosave, edit and delete
- **XP, levels, streaks, achievements and personal milestones**, all optional to
  display. XP only ever goes up
- **Progress**: weekly activity calendar, categories explored, milestones,
  achievements, XP history
- **Settings**: light / dark / system and five color palettes, preferred
  difficulty, daily suggestion switch, a gentle in-app reminder, privacy
  information, copy-my-data export, reset progress, delete all data

## Quick start

Full instructions with expected output are in `docs/SETUP.md`. In short:

```
cd confident_me
flutter create --org com.example --project-name confident_me .   # first time only
rm test/widget_test.dart                                          # sample test that does not belong here
flutter pub get
flutter run
```

```
flutter analyze
flutter test
flutter test integration_test/app_test.dart -d <device id>        # needs an emulator or phone
flutter build apk --release
```

## App icon

A white lotus with a small teal dot (one small step) on a lavender gradient, to
match the welcome screen. After `flutter pub get`, install it into the Android
project with `dart run flutter_launcher_icons`. The artwork is in `assets/icon/`.

## Documentation

| File | What it covers |
| --- | --- |
| `docs/SETUP.md` | installing Flutter and Android tools, running, testing, release builds |
| `docs/USER_GUIDE.md` | how to use every part of the app |
| `docs/ARCHITECTURE.md` | folder structure, state, routing, data, how to add a feature (with diagrams) |
| `docs/DATA_AND_PRIVACY.md` | what is stored, where, export, deletion, security limits |
| `docs/TROUBLESHOOTING.md` | common problems and exact fixes |
| `docs/DEPLOYMENT.md` | release builds, signing, Google Play preparation |

## Project layout

```
lib/            app code (core, models, data, features, shared)
assets/data/    bundled challenges, scenarios and affirmations (JSON)
test/           unit and widget tests
integration_test/  end-to-end test of the main workflow
docs/           documentation
```

## Technology

Flutter, Dart, Material 3, Riverpod (state management), GoRouter (navigation),
SharedPreferences (settings and progress), Hive (journal, practice history and
your own affirmations). No Firebase and no network use in this version.

## Verification status (please read)

This project was written without access to a Flutter SDK, so the author could not
run `flutter analyze`, `flutter test`, the integration test or a release build
while writing it. Early versions were run and reported working by the project
owner; later additions (breathing, practice, journal, affirmations, settings, data
export and deletion, color palettes, and these docs) have not been confirmed by a
run. Run `flutter analyze` and `flutter test` first and fix anything they report.
The package versions in `pubspec.yaml` were also not checked against pub.dev.

## Known limitations

- Android is the intended target. iOS is untested.
- Reminders are in-app cards only; the app does not send phone notifications.
- Export is copy-to-clipboard; there is no import, file save or share sheet.
- No cloud sync, accounts or backup of its own. Uninstalling or clearing app data
  deletes everything.
- The app adds no encryption of its own and has no app lock.
- Choices such as "make this easier" suggestions, scenarios and affirmations are
  written content; they are examples, not clinical advice and not predictions of
  how real people will respond.

## Recommended next steps

- Run the full test suite and the integration test on a real phone, and try the
  release checklist in `docs/DEPLOYMENT.md`.
- Add real notifications (a local-notifications plugin plus Android setup) if you
  want phone reminders.
- Add a file export or share sheet and an import feature.
- Consider optional, opt-in cloud sync only with explicit consent for sensitive
  data (journal), proper authentication and server-side access rules.
- Translate the content and add localisation.
- Have the wording reviewed by someone with mental-health expertise before
  publishing widely.

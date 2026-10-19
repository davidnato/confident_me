# Data and privacy

This describes exactly what ConfidentMe stores, where, and how to remove it.
It describes the app as built: a **local-only** app. If the code changes, update
this file.

## The short version

- Everything you enter stays **on your device**.
- **Nothing is sent to a server.** The app makes no network requests, has no
  accounts, no analytics, no advertising and no tracking.
- You can **copy** all of your data out, **reset** your progress, or **delete
  everything**, any time, from Settings.
- Uninstalling the app or clearing its data **permanently deletes** it. There is
  no cloud copy in this app.
- The app does **not** add its own encryption.

## What is stored

| Information | Where | Storage name |
| --- | --- | --- |
| Profile: name or nickname (optional), chosen situations, improvement focus, "how challenging" answer (1 to 5), small goal, starting difficulty | SharedPreferences | `user_profile_v1` |
| Settings: theme, color palette, difficulty, daily-suggestion switch, reminder switch and time, show/hide XP | SharedPreferences | `app_settings_v1` |
| Challenge attempts: which challenge, status, dates, your optional reflection, XP earned | SharedPreferences | `challenge_progress_v1` |
| XP history | SharedPreferences | `xp_ledger_v1` |
| Achievements earned and when | SharedPreferences | `earned_achievements_v1` |
| Personal milestones you wrote | SharedPreferences | `milestones_v1` |
| Favorite affirmations and chosen affirmation themes | SharedPreferences | `affirmation_favorites_v1`, `affirmation_categories_v1` |
| Which day you tapped "Not today" on the reminder | SharedPreferences | `reminder_dismissed_on_v1` |
| **Journal entries** | Hive database | box `journal_entries` |
| Finished practice sessions (type, scenario, date, XP) | Hive database | box `practice_sessions` |
| Affirmations you wrote | Hive database | box `custom_affirmations` |

SharedPreferences and Hive both keep their files inside the app's **private
storage area**, which other apps cannot normally read.

What is **not** stored: anything you type while rehearsing a conversation, your
location, contacts, photos, microphone or camera data, a device identifier, or an
advertising id. The challenge, scenario and affirmation libraries are bundled
with the app (`assets/data/`) and contain no personal information.

Names, goals and journal entries can be sensitive. You decide what to write, and
every field is optional.

## Is anything sent to a server?

No. The app has no code that contacts a server, and no account system. The
release build does not need internet access. (Flutter's generated debug and
profile manifests include the internet permission so development tools can
connect; check that your release `AndroidManifest.xml` does not add it.)

## Exporting your data

**Settings > Your data > Copy my data** asks you to confirm, then copies one block
of JSON text to the clipboard. It contains everything above (profile, settings,
challenge attempts, XP history, achievements, milestones, practice sessions,
journal entries, your affirmations, favorites and themes), plus the app version
and the date of the export. Paste it into a notes app or an email to yourself.

Things to know:

- It **includes your private journal**. Anyone who can read the copied text can
  read it. Paste it somewhere safe and clear the clipboard afterwards if you wish.
- On some systems other apps can read the clipboard.
- Export only; there is no import feature yet.

## Deleting your data

| Action | What it removes | What it keeps |
| --- | --- | --- |
| **Reset progress** | challenge attempts, XP, levels, achievements, milestones, practice history | journal, your own affirmations, favorites and themes, settings, profile |
| **Delete all my data** | everything listed in "What is stored", then returns to the welcome screen | nothing |
| Clear the app's storage in Android settings, or uninstall | everything on the device | nothing |

Both in-app actions ask for confirmation first, and "Delete all my data" needs you
to type `DELETE`. Neither can be undone, so copy your data first if you want a
record. "Delete all" removes the Hive database contents as well as the
SharedPreferences records.

## Limits of local-only storage

- **No backup from this app.** If you lose or reset your phone, or uninstall the
  app, your data is gone unless you copied it out.
- **Your phone's own backup may include it.** By default Android's system backup
  can include an app's private data in a backup tied to your Google account,
  depending on your device settings. This is the phone's feature, not the app's.
  If you do not want that, turn it off in your device settings, or (if you build
  the app yourself) set `android:allowBackup="false"` in
  `android/app/src/main/AndroidManifest.xml`.
- **No sync between devices.** Each device has its own separate data.

## Security limitations

- **No encryption inside the app.** Journal entries and other data are stored as
  readable JSON. They are protected by your phone's lock screen, its disk
  encryption (if enabled) and Android's per-app storage. The app does not claim
  end-to-end encryption and does not provide it.
- **No app lock.** Anyone who can unlock your phone and open the app can read your
  journal. Consider a phone lock screen.
- A phone that is rooted or has malware may allow other software to read app
  data.
- Screenshots and the screen-recording of your phone can capture what is on screen.

## Cloud sync and accounts

Not included. The code is organised so that storage sits behind small interfaces
(see `docs/ARCHITECTURE.md`), which would make adding an optional, opt-in sync
possible later. Any such feature would need its own consent step, authentication,
and server-side access rules before it could be called private, and this document
would need to change.

## A note on wellbeing

ConfidentMe is a self-help tool. It does not collect health information on
purpose and it never calls anything a diagnosis or a score. If something you are
experiencing worries you, please speak to a doctor or a mental health
professional.

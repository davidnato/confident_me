# ConfidentMe

*Confidence grows through practice, not perfection.*

A Flutter app for gradually building confidence in social situations through
small optional challenges, breathing exercises, conversation practice, and
private journaling. Local-first: no account, no analytics, no servers.

ConfidentMe is a self-help tool, not a substitute for professional mental
health care.

## Status: Phase 2 of 7

Working now
- Welcome screen, guest mode, optional 5-step onboarding (editable from Home)
- Challenge library: 28 bundled challenges (`assets/data/challenges.json`),
  8 categories, filter by category and difficulty
- Challenge details: preparation, steps, reflection prompt, reward shown up front
- Start, complete (with optional reflection), skip, postpone to tomorrow,
  "Make this easier", and "Do it again". A completion is recorded once per attempt.
- Home dashboard: today's suggestion ("Try one small step"), daily affirmation,
  completed count, categories explored, recent completions
- Daily suggestion from fixed, documented rules (not AI) - see
  `lib/features/challenges/daily_planner.dart`
- Progress saved locally and restored after restart

Not built yet
- XP, levels, streaks, achievements (Phase 3). XP amounts are displayed but not
  yet awarded.
- Breathing, social practice, journal, full affirmations (Phase 4)
- Progress page, settings, export/delete (Phase 5)
- Practice, Journal and Progress tabs are labelled placeholders

## Setup

    flutter create --org com.example --project-name confident_me .
    flutter pub get

`flutter create` adds `test/widget_test.dart`; delete it (it references `MyApp`).

    flutter analyze
    flutter test
    flutter run

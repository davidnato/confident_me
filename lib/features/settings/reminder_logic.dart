import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/clock.dart';
import '../../data/providers.dart';
import '../../models/app_settings.dart';
import '../gamification/gamification_providers.dart';
import '../settings_controller.dart';

/// `2026-10-18` style key for a calendar day (local time).
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The gentle in-app reminder. It appears on Home, only when:
///  - reminders are switched on,
///  - the chosen time of day has passed,
///  - nothing has been done today (no step, practice, or journal entry), and
///  - the person has not tapped "Not today".
/// It never repeats, never counts anything, and never uses guilt.
bool shouldShowReminder({
  required AppSettings settings,
  required DateTime now,
  required bool activeToday,
  required String? dismissedOn,
}) {
  if (!settings.remindersEnabled) return false;
  if (activeToday) return false;
  if (dismissedOn == dayKey(now)) return false;
  final minutesNow = now.hour * 60 + now.minute;
  return minutesNow >= settings.reminderMinutes;
}

const reminderMessage =
    'Would you like to try one small confidence-building activity today?';

/// Remembers which day "Not today" was tapped, so it stays hidden until tomorrow.
class ReminderDismissController extends Notifier<String?> {
  static const storageKey = 'reminder_dismissed_on_v1';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  String? build() => _prefs.getString(storageKey);

  Future<void> dismissToday() async {
    final key = dayKey(ref.read(clockProvider)());
    state = key;
    await _prefs.setString(storageKey, key);
  }

  Future<void> clearAll() async {
    state = null;
    await _prefs.remove(storageKey);
  }
}

final reminderDismissProvider =
    NotifierProvider<ReminderDismissController, String?>(
  ReminderDismissController.new,
);

final reminderVisibleProvider = Provider<bool>((ref) {
  final now = ref.watch(clockProvider)();
  final activeToday = ref
      .watch(activityDatesProvider)
      .any((d) => d.year == now.year && d.month == now.month && d.day == now.day);
  return shouldShowReminder(
    settings: ref.watch(settingsProvider),
    now: now,
    activeToday: activeToday,
    dismissedOn: ref.watch(reminderDismissProvider),
  );
});

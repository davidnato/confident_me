import 'package:confident_me/features/settings/reminder_logic.dart';
import 'package:confident_me/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const on = AppSettings(remindersEnabled: true, reminderMinutes: 19 * 60);

  bool show({
    AppSettings settings = on,
    DateTime? now,
    bool activeToday = false,
    String? dismissedOn,
  }) =>
      shouldShowReminder(
        settings: settings,
        now: now ?? DateTime(2026, 10, 18, 20),
        activeToday: activeToday,
        dismissedOn: dismissedOn,
      );

  test('shows after the chosen time when nothing was done today', () {
    expect(show(), isTrue);
    expect(show(now: DateTime(2026, 10, 18, 19, 0)), isTrue);
  });

  test('stays hidden before the chosen time', () {
    expect(show(now: DateTime(2026, 10, 18, 18, 59)), isFalse);
  });

  test('stays hidden when reminders are off (the default)', () {
    expect(show(settings: const AppSettings()), isFalse);
    expect(const AppSettings().remindersEnabled, isFalse);
  });

  test('stays hidden once something was done today', () {
    expect(show(activeToday: true), isFalse);
  });

  test('stays hidden for the rest of the day after "Not today"', () {
    expect(show(dismissedOn: '2026-10-18'), isFalse);
    expect(show(dismissedOn: '2026-10-17'), isTrue);
  });

  test('dayKey pads month and day', () {
    expect(dayKey(DateTime(2026, 3, 5)), '2026-03-05');
    expect(dayKey(DateTime(2026, 12, 31)), '2026-12-31');
  });

  test('the message is supportive and not shaming', () {
    expect(reminderMessage,
        'Would you like to try one small confidence-building activity today?');
    for (final bad in ['missed', 'failed', 'should have', 'streak', 'lost']) {
      expect(reminderMessage.toLowerCase(), isNot(contains(bad)));
    }
  });

  test('settings from before reminders had a time still load', () {
    final s = AppSettings.fromJson({'remindersEnabled': true});
    expect(s.reminderMinutes, AppSettings.defaultReminderMinutes);
    expect(s.remindersEnabled, isTrue);
  });

  test('reminder time round-trips and is kept within a day', () {
    const s = AppSettings(reminderMinutes: 8 * 60 + 30);
    expect(AppSettings.fromJson(s.toJson()).reminderMinutes, 510);
    expect(
        AppSettings.fromJson({'reminderMinutes': 99999}).reminderMinutes, 1439);
    expect(AppSettings.fromJson({'reminderMinutes': -5}).reminderMinutes, 0);
  });
}

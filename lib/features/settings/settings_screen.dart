import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/difficulty.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/soft_card.dart';
import '../settings_controller.dart';
import 'data_management_service.dart';
import 'reminder_logic.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            text,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heading('Appearance'),
                        SegmentedButton<ThemeMode>(
                          key: const Key('theme_selector'),
                          segments: const [
                            ButtonSegment(
                                value: ThemeMode.system, label: Text('System')),
                            ButtonSegment(
                                value: ThemeMode.light, label: Text('Light')),
                            ButtonSegment(
                                value: ThemeMode.dark, label: Text('Dark')),
                          ],
                          selected: {settings.themeMode},
                          onSelectionChanged: (s) =>
                              controller.setThemeMode(s.first),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heading('Challenges'),
                        Text('Preferred difficulty',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Used to choose your daily suggestion. You can still '
                          'open any challenge, and "Make this easier" is always there.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final d in Difficulty.values)
                              ChoiceChip(
                                label: Text(d.label),
                                selected: settings.preferredDifficulty == d,
                                onSelected: (_) =>
                                    controller.setPreferredDifficulty(d),
                              ),
                          ],
                        ),
                        SwitchListTile(
                          key: const Key('daily_challenge_switch'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Suggest a challenge each day'),
                          subtitle: const Text(
                              'Turn off to browse the library on your own terms.'),
                          value: settings.dailyChallengeEnabled,
                          onChanged: controller.setDailyChallengeEnabled,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heading('Reminders'),
                        SwitchListTile(
                          key: const Key('reminder_switch'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Gentle daily reminder'),
                          subtitle: const Text(
                              'Optional. Off by default, and never sent as a phone notification.'),
                          value: settings.remindersEnabled,
                          onChanged: controller.setRemindersEnabled,
                        ),
                        if (settings.remindersEnabled) ...[
                          ListTile(
                            key: const Key('reminder_time'),
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Reminder time'),
                            subtitle: Text(TimeOfDay(
                              hour: settings.reminderMinutes ~/ 60,
                              minute: settings.reminderMinutes % 60,
                            ).format(context)),
                            trailing: const Icon(Icons.schedule_rounded),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: settings.reminderMinutes ~/ 60,
                                  minute: settings.reminderMinutes % 60,
                                ),
                              );
                              if (picked != null) {
                                await controller.setReminderMinutes(
                                    picked.hour * 60 + picked.minute);
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          Text('What it says:',
                              style: theme.textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text('"$reminderMessage"',
                              style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          Text(
                            'It appears on the Home screen after this time, only '
                            'if you have not done anything yet today, and you can '
                            'tap "Not today" to hide it. Phone notifications are '
                            'not set up in this version.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SoftCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: SwitchListTile(
                      key: const Key('settings_gamification_switch'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show XP, levels and streaks'),
                      subtitle: const Text(
                          'Your progress is always saved. This only changes what you see.'),
                      value: settings.gamificationEnabled,
                      onChanged: controller.setGamificationEnabled,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _PrivacyCard(),
                  const SizedBox(height: 16),
                  const _DataCard(),
                  const SizedBox(height: 16),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heading('About'),
                        Text('${AppConstants.appName}  ·  version ${AppConstants.version}',
                            key: const Key('about_version'),
                            style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        Text(AppConstants.philosophy,
                            style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Text(AppConstants.selfHelpDisclaimer,
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget item(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2, right: 8),
                child: Icon(Icons.circle, size: 6),
              ),
              Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
            ],
          ),
        );

    return SoftCard(
      child: Column(
        key: const Key('privacy_card'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Privacy',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          item('Everything you enter stays on this device. No account is '
              'needed and nothing is sent to a server.'),
          item('There are no analytics or tracking.'),
          item('Your journal, practice history and your own affirmations are '
              'kept in a private database inside the app. Your progress and '
              'settings are kept in the app\'s private preferences.'),
          item('The app does not add its own encryption. Your data is protected '
              'by your phone\'s lock screen and the app\'s private storage, '
              'not by a password inside the app.'),
          item('Uninstalling the app or clearing its data permanently deletes '
              'everything. There is no cloud backup, so export a copy below if '
              'you want to keep one.'),
        ],
      ),
    );
  }
}

class _DataCard extends ConsumerWidget {
  const _DataCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final service = ref.read(dataManagementServiceProvider);

    Future<void> export() async {
      final ok = await confirmDialog(
        context,
        title: 'Copy my data?',
        message: 'This copies a full copy of your data to the clipboard, '
            'including your private journal. Anyone who can see the copied '
            'text can read it, so paste it somewhere safe.',
        confirmLabel: 'Copy',
      );
      if (!ok) return;
      final json = service.exportJson();
      await Clipboard.setData(ClipboardData(text: json));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Copied ${json.length} characters. Paste it into a '
              'notes app or an email to yourself.'),
        ));
    }

    Future<void> reset() async {
      final ok = await confirmDialog(
        context,
        title: 'Reset your progress?',
        message: 'This clears your challenge history, XP, levels, '
            'achievements, milestones and practice history. Your journal, '
            'your own affirmations, your settings and your profile are kept. '
            'This cannot be undone.',
        confirmLabel: 'Reset progress',
      );
      if (!ok) return;
      await service.resetProgress();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('Progress reset. A fresh start.')));
    }

    Future<void> deleteAll() async {
      final ok = await typedConfirmDialog(
        context,
        title: 'Delete all your data?',
        message: 'This permanently deletes everything stored by ConfidentMe '
            'on this device: your profile, settings, progress, journal '
            'entries and affirmations. It cannot be undone, so consider '
            'copying your data first.',
        word: 'DELETE',
        confirmLabel: 'Delete everything',
      );
      if (!ok) return;
      await service.deleteAllData();
    }

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your data',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('export_button'),
            onPressed: export,
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy my data'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('reset_button'),
            onPressed: reset,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset progress'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('delete_button'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: deleteAll,
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Delete all my data'),
          ),
        ],
      ),
    );
  }
}

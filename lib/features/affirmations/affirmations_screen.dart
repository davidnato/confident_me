import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/affirmation.dart';
import '../../shared/widgets/async_states.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/soft_card.dart';
import 'affirmation_providers.dart';

class AffirmationsScreen extends ConsumerStatefulWidget {
  const AffirmationsScreen({super.key});

  @override
  ConsumerState<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends ConsumerState<AffirmationsScreen> {
  final _controller = TextEditingController();
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final added =
        await ref.read(customAffirmationsProvider.notifier).add(_controller.text);
    if (added != null) _controller.clear();
  }

  Future<void> _delete(Affirmation a) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete this affirmation?',
      message: 'This removes "${a.text}" from your list.',
      confirmLabel: 'Delete',
    );
    if (ok) {
      await ref.read(customAffirmationsProvider.notifier).remove(a.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loading = ref.watch(affirmationsProvider);
    final all = ref.watch(allAffirmationsProvider);
    final prefs = ref.watch(affirmationPrefsProvider);
    final today = ref.watch(todaysAffirmationProvider);

    var visible = prefs.categories.isEmpty
        ? all
        : all.where((a) => prefs.categories.contains(a.category)).toList();
    if (_favoritesOnly) {
      visible = visible.where((a) => prefs.favoriteIds.contains(a.id)).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Affirmations')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: loading.when(
              loading: () => const LoadingView(),
              error: (_, __) => ErrorView(
                message: 'The affirmations could not be loaded.',
                onRetry: () => ref.invalidate(affirmationsProvider),
              ),
              data: (_) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (today != null)
                      SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Today's affirmation",
                                style: theme.textTheme.labelLarge),
                            const SizedBox(height: 4),
                            Text(today.text, style: theme.textTheme.titleMedium),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text('Themes I would like',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Choose any to shape your daily affirmation and this list. '
                      'Choose none to see everything.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in affirmationCategories.entries)
                          FilterChip(
                            label: Text(entry.value),
                            selected: prefs.categories.contains(entry.key),
                            onSelected: (_) => ref
                                .read(affirmationPrefsProvider.notifier)
                                .toggleCategory(entry.key),
                          ),
                        FilterChip(
                          label: const Text('Favorites only'),
                          avatar: const Icon(Icons.favorite_rounded, size: 16),
                          selected: _favoritesOnly,
                          onSelected: (v) => setState(() => _favoritesOnly = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Write your own',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            'Keep it realistic and kind, something you can believe '
                            'on a hard day.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('affirmation_field'),
                            controller: _controller,
                            maxLength: maxCustomAffirmationLength,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                                labelText: 'My affirmation'),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size(140, 48)),
                              onPressed: _add,
                              child: const Text('Add affirmation'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (visible.isEmpty)
                      SoftCard(
                        child: Text(
                          _favoritesOnly
                              ? 'No favorites here yet. Tap the heart on any affirmation to keep it.'
                              : 'Nothing matches these themes yet.',
                        ),
                      )
                    else
                      for (final a in visible)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SoftCard(
                            padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
                            child: Row(
                              children: [
                                Expanded(child: Text(a.text)),
                                IconButton(
                                  tooltip: prefs.favoriteIds.contains(a.id)
                                      ? 'Remove from favorites'
                                      : 'Add to favorites',
                                  icon: Icon(
                                    prefs.favoriteIds.contains(a.id)
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                  onPressed: () => ref
                                      .read(affirmationPrefsProvider.notifier)
                                      .toggleFavorite(a.id),
                                ),
                                if (a.category == customCategoryId)
                                  IconButton(
                                    tooltip: 'Delete affirmation',
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    onPressed: () => _delete(a),
                                  ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

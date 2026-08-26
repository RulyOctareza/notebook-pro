import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:notebook_pro/core/theme/app_spacing.dart';
import 'package:notebook_pro/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:notebook_pro/features/notes/presentation/providers/notes_providers.dart';
import 'package:notebook_pro/features/settings/presentation/providers/app_prefs_providers.dart';
import 'package:notebook_pro/features/settings/presentation/providers/theme_mode_provider.dart';

class SettingsDialog {
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const _SettingsDialog(),
    );
  }
}

class _SettingsDialog extends ConsumerWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final sort = ref.watch(noteSortProvider);
    final profile = ref.watch(gamificationProfileProvider).valueOrNull;
    final goal = profile?.weeklyWordsGoal ?? 500;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Settings', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView(
                  children: [
                    Text('Appearance', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_outlined, size: 16),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (s) =>
                          ref.read(themeModeProvider.notifier).setMode(s.first),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Note sort', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<NoteSortOption>(
                      initialValue: sort,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: NoteSortOption.updatedDesc,
                          child: Text('Newest updated'),
                        ),
                        DropdownMenuItem(
                          value: NoteSortOption.updatedAsc,
                          child: Text('Oldest updated'),
                        ),
                        DropdownMenuItem(
                          value: NoteSortOption.createdDesc,
                          child: Text('Newest created'),
                        ),
                        DropdownMenuItem(
                          value: NoteSortOption.titleAsc,
                          child: Text('Title A–Z'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          ref.read(noteSortProvider.notifier).setSort(v);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Weekly writing goal', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '$goal words / week',
                      style: theme.textTheme.bodySmall,
                    ),
                    Slider(
                      value: goal.toDouble().clamp(100, 5000),
                      min: 100,
                      max: 5000,
                      divisions: 49,
                      label: '$goal',
                      onChanged: (v) {
                        ref
                            .read(gamificationRepositoryProvider)
                            .setWeeklyWordsGoal(v.round());
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Backup', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final path = await ref
                                .read(backupServiceProvider)
                                .exportBackup();
                            if (context.mounted && path != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Backup saved: $path')),
                              );
                            }
                          },
                          icon: const Icon(Icons.upload_outlined, size: 16),
                          label: const Text('Export backup'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final count = await ref
                                .read(backupServiceProvider)
                                .importBackup();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    count == 0
                                        ? 'Import cancelled'
                                        : 'Imported $count notes',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.download_outlined, size: 16),
                          label: const Text('Import backup'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Shortcuts', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '⌘N New note · ⌘K Command palette · ⌘E Export\n'
                      '⌘D Move to Trash · ⌘F Find in note · ⌘⇧F Focus mode\n'
                      '⌘B Bold · ⌘I Italic · ⌘U Underline · ⌘, Settings',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

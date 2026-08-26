import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:notebook_pro/core/theme/app_colors.dart';
import 'package:notebook_pro/core/theme/app_spacing.dart';
import 'package:notebook_pro/features/notes/domain/entities/note.dart';
import 'package:notebook_pro/features/notes/domain/note_importer.dart';
import 'package:notebook_pro/features/notes/presentation/providers/notes_providers.dart';
import 'package:notebook_pro/features/notes/presentation/widgets/export_note_dialog.dart';
import 'package:notebook_pro/features/settings/presentation/providers/app_prefs_providers.dart';
import 'package:notebook_pro/features/settings/presentation/providers/editor_zoom_provider.dart';
import 'package:notebook_pro/features/settings/presentation/providers/folder_sidebar_visible_provider.dart';
import 'package:notebook_pro/features/settings/presentation/providers/note_list_visible_provider.dart';
import 'package:notebook_pro/features/settings/presentation/providers/theme_mode_provider.dart';
import 'package:notebook_pro/features/settings/presentation/widgets/settings_dialog.dart';

class CommandPaletteDialog extends ConsumerStatefulWidget {
  const CommandPaletteDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => const CommandPaletteDialog(),
    );
  }

  @override
  ConsumerState<CommandPaletteDialog> createState() =>
      _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends ConsumerState<CommandPaletteDialog> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final total = _calculateTotalItems();
      if (total > 0) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % total;
        });
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final total = _calculateTotalItems();
      if (total > 0) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + total) % total;
        });
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      _executeSelected();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  int _calculateTotalItems() {
    final query = _searchController.text.trim().toLowerCase();
    final commands = _getFilteredCommands(query);
    final notes = _getFilteredNotes(query);
    return commands.length + notes.length;
  }

  List<_PaletteCommand> _getFilteredCommands(String query) {
    final all = <_PaletteCommand>[
      _PaletteCommand(
        id: 'new_note',
        title: 'New Note',
        subtitle: 'Create a new blank note',
        icon: Icons.note_add_outlined,
        shortcut: '⌘N',
        onRun: () async {
          Navigator.of(context).pop();
          final note = await ref.read(noteRepositoryProvider).create();
          ref.read(selectedNoteIdProvider.notifier).state = note.id;
        },
      ),
      _PaletteCommand(
        id: 'export_note',
        title: 'Export Note (PDF, Markdown, Text)',
        subtitle: 'Export active note in multiple formats',
        icon: Icons.ios_share_outlined,
        shortcut: '⌘E',
        onRun: () async {
          Navigator.of(context).pop();
          final selectedId = ref.read(selectedNoteIdProvider);
          if (selectedId != null) {
            final note = await ref.read(noteRepositoryProvider).getById(selectedId);
            if (note != null && mounted) {
              await ExportNoteDialog.show(context, note);
            }
          }
        },
      ),
      _PaletteCommand(
        id: 'toggle_pin',
        title: 'Pin / Unpin Note',
        subtitle: 'Toggle pin on selected note',
        icon: Icons.push_pin_outlined,
        onRun: () async {
          Navigator.of(context).pop();
          final selectedId = ref.read(selectedNoteIdProvider);
          if (selectedId != null) {
            await ref.read(noteRepositoryProvider).togglePin(selectedId);
          }
        },
      ),
      _PaletteCommand(
        id: 'toggle_theme',
        title: 'Switch Color Theme',
        subtitle: 'Cycle through Light / Dark / System mode',
        icon: Icons.palette_outlined,
        onRun: () {
          Navigator.of(context).pop();
          ref.read(themeModeProvider.notifier).cycle();
        },
      ),
      _PaletteCommand(
        id: 'zoom_in',
        title: 'Zoom In Editor',
        subtitle: 'Increase editor display scale',
        icon: Icons.zoom_in,
        shortcut: '⌘+',
        onRun: () {
          Navigator.of(context).pop();
          ref.read(editorZoomProvider.notifier).zoomIn();
        },
      ),
      _PaletteCommand(
        id: 'zoom_out',
        title: 'Zoom Out Editor',
        subtitle: 'Decrease editor display scale',
        icon: Icons.zoom_out,
        shortcut: '⌘-',
        onRun: () {
          Navigator.of(context).pop();
          ref.read(editorZoomProvider.notifier).zoomOut();
        },
      ),
      _PaletteCommand(
        id: 'zoom_reset',
        title: 'Reset Zoom (100%)',
        subtitle: 'Restore normal scale',
        icon: Icons.restart_alt,
        shortcut: '⌘0',
        onRun: () {
          Navigator.of(context).pop();
          ref.read(editorZoomProvider.notifier).reset();
        },
      ),
      _PaletteCommand(
        id: 'focus_mode',
        title: 'Toggle Focus Mode',
        subtitle: 'Hide sidebars for distraction-free writing',
        icon: Icons.fullscreen,
        shortcut: '⌘⇧F',
        onRun: () {
          Navigator.of(context).pop();
          final next = !ref.read(focusModeProvider);
          ref.read(focusModeProvider.notifier).setEnabled(next);
          ref.read(folderSidebarVisibleProvider.notifier).setVisible(!next);
          ref.read(noteListVisibleProvider.notifier).setVisible(!next);
        },
      ),
      _PaletteCommand(
        id: 'settings',
        title: 'Open Settings',
        subtitle: 'Theme, sort, backup, weekly goal',
        icon: Icons.settings_outlined,
        shortcut: '⌘,',
        onRun: () {
          Navigator.of(context).pop();
          SettingsDialog.show(context);
        },
      ),
      _PaletteCommand(
        id: 'find_in_note',
        title: 'Find in Note',
        subtitle: 'Search within the active note',
        icon: Icons.search,
        shortcut: '⌘F',
        onRun: () {
          Navigator.of(context).pop();
          ref.read(findInNoteVisibleProvider.notifier).state = true;
        },
      ),
      _PaletteCommand(
        id: 'import_markdown',
        title: 'Import Markdown',
        subtitle: 'Create a note from a .md file',
        icon: Icons.upload_file_outlined,
        onRun: () async {
          Navigator.of(context).pop();
          final file = await openFile(
            acceptedTypeGroups: [
              const XTypeGroup(
                label: 'Markdown',
                extensions: ['md', 'markdown', 'txt'],
              ),
            ],
          );
          if (file == null) return;
          final content = await File(file.path).readAsString();
          final note = NoteImporter.fromMarkdown(content);
          await ref.read(noteRepositoryProvider).update(note);
          ref.read(selectedNoteIdProvider.notifier).state = note.id;
        },
      ),
    ];

    if (query.isEmpty) return all;
    return all
        .where(
          (c) =>
              c.title.toLowerCase().contains(query) ||
              c.subtitle.toLowerCase().contains(query),
        )
        .toList();
  }

  List<Note> _getFilteredNotes(String query) {
    final allNotes = ref.watch(notesListProvider).valueOrNull ?? const [];
    if (query.isEmpty) {
      // Show up to 5 recent notes if no query
      return allNotes.take(5).toList();
    }
    return allNotes
        .where(
          (n) =>
              n.title.toLowerCase().contains(query) ||
              n.plainTextPreview.toLowerCase().contains(query) ||
              n.tags.any((t) => t.toLowerCase().contains(query)),
        )
        .take(10)
        .toList();
  }

  void _executeSelected() {
    final query = _searchController.text.trim().toLowerCase();
    final commands = _getFilteredCommands(query);
    final notes = _getFilteredNotes(query);

    if (_selectedIndex < commands.length) {
      commands[_selectedIndex].onRun();
    } else {
      final noteIndex = _selectedIndex - commands.length;
      if (noteIndex < notes.length) {
        final note = notes[noteIndex];
        Navigator.of(context).pop();
        ref.read(selectedNoteIdProvider.notifier).state = note.id;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canvas = isDark ? AppColors.darkCanvas : AppColors.lightCanvas;
    final selection = isDark ? AppColors.darkSelection : AppColors.lightSelection;

    final query = _searchController.text.trim().toLowerCase();
    final commands = _getFilteredCommands(query);
    final notes = _getFilteredNotes(query);

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 580,
            constraints: const BoxConstraints(maxHeight: 480),
            decoration: BoxDecoration(
              color: canvas,
              borderRadius: BorderRadius.circular(AppRadii.md),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 20, color: Colors.grey),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'Type a command or search notes… (⌘K)',
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => _searchController.clear(),
                            visualDensity: VisualDensity.compact,
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ESC',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.colorScheme.outline),

                  // Results list
                  Flexible(
                    child: (commands.isEmpty && notes.isEmpty)
                        ? Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: Center(
                              child: Text(
                                'No matching commands or notes found.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          )
                        : ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            children: [
                              if (commands.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.md,
                                    AppSpacing.xs,
                                    AppSpacing.md,
                                    AppSpacing.xs,
                                  ),
                                  child: Text(
                                    'COMMANDS',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ),
                                for (var i = 0; i < commands.length; i++)
                                  _CommandListTile(
                                    command: commands[i],
                                    selected: _selectedIndex == i,
                                    selectionColor: selection,
                                    onTap: () {
                                      setState(() => _selectedIndex = i);
                                      _executeSelected();
                                    },
                                  ),
                              ],
                              if (notes.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.md,
                                    AppSpacing.sm,
                                    AppSpacing.md,
                                    AppSpacing.xs,
                                  ),
                                  child: Text(
                                    query.isEmpty ? 'RECENT NOTES' : 'MATCHING NOTES',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ),
                                for (var j = 0; j < notes.length; j++)
                                  _NoteResultListTile(
                                    note: notes[j],
                                    selected:
                                        _selectedIndex == commands.length + j,
                                    selectionColor: selection,
                                    onTap: () {
                                      setState(
                                        () => _selectedIndex = commands.length + j,
                                      );
                                      _executeSelected();
                                    },
                                  ),
                              ],
                            ],
                          ),
                  ),

                  // Footer guide
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '↑↓ to navigate · ↵ to select · ESC to dismiss',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              color: theme.hintColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Notebook Pro',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

class _PaletteCommand {
  const _PaletteCommand({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.shortcut,
    required this.onRun,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? shortcut;
  final VoidCallback onRun;
}

class _CommandListTile extends StatelessWidget {
  const _CommandListTile({
    required this.command,
    required this.selected,
    required this.selectionColor,
    required this.onTap,
  });

  final _PaletteCommand command;
  final bool selected;
  final Color selectionColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? selectionColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Row(
          children: [
            Icon(
              command.icon,
              size: 18,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    command.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    command.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (command.shortcut != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  command.shortcut!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoteResultListTile extends StatelessWidget {
  const _NoteResultListTile({
    required this.note,
    required this.selected,
    required this.selectionColor,
    required this.onTap,
  });

  final Note note;
  final bool selected;
  final Color selectionColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = note.title.trim().isEmpty ? 'Untitled Note' : note.title.trim();
    final dateStr = DateFormat.MMMd().format(note.updatedAt.toLocal());

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? selectionColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Row(
          children: [
            Icon(
              note.isPinned ? Icons.push_pin : Icons.description_outlined,
              size: 18,
              color: note.isPinned ? theme.colorScheme.primary : Colors.grey,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                  if (note.plainTextPreview.isNotEmpty || note.tags.isNotEmpty)
                    Row(
                      children: [
                        if (note.tags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              note.tags.map((t) => '#$t').take(2).join(' '),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            note.plainTextPreview.replaceAll('\n', ' '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

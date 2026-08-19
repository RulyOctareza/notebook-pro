import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:notebook_pro/core/theme/app_colors.dart';
import 'package:notebook_pro/core/theme/app_spacing.dart';
import 'package:notebook_pro/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:notebook_pro/features/gamification/presentation/widgets/badge_unlock_toast.dart';
import 'package:notebook_pro/features/gamification/presentation/widgets/streak_badge.dart';
import 'package:notebook_pro/features/notes/domain/entities/note_folder.dart';
import 'package:notebook_pro/features/notes/presentation/providers/notes_providers.dart';
import 'package:notebook_pro/features/notes/presentation/widgets/command_palette_dialog.dart';
import 'package:notebook_pro/features/notes/presentation/widgets/empty_editor_state.dart';
import 'package:notebook_pro/features/notes/presentation/widgets/export_note_dialog.dart';
import 'package:notebook_pro/features/notes/presentation/widgets/folder_sidebar.dart';
import 'package:notebook_pro/features/notes/presentation/widgets/note_editor_pane.dart';
import 'package:notebook_pro/features/notes/presentation/widgets/note_list_tile.dart';
import 'package:notebook_pro/features/notes/presentation/widgets/panel_resize_handle.dart';
import 'package:notebook_pro/features/settings/presentation/providers/editor_zoom_provider.dart';
import 'package:notebook_pro/features/settings/presentation/providers/folder_sidebar_visible_provider.dart';
import 'package:notebook_pro/features/settings/presentation/providers/note_list_visible_provider.dart';
import 'package:notebook_pro/features/settings/presentation/providers/panel_layout_provider.dart';
import 'package:notebook_pro/features/settings/presentation/providers/theme_mode_provider.dart';
import 'package:notebook_pro/features/settings/presentation/widgets/account_button.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _clampFolderWidth({
    required double desired,
    required double totalWidth,
    required double listWidth,
    required bool listVisible,
  }) {
    final handles = 5.0 + (listVisible ? 5.0 : 0.0);
    final listShare = listVisible ? listWidth : 0.0;
    final maxForFolder = totalWidth - AppLayout.editorMin - listShare - handles;
    final upper = maxForFolder.clamp(AppLayout.folderMin, AppLayout.folderMax);
    return desired.clamp(AppLayout.folderMin, upper);
  }

  double _clampListWidth({
    required double desired,
    required double totalWidth,
    required double folderWidth,
    required bool foldersVisible,
  }) {
    final handles = 5.0 + (foldersVisible ? 5.0 : 0.0);
    final folderShare = foldersVisible ? folderWidth : 0.0;
    final maxForList = totalWidth - AppLayout.editorMin - folderShare - handles;
    final upper = maxForList.clamp(
      AppLayout.noteListMin,
      AppLayout.noteListMax,
    );
    return desired.clamp(AppLayout.noteListMin, upper);
  }

  String? _targetFolderForNewNote() {
    final selected = ref.read(selectedFolderIdProvider);
    if (selected == null || selected == kInboxFolderId) return null;
    return selected;
  }

  Future<void> _createNote() async {
    // Draft is created locally; gamification + "real" save wait until
    // the note has title/body content (handled in NoteEditorPane).
    final note = await ref
        .read(noteRepositoryProvider)
        .create(folderId: _targetFolderForNewNote());
    ref.read(selectedNoteIdProvider.notifier).state = note.id;
  }

  Future<void> _deleteNote(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be removed from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(noteRepositoryProvider).softDelete(id);
      if (ref.read(selectedNoteIdProvider) == id) {
        ref.read(selectedNoteIdProvider.notifier).state = null;
      }
    }
  }

  Future<void> _deleteSelected() async {
    final id = ref.read(selectedNoteIdProvider);
    if (id == null) return;
    await _deleteNote(id);
  }

  void _openCommandPalette() {
    CommandPaletteDialog.show(context);
  }

  Future<void> _exportSelected() async {
    final noteId = ref.read(selectedNoteIdProvider);
    if (noteId == null) return;
    final note = await ref.read(noteRepositoryProvider).getById(noteId);
    if (note != null && mounted) {
      await ExportNoteDialog.show(context, note);
    }
  }

  Future<void> _moveSelected() async {
    final noteId = ref.read(selectedNoteIdProvider);
    if (noteId == null) return;
    final folders = ref.read(foldersProvider).valueOrNull ?? const [];

    final choice = await showDialog<Object>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Move to folder'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, kInboxFolderId),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.inbox_outlined),
              title: Text('Notes'),
              subtitle: Text('Inbox (no folder)'),
            ),
          ),
          for (final folder in folders)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, folder.id),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_outlined),
                title: Text(folder.name),
              ),
            ),
        ],
      ),
    );

    if (!mounted || choice == null) return;
    final folderId = choice == kInboxFolderId ? null : choice as String;
    await ref.read(noteRepositoryProvider).moveToFolder(noteId, folderId);
  }

  String _folderTitle() {
    final selected = ref.watch(selectedFolderIdProvider);
    if (selected == null) return 'All Notes';
    if (selected == kInboxFolderId) return 'Notes';
    final folders = ref.watch(foldersProvider).valueOrNull ?? const [];
    return folders
            .where((f) => f.id == selected)
            .map((f) => f.name)
            .firstOrNull ??
        'Folder';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final panel = isDark ? AppColors.darkPanel : AppColors.lightPanel;
    final canvas = isDark ? AppColors.darkCanvas : AppColors.lightCanvas;
    final selectedId = ref.watch(selectedNoteIdProvider);
    final notesAsync = ref.watch(filteredNotesProvider);
    final pending = ref.watch(pendingUnlocksProvider);
    final themeMode = ref.watch(themeModeProvider);
    final foldersVisible = ref.watch(folderSidebarVisibleProvider);
    final listVisible = ref.watch(noteListVisibleProvider);
    final panelLayout = ref.watch(panelLayoutProvider);
    final folderTitle = _folderTitle();
    final selectedTag = ref.watch(selectedTagProvider);

    final zoomNotifier = ref.read(editorZoomProvider.notifier);
    final panelNotifier = ref.read(panelLayoutProvider.notifier);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): _createNote,
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            _createNote,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _openCommandPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _openCommandPalette,
        const SingleActivator(LogicalKeyboardKey.keyE, meta: true):
            _exportSelected,
        const SingleActivator(LogicalKeyboardKey.keyE, control: true):
            _exportSelected,
        const SingleActivator(LogicalKeyboardKey.keyD, meta: true):
            _deleteSelected,
        const SingleActivator(LogicalKeyboardKey.keyD, control: true):
            _deleteSelected,
        // View zoom (display scale) — Cmd/Ctrl + / -
        const SingleActivator(LogicalKeyboardKey.equal, meta: true):
            zoomNotifier.zoomIn,
        const SingleActivator(LogicalKeyboardKey.equal, control: true):
            zoomNotifier.zoomIn,
        const SingleActivator(
          LogicalKeyboardKey.equal,
          meta: true,
          shift: true,
        ): zoomNotifier.zoomIn,
        const SingleActivator(
          LogicalKeyboardKey.equal,
          control: true,
          shift: true,
        ): zoomNotifier.zoomIn,
        const SingleActivator(LogicalKeyboardKey.numpadAdd, meta: true):
            zoomNotifier.zoomIn,
        const SingleActivator(LogicalKeyboardKey.numpadAdd, control: true):
            zoomNotifier.zoomIn,
        const SingleActivator(LogicalKeyboardKey.minus, meta: true):
            zoomNotifier.zoomOut,
        const SingleActivator(LogicalKeyboardKey.minus, control: true):
            zoomNotifier.zoomOut,
        const SingleActivator(LogicalKeyboardKey.numpadSubtract, meta: true):
            zoomNotifier.zoomOut,
        const SingleActivator(LogicalKeyboardKey.numpadSubtract, control: true):
            zoomNotifier.zoomOut,
        const SingleActivator(LogicalKeyboardKey.digit0, meta: true):
            zoomNotifier.reset,
        const SingleActivator(LogicalKeyboardKey.digit0, control: true):
            zoomNotifier.reset,
      },
      child: Scaffold(
        backgroundColor: canvas,
        body: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final folderWidth = foldersVisible
                    ? _clampFolderWidth(
                        desired: panelLayout.folderWidth,
                        totalWidth: totalWidth,
                        listWidth: panelLayout.listWidth,
                        listVisible: listVisible,
                      )
                    : 0.0;
                final listWidth = listVisible
                    ? _clampListWidth(
                        desired: panelLayout.listWidth,
                        totalWidth: totalWidth,
                        folderWidth: folderWidth,
                        foldersVisible: foldersVisible,
                      )
                    : 0.0;

                return Row(
                  children: [
                    ClipRect(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.centerLeft,
                        child: foldersVisible
                            ? SizedBox(
                                width: folderWidth,
                                child: FolderSidebar(
                                  onHide: () => ref
                                      .read(
                                        folderSidebarVisibleProvider.notifier,
                                      )
                                      .setVisible(false),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    if (foldersVisible)
                      PanelResizeHandle(
                        onDragDelta: (dx) {
                          final current = ref
                              .read(panelLayoutProvider)
                              .folderWidth;
                          panelNotifier.setFolderWidth(
                            _clampFolderWidth(
                              desired: current + dx,
                              totalWidth: totalWidth,
                              listWidth: listWidth,
                              listVisible: listVisible,
                            ),
                          );
                        },
                        onDragEnd: () {
                          panelNotifier.setFolderWidth(
                            ref.read(panelLayoutProvider).folderWidth,
                            persist: true,
                          );
                        },
                        onReset: panelNotifier.resetFolder,
                      ),
                    ClipRect(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.centerLeft,
                        child: listVisible
                            ? SizedBox(
                                width: listWidth,
                                child: ColoredBox(
                                  color: panel,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: AppLayout.listHeaderHeight,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                          ),
                                          child: Row(
                                            children: [
                                              if (!foldersVisible) ...[
                                                IconButton(
                                                  tooltip: 'Show folders',
                                                  onPressed: () => ref
                                                      .read(
                                                        folderSidebarVisibleProvider
                                                            .notifier,
                                                      )
                                                      .setVisible(true),
                                                  icon: const Icon(
                                                    Icons.menu_rounded,
                                                    size: 18,
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ),
                                                IconButton(
                                                  tooltip: 'Command Palette (⌘K)',
                                                  onPressed: _openCommandPalette,
                                                  icon: const Icon(
                                                    Icons.terminal_outlined,
                                                    size: 18,
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ),
                                                IconButton(
                                                  tooltip: 'New note',
                                                  onPressed: _createNote,
                                                  icon: const Icon(
                                                    Icons.add,
                                                    size: 18,
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.xs,
                                                ),
                                              ],
                                              Expanded(
                                                child: TextField(
                                                  controller: _searchController,
                                                  style:
                                                      theme.textTheme.bodySmall,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'Search in $folderTitle',
                                                    hintStyle: theme
                                                        .textTheme
                                                        .bodySmall,
                                                    prefixIcon: const Icon(
                                                      Icons.search,
                                                      size: 16,
                                                    ),
                                                    prefixIconConstraints:
                                                        const BoxConstraints(
                                                          minWidth: 32,
                                                          minHeight: 32,
                                                        ),
                                                    isDense: true,
                                                    filled: true,
                                                    fillColor: canvas,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 8,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            AppRadii.sm,
                                                          ),
                                                      borderSide:
                                                          BorderSide.none,
                                                    ),
                                                  ),
                                                  onChanged: (v) =>
                                                      ref
                                                              .read(
                                                                searchQueryProvider
                                                                    .notifier,
                                                              )
                                                              .state =
                                                          v,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.sm,
                                              ),
                                              const AccountButton(),
                                              const StreakBadge(),
                                              const SizedBox(
                                                width: AppSpacing.xs,
                                              ),
                                              IconButton(
                                                tooltip: 'New note',
                                                onPressed: _createNote,
                                                icon: const Icon(
                                                  Icons.add,
                                                  size: 18,
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                              IconButton(
                                                tooltip: switch (themeMode) {
                                                  ThemeMode.light => 'Light',
                                                  ThemeMode.dark => 'Dark',
                                                  ThemeMode.system => 'System',
                                                },
                                                onPressed: () => ref
                                                    .read(
                                                      themeModeProvider
                                                          .notifier,
                                                    )
                                                    .cycle(),
                                                icon: Icon(switch (themeMode) {
                                                  ThemeMode.light =>
                                                    Icons.light_mode_outlined,
                                                  ThemeMode.dark =>
                                                    Icons.dark_mode_outlined,
                                                  ThemeMode.system =>
                                                    Icons
                                                        .brightness_auto_outlined,
                                                }, size: 18),
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                              IconButton(
                                                tooltip: 'Hide notes list',
                                                onPressed: () => ref
                                                    .read(
                                                      noteListVisibleProvider
                                                          .notifier,
                                                    )
                                                    .setVisible(false),
                                                icon: const Icon(
                                                  Icons.menu_open,
                                                  size: 18,
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Divider(
                                        height: 1,
                                        color: theme.colorScheme.outline,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          AppSpacing.md,
                                          AppSpacing.sm,
                                          AppSpacing.md,
                                          AppSpacing.xs,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              folderTitle,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            if (selectedTag != null) ...[
                                              const SizedBox(width: AppSpacing.sm),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.tag, size: 11, color: theme.colorScheme.primary),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      selectedTag,
                                                      style: theme.textTheme.labelSmall?.copyWith(
                                                        color: theme.colorScheme.primary,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    InkWell(
                                                      onTap: () => ref.read(selectedTagProvider.notifier).state = null,
                                                      child: Icon(Icons.close, size: 12, color: theme.colorScheme.primary),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: notesAsync.when(
                                          loading: () => const Center(
                                            child:
                                                CircularProgressIndicator.adaptive(),
                                          ),
                                          error: (e, _) =>
                                              Center(child: Text('$e')),
                                          data: (notes) {
                                            if (notes.isEmpty) {
                                              return Center(
                                                child: Text(
                                                  'No notes here',
                                                  style:
                                                      theme.textTheme.bodySmall,
                                                ),
                                              );
                                            }
                                            return ListView.builder(
                                              itemCount: notes.length,
                                              itemBuilder: (context, index) {
                                                final note = notes[index];
                                                return NoteListTile(
                                                  note: note,
                                                  selected:
                                                      note.id == selectedId,
                                                  onTap: () {
                                                    ref
                                                        .read(
                                                          selectedNoteIdProvider
                                                              .notifier,
                                                        )
                                                        .state = note
                                                        .id;
                                                  },
                                                  onPin: () => ref
                                                      .read(
                                                        noteRepositoryProvider,
                                                      )
                                                      .togglePin(note.id),
                                                  onDelete: () =>
                                                      _deleteNote(note.id),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      if (selectedId != null)
                                        Padding(
                                          padding: const EdgeInsets.all(
                                            AppSpacing.sm,
                                          ),
                                          child: Wrap(
                                            spacing: 4,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () => ref
                                                    .read(
                                                      noteRepositoryProvider,
                                                    )
                                                    .togglePin(selectedId),
                                                icon: const Icon(
                                                  Icons.push_pin_outlined,
                                                  size: 14,
                                                ),
                                                label: const Text('Pin'),
                                              ),
                                              TextButton.icon(
                                                onPressed: _exportSelected,
                                                icon: const Icon(
                                                  Icons.ios_share_outlined,
                                                  size: 14,
                                                ),
                                                label: const Text('Export'),
                                              ),
                                              TextButton.icon(
                                                onPressed: _moveSelected,
                                                icon: const Icon(
                                                  Icons.drive_file_move_outline,
                                                  size: 14,
                                                ),
                                                label: const Text('Move'),
                                              ),
                                              TextButton.icon(
                                                onPressed: _deleteSelected,
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  size: 14,
                                                  color:
                                                      theme.colorScheme.error,
                                                ),
                                                label: Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color:
                                                        theme.colorScheme.error,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    if (listVisible)
                      PanelResizeHandle(
                        onDragDelta: (dx) {
                          final current = ref
                              .read(panelLayoutProvider)
                              .listWidth;
                          panelNotifier.setListWidth(
                            _clampListWidth(
                              desired: current + dx,
                              totalWidth: totalWidth,
                              folderWidth: folderWidth,
                              foldersVisible: foldersVisible,
                            ),
                          );
                        },
                        onDragEnd: () {
                          panelNotifier.setListWidth(
                            ref.read(panelLayoutProvider).listWidth,
                            persist: true,
                          );
                        },
                        onReset: panelNotifier.resetList,
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          if (!listVisible)
                            SizedBox(
                              height: AppLayout.listHeaderHeight,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: panel,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                  ),
                                  child: Row(
                                    children: [
                                      if (!foldersVisible)
                                        IconButton(
                                          tooltip: 'Show folders',
                                          onPressed: () => ref
                                              .read(
                                                folderSidebarVisibleProvider
                                                    .notifier,
                                              )
                                              .setVisible(true),
                                          icon: const Icon(
                                            Icons.menu_rounded,
                                            size: 18,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      IconButton(
                                        tooltip: 'Show notes list',
                                        onPressed: () => ref
                                            .read(
                                              noteListVisibleProvider.notifier,
                                            )
                                            .setVisible(true),
                                        icon: const Icon(
                                          Icons.view_agenda_outlined,
                                          size: 18,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const Spacer(),
                                      const AccountButton(),
                                      const StreakBadge(),
                                       IconButton(
                                         tooltip: 'Command Palette (⌘K)',
                                         onPressed: _openCommandPalette,
                                         icon: const Icon(
                                           Icons.terminal_outlined,
                                           size: 18,
                                         ),
                                         visualDensity: VisualDensity.compact,
                                       ),
                                       if (selectedId != null)
                                         IconButton(
                                           tooltip: 'Export note (PDF, MD, TXT)',
                                           onPressed: _exportSelected,
                                           icon: const Icon(
                                             Icons.ios_share_outlined,
                                             size: 18,
                                           ),
                                           visualDensity: VisualDensity.compact,
                                         ),
                                       IconButton(
                                         tooltip: 'New note',
                                         onPressed: _createNote,
                                         icon: const Icon(Icons.add, size: 18),
                                         visualDensity: VisualDensity.compact,
                                       ),
                                      IconButton(
                                        tooltip: switch (themeMode) {
                                          ThemeMode.light => 'Light',
                                          ThemeMode.dark => 'Dark',
                                          ThemeMode.system => 'System',
                                        },
                                        onPressed: () => ref
                                            .read(themeModeProvider.notifier)
                                            .cycle(),
                                        icon: Icon(switch (themeMode) {
                                          ThemeMode.light =>
                                            Icons.light_mode_outlined,
                                          ThemeMode.dark =>
                                            Icons.dark_mode_outlined,
                                          ThemeMode.system =>
                                            Icons.brightness_auto_outlined,
                                        }, size: 18),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          Expanded(
                            child: selectedId == null
                                ? EmptyEditorState(onCreate: _createNote)
                                : NoteEditorPane(
                                    key: ValueKey(selectedId),
                                    noteId: selectedId,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            if (pending.isNotEmpty)
              Positioned(
                right: 24,
                bottom: 24,
                child: BadgeUnlockToast(
                  key: ValueKey(pending.first.id),
                  achievement: pending.first,
                  onDismiss: () {
                    final rest = [...ref.read(pendingUnlocksProvider)]
                      ..removeAt(0);
                    ref.read(pendingUnlocksProvider.notifier).state = rest;
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

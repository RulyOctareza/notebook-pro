import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:notebook_pro/core/theme/app_colors.dart';
import 'package:notebook_pro/core/theme/app_spacing.dart';
import 'package:notebook_pro/features/notes/domain/entities/note_folder.dart';
import 'package:notebook_pro/features/notes/presentation/providers/notes_providers.dart';

class FolderSidebar extends ConsumerWidget {
  const FolderSidebar({super.key, this.onHide});

  /// Called when the user collapses this sidebar.
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canvas = isDark ? AppColors.darkCanvas : AppColors.lightCanvas;
    final selection = isDark
        ? AppColors.darkSelection
        : AppColors.lightSelection;
    final selected = ref.watch(selectedFolderIdProvider);
    final selectedTag = ref.watch(selectedTagProvider);
    final folders = ref.watch(foldersProvider).valueOrNull ?? const [];
    final counts = ref.watch(noteCountsByFolderProvider).valueOrNull ?? {};
    final tagsMap = ref.watch(allTagsProvider).valueOrNull ?? {};

    final allCount = counts.values.fold<int>(0, (a, b) => a + b);
    final inboxCount = counts[null] ?? 0;

    Future<void> moveNote(String noteId, String? folderId) async {
      await ref.read(noteRepositoryProvider).moveToFolder(noteId, folderId);
    }

    return ColoredBox(
      color: canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Folders',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'New folder',
                  onPressed: () => _createFolder(context, ref),
                  icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
                if (onHide != null)
                  IconButton(
                    tooltip: 'Hide folders',
                    onPressed: onHide,
                    icon: const Icon(Icons.menu_open, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              children: [
                _FolderRow(
                  icon: Icons.notes_outlined,
                  label: 'All Notes',
                  count: allCount,
                  selected: selected == null && selectedTag == null,
                  selectionColor: selection,
                  // All Notes is a filter view — not a drop target.
                  onTap: () {
                    ref.read(selectedFolderIdProvider.notifier).state = null;
                    ref.read(selectedTagProvider.notifier).state = null;
                    ref.read(selectedNoteIdProvider.notifier).state = null;
                  },
                ),
                _FolderRow(
                  icon: Icons.inbox_outlined,
                  label: 'Notes',
                  count: inboxCount,
                  selected: selected == kInboxFolderId && selectedTag == null,
                  selectionColor: selection,
                  acceptDrops: true,
                  onAcceptNote: (noteId) => moveNote(noteId, null),
                  onTap: () {
                    ref.read(selectedFolderIdProvider.notifier).state =
                        kInboxFolderId;
                    ref.read(selectedTagProvider.notifier).state = null;
                    ref.read(selectedNoteIdProvider.notifier).state = null;
                  },
                ),
                _TrashRow(
                  count: ref.watch(trashCountProvider).valueOrNull ?? 0,
                  selected: selected == kTrashFolderId,
                  selectionColor: selection,
                  onTap: () {
                    ref.read(selectedFolderIdProvider.notifier).state =
                        kTrashFolderId;
                    ref.read(selectedTagProvider.notifier).state = null;
                    ref.read(selectedNoteIdProvider.notifier).state = null;
                  },
                  onEmpty: () => _emptyTrash(context, ref),
                ),
                if (folders.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.xs,
                    ),
                    child: Text(
                      'My Folders',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  for (final folder in folders)
                    _FolderRow(
                      icon: folder.isPinned
                          ? Icons.folder_special_outlined
                          : Icons.folder_outlined,
                      label: folder.name,
                      count: counts[folder.id] ?? 0,
                      selected: selected == folder.id && selectedTag == null,
                      selectionColor: selection,
                      isPinned: folder.isPinned,
                      acceptDrops: true,
                      onAcceptNote: (noteId) => moveNote(noteId, folder.id),
                      onTap: () {
                        ref.read(selectedFolderIdProvider.notifier).state =
                            folder.id;
                        ref.read(selectedTagProvider.notifier).state = null;
                        ref.read(selectedNoteIdProvider.notifier).state = null;
                      },
                      onPin: () => ref
                          .read(folderRepositoryProvider)
                          .togglePin(folder.id),
                      onRename: () => _renameFolder(context, ref, folder),
                      onDelete: () => _deleteFolder(context, ref, folder),
                    ),
                ],
                if (tagsMap.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tags',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (selectedTag != null)
                          GestureDetector(
                            onTap: () => ref.read(selectedTagProvider.notifier).state = null,
                            child: Text(
                              'Clear',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  for (final entry in tagsMap.entries)
                    _TagRow(
                      tag: entry.key,
                      count: entry.value,
                      selected: selectedTag == entry.key,
                      selectionColor: selection,
                      onTap: () {
                        if (selectedTag == entry.key) {
                          ref.read(selectedTagProvider.notifier).state = null;
                        } else {
                          ref.read(selectedTagProvider.notifier).state = entry.key;
                        }
                      },
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _emptyTrash(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'Notes in Trash will be permanently deleted. This cannot be undone.',
        ),
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
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(noteRepositoryProvider).emptyTrash();
    if (ref.read(selectedFolderIdProvider) == kTrashFolderId) {
      ref.read(selectedNoteIdProvider.notifier).state = null;
    }
  }

  Future<void> _createFolder(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context, title: 'New folder');
    if (name == null) return;
    final folder = await ref.read(folderRepositoryProvider).create(name);
    ref.read(selectedFolderIdProvider.notifier).state = folder.id;
  }

  Future<void> _renameFolder(
    BuildContext context,
    WidgetRef ref,
    NoteFolder folder,
  ) async {
    final name = await _promptName(
      context,
      title: 'Rename folder',
      initial: folder.name,
    );
    if (name == null) return;
    await ref.read(folderRepositoryProvider).rename(folder.id, name);
  }

  Future<void> _deleteFolder(
    BuildContext context,
    WidgetRef ref,
    NoteFolder folder,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${folder.name}"?'),
        content: const Text(
          'Notes in this folder will move back to Notes (inbox).',
        ),
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
    if (ok != true) return;
    await ref.read(folderRepositoryProvider).delete(folder.id);
    final selected = ref.read(selectedFolderIdProvider);
    if (selected == folder.id) {
      ref.read(selectedFolderIdProvider.notifier).state = null;
    }
  }

  Future<String?> _promptName(
    BuildContext context, {
    required String title,
    String initial = '',
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _FolderNameDialog(title: title, initial: initial),
    );
    if (result == null || result.isEmpty) return null;
    return result;
  }
}

class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Folder name',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _FolderRow extends StatefulWidget {
  const _FolderRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.selectionColor,
    required this.onTap,
    this.isPinned = false,
    this.acceptDrops = false,
    this.onAcceptNote,
    this.onPin,
    this.onRename,
    this.onDelete,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final Color selectionColor;
  final VoidCallback onTap;
  final bool isPinned;
  final bool acceptDrops;
  final Future<void> Function(String noteId)? onAcceptNote;
  final VoidCallback? onPin;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  State<_FolderRow> createState() => _FolderRowState();
}

class _FolderRowState extends State<_FolderRow> {
  bool _dragOver = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: _dragOver
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : widget.selected
                ? widget.selectionColor
                : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          onTap: widget.onTap,
          onSecondaryTapDown: (widget.onPin == null &&
                  widget.onRename == null &&
                  widget.onDelete == null)
              ? null
              : (details) async {
                  final action = await showMenu<String>(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                    ),
                    items: [
                      if (widget.onPin != null)
                        PopupMenuItem(
                          value: 'pin',
                          child: Text(widget.isPinned ? 'Unpin' : 'Pin'),
                        ),
                      if (widget.onRename != null)
                        const PopupMenuItem(
                          value: 'rename',
                          child: Text('Rename'),
                        ),
                      if (widget.onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                    ],
                  );
                  if (action == 'pin') widget.onPin?.call();
                  if (action == 'rename') widget.onRename?.call();
                  if (action == 'delete') widget.onDelete?.call();
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(
                color: _dragOver
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color,
                      fontWeight: widget.selected || _dragOver
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.isPinned) ...[
                  Icon(
                    Icons.push_pin_rounded,
                    size: 12,
                    color: theme.textTheme.labelSmall?.color,
                  ),
                  const SizedBox(width: 4),
                ],
                Text('${widget.count}', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.acceptDrops || widget.onAcceptNote == null) return row;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        setState(() => _dragOver = true);
        return true;
      },
      onLeave: (_) => setState(() => _dragOver = false),
      onAcceptWithDetails: (details) async {
        setState(() => _dragOver = false);
        await widget.onAcceptNote!(details.data);
      },
      builder: (context, candidate, rejected) => row,
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tag,
    required this.count,
    required this.selected,
    required this.selectionColor,
    required this.onTap,
  });

  final String tag;
  final int count;
  final bool selected;
  final Color selectionColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? selectionColor : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tag,
                  size: 14,
                  color: selected ? theme.colorScheme.primary : Colors.grey,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    tag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyMedium?.color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                Text('$count', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrashRow extends StatelessWidget {
  const _TrashRow({
    required this.count,
    required this.selected,
    required this.selectionColor,
    required this.onTap,
    required this.onEmpty,
  });

  final int count;
  final bool selected;
  final Color selectionColor;
  final VoidCallback onTap;
  final VoidCallback onEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, top: 4),
      child: Material(
        color: selected ? selectionColor : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          onTap: onTap,
          onSecondaryTapDown: count == 0
              ? null
              : (details) async {
                  final action = await showMenu<String>(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                    ),
                    items: const [
                      PopupMenuItem(
                        value: 'empty',
                        child: Text('Empty Trash'),
                      ),
                    ],
                  );
                  if (action == 'empty') onEmpty();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 8,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: selected ? theme.colorScheme.error : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Trash',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? theme.colorScheme.error : null,
                    ),
                  ),
                ),
                Text('$count', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



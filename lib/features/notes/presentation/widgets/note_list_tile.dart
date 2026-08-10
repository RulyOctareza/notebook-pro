import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:notebook_pro/core/theme/app_colors.dart';
import 'package:notebook_pro/core/theme/app_spacing.dart';
import 'package:notebook_pro/features/notes/domain/entities/note.dart';

class NoteListTile extends StatefulWidget {
  const NoteListTile({
    super.key,
    required this.note,
    required this.selected,
    required this.onTap,
    this.onPin,
    this.onDelete,
  });

  final Note note;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;

  @override
  State<NoteListTile> createState() => _NoteListTileState();
}

class _NoteListTileState extends State<NoteListTile> {
  bool _hovered = false;

  Future<void> _showContextMenu(Offset globalPosition) async {
    if (widget.onPin == null && widget.onDelete == null) return;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: [
        if (widget.onPin != null)
          PopupMenuItem(
            value: 'pin',
            child: Text(widget.note.isPinned ? 'Unpin' : 'Pin'),
          ),
        if (widget.onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete'),
          ),
      ],
    );
    if (action == 'pin') widget.onPin?.call();
    if (action == 'delete') widget.onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selection = isDark
        ? AppColors.darkSelection
        : AppColors.lightSelection;
    final tertiary = isDark
        ? AppColors.darkTextTertiary
        : AppColors.lightTextTertiary;
    final title = widget.note.title.isEmpty ? 'Untitled' : widget.note.title;

    final tile = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.ease,
        decoration: BoxDecoration(
          color: widget.selected
              ? selection
              : _hovered
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.04)
                  : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: widget.selected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          onSecondaryTapDown: (details) =>
              _showContextMenu(details.globalPosition),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            child: Row(
              children: [
                if (widget.note.isPinned) ...[
                  Icon(Icons.push_pin_rounded, size: 12, color: tertiary),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _relativeTime(widget.note.updatedAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Draggable<String>(
      data: widget.note.id,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        color: theme.colorScheme.surface,
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: tile,
    );
  }

  String _relativeTime(DateTime utc) {
    final local = utc.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24 && now.day == local.day) {
      return '${diff.inHours}h';
    }
    if (diff.inDays < 7) return DateFormat.E().format(local);
    return DateFormat.MMMd().format(local);
  }
}

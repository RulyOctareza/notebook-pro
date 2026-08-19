import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:notebook_pro/core/theme/app_spacing.dart';
import 'package:notebook_pro/features/notes/domain/entities/note.dart';
import 'package:notebook_pro/features/notes/domain/note_exporter.dart';

class ExportNoteDialog extends StatefulWidget {
  const ExportNoteDialog({super.key, required this.note});

  final Note note;

  static Future<void> show(BuildContext context, Note note) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => ExportNoteDialog(note: note),
    );
  }

  @override
  State<ExportNoteDialog> createState() => _ExportNoteDialogState();
}

class _ExportNoteDialogState extends State<ExportNoteDialog> {
  bool _isExporting = false;

  Future<void> _export(ExportFormat format) async {
    setState(() => _isExporting = true);
    try {
      final savedPath = await NoteExporter.exportAndSave(
        note: widget.note,
        format: format,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported successfully to: $savedPath'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _printOrPreviewPdf() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await NoteExporter.toPdf(widget.note);
      if (!mounted) return;
      Navigator.of(context).pop();
      await Printing.layoutPdf(
        name: widget.note.title.isEmpty ? 'Notebook Note' : widget.note.title,
        onLayout: (format) async => bytes,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Print preview error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.note.title.trim().isEmpty
        ? 'Untitled Note'
        : widget.note.title.trim();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.ios_share_outlined, size: 20),
          const SizedBox(width: AppSpacing.sm),
          const Text('Export Note'),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exporting "$title"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isExporting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator.adaptive(),
                ),
              )
            else ...[
              _ExportOptionTile(
                icon: Icons.picture_as_pdf_outlined,
                title: 'PDF Document (.pdf)',
                subtitle: 'Printable layout with styled text and embedded images',
                onTap: () => _export(ExportFormat.pdf),
              ),
              const Divider(height: 1),
              _ExportOptionTile(
                icon: Icons.description_outlined,
                title: 'Markdown (.md)',
                subtitle: 'Portable formatted markdown with headers, lists & links',
                onTap: () => _export(ExportFormat.markdown),
              ),
              const Divider(height: 1),
              _ExportOptionTile(
                icon: Icons.text_snippet_outlined,
                title: 'Plain Text (.txt)',
                subtitle: 'Clean raw text without styling',
                onTap: () => _export(ExportFormat.plainText),
              ),
              const Divider(height: 1),
              _ExportOptionTile(
                icon: Icons.print_outlined,
                title: 'Print / System PDF Dialog',
                subtitle: 'Open macOS print dialog or Save as PDF via native print',
                onTap: _printOrPreviewPdf,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _ExportOptionTile extends StatelessWidget {
  const _ExportOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 20, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

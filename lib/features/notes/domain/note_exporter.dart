import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:notebook_pro/features/notes/domain/entities/note.dart';

enum ExportFormat {
  pdf(label: 'PDF Document (.pdf)', extension: 'pdf', mime: 'application/pdf'),
  markdown(label: 'Markdown (.md)', extension: 'md', mime: 'text/markdown'),
  plainText(label: 'Plain Text (.txt)', extension: 'txt', mime: 'text/plain');

  const ExportFormat({
    required this.label,
    required this.extension,
    required this.mime,
  });

  final String label;
  final String extension;
  final String mime;
}

class NoteExporter {
  /// Converts a note's Quill Delta and metadata into standard Markdown.
  static String toMarkdown(Note note) {
    final buffer = StringBuffer();

    // Title
    final title = note.title.trim().isEmpty ? 'Untitled Note' : note.title.trim();
    buffer.writeln('# $title');
    buffer.writeln();

    // Metadata header
    final dateStr = DateFormat.yMMMMd().add_jm().format(note.updatedAt.toLocal());
    buffer.writeln('> *Last modified: $dateStr*');

    if (note.tags.isNotEmpty) {
      final tagsStr = note.tags.map((t) => '#$t').join(' ');
      buffer.writeln('> *Tags: $tagsStr*');
    }
    buffer.writeln();

    // Parse Quill Delta Ops
    List<dynamic> ops = [];
    try {
      ops = jsonDecode(note.bodyDelta) as List<dynamic>;
    } catch (_) {
      ops = [];
    }

    if (ops.isEmpty) {
      if (note.plainTextPreview.isNotEmpty) {
        buffer.writeln(note.plainTextPreview);
      }
      return buffer.toString();
    }

    var currentLine = StringBuffer();
    var currentLineBlockAttrs = <String, dynamic>{};

    for (final op in ops) {
      if (op is! Map<String, dynamic>) continue;
      final insert = op['insert'];
      final attrs = (op['attributes'] as Map<String, dynamic>?) ?? {};

      if (attrs.containsKey('header')) {
        currentLineBlockAttrs['header'] = attrs['header'];
      }
      if (attrs.containsKey('list')) {
        currentLineBlockAttrs['list'] = attrs['list'];
      }
      if (attrs.containsKey('blockquote')) {
        currentLineBlockAttrs['blockquote'] = attrs['blockquote'];
      }
      if (attrs.containsKey('code-block')) {
        currentLineBlockAttrs['code-block'] = attrs['code-block'];
      }

      if (insert is Map<String, dynamic>) {
        // Embeds (e.g. image)
        if (insert.containsKey('image')) {
          final imgPath = insert['image'].toString();
          currentLine.write('\n![Image]($imgPath)\n');
        }
        continue;
      }

      if (insert is! String) continue;

      // Check for newline with block-level formatting
      if (insert.contains('\n')) {
        final parts = insert.split('\n');
        for (var i = 0; i < parts.length; i++) {
          final part = parts[i];
          _appendFormattedInline(currentLine, part, attrs);

          if (i < parts.length - 1) {
            final lineText = currentLine.toString();
            currentLine = StringBuffer();

            final combinedBlockAttrs = <String, dynamic>{
              ...currentLineBlockAttrs,
              ...attrs,
            };
            currentLineBlockAttrs = {};

            if (combinedBlockAttrs.containsKey('header')) {
              final level = combinedBlockAttrs['header'];
              final prefix = level == 1 ? '# ' : (level == 2 ? '## ' : '### ');
              buffer.writeln('$prefix$lineText');
            } else if (combinedBlockAttrs.containsKey('blockquote')) {
              buffer.writeln('> $lineText');
            } else if (combinedBlockAttrs.containsKey('list')) {
              final listType = combinedBlockAttrs['list'];
              if (listType == 'bullet') {
                buffer.writeln('- $lineText');
              } else if (listType == 'ordered') {
                buffer.writeln('1. $lineText');
              } else if (listType == 'checked') {
                buffer.writeln('- [x] $lineText');
              } else if (listType == 'unchecked') {
                buffer.writeln('- [ ] $lineText');
              } else {
                buffer.writeln('- $lineText');
              }
            } else if (combinedBlockAttrs.containsKey('code-block')) {
              buffer.writeln('```\n$lineText\n```');
            } else {
              buffer.writeln(lineText);
            }
          }
        }
      } else {
        _appendFormattedInline(currentLine, insert, attrs);
      }
    }

    if (currentLine.isNotEmpty) {
      buffer.writeln(currentLine.toString());
    }

    return '${buffer.toString().trimRight()}\n';
  }

  static void _appendFormattedInline(
    StringBuffer buffer,
    String text,
    Map<String, dynamic> attrs,
  ) {
    if (text.isEmpty) return;
    var formatted = text;

    if (attrs['bold'] == true) {
      formatted = '**$formatted**';
    }
    if (attrs['italic'] == true) {
      formatted = '*$formatted*';
    }
    if (attrs['underline'] == true) {
      formatted = '<u>$formatted</u>';
    }
    if (attrs['strike'] == true) {
      formatted = '~~$formatted~~';
    }
    if (attrs['code'] == true) {
      formatted = '`$formatted`';
    }
    if (attrs['link'] != null) {
      formatted = '[$formatted](${attrs['link']})';
    }

    buffer.write(formatted);
  }

  /// Converts note to simple clean plain text.
  static String toPlainText(Note note) {
    final title = note.title.trim().isEmpty ? 'Untitled Note' : note.title.trim();
    final buffer = StringBuffer();
    buffer.writeln(title);
    buffer.writeln('=' * title.length);
    buffer.writeln();

    if (note.tags.isNotEmpty) {
      buffer.writeln('Tags: ${note.tags.map((t) => '#$t').join(' ')}');
    }
    final dateStr = DateFormat.yMMMMd().add_jm().format(note.updatedAt.toLocal());
    buffer.writeln('Date: $dateStr');
    buffer.writeln();

    List<dynamic> ops = [];
    try {
      ops = jsonDecode(note.bodyDelta) as List<dynamic>;
    } catch (_) {
      ops = [];
    }

    if (ops.isEmpty) {
      buffer.writeln(note.plainTextPreview);
      return buffer.toString();
    }

    for (final op in ops) {
      if (op is Map<String, dynamic>) {
        final insert = op['insert'];
        if (insert is String) {
          buffer.write(insert);
        } else if (insert is Map && insert.containsKey('image')) {
          buffer.write('\n[Image: ${insert['image']}]\n');
        }
      }
    }

    return '${buffer.toString().trimRight()}\n';
  }

  /// Generates a styled PDF document bytes for printing or saving.
  static Future<Uint8List> toPdf(Note note) async {
    final pdf = pw.Document(
      title: note.title.isEmpty ? 'Untitled Note' : note.title,
      author: 'Notebook Pro',
    );

    final title = note.title.trim().isEmpty ? 'Untitled Note' : note.title.trim();
    final dateStr = DateFormat.yMMMMd().add_jm().format(note.updatedAt.toLocal());
    final tagsStr = note.tags.map((t) => '#$t').join(' ');

    List<dynamic> ops = [];
    try {
      ops = jsonDecode(note.bodyDelta) as List<dynamic>;
    } catch (_) {
      ops = [];
    }

    // Build PDF content widgets
    final contentWidgets = <pw.Widget>[];

    // Header
    contentWidgets.add(
      pw.Header(
        level: 0,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Modified $dateStr',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                if (tagsStr.isNotEmpty)
                  pw.Text(
                    tagsStr,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
          ],
        ),
      ),
    );

    contentWidgets.add(pw.SizedBox(height: 12));

    // Parse body
    if (ops.isEmpty) {
      if (note.plainTextPreview.isNotEmpty) {
        contentWidgets.add(
          pw.Paragraph(
            text: note.plainTextPreview,
            style: const pw.TextStyle(fontSize: 12),
          ),
        );
      }
    } else {
      var currentSpans = <pw.InlineSpan>[];

      for (final op in ops) {
        if (op is! Map<String, dynamic>) continue;
        final insert = op['insert'];
        final attrs = (op['attributes'] as Map<String, dynamic>?) ?? {};

        if (insert is Map<String, dynamic> && insert.containsKey('image')) {
          // Flush accumulated spans
          if (currentSpans.isNotEmpty) {
            contentWidgets.add(
              pw.RichText(text: pw.TextSpan(children: currentSpans)),
            );
            currentSpans = [];
          }
          final path = insert['image'].toString();
          final imgFile = File(path);
          if (imgFile.existsSync()) {
            try {
              final bytes = imgFile.readAsBytesSync();
              final image = pw.MemoryImage(bytes);
              contentWidgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Center(
                    child: pw.Image(image, height: 260, fit: pw.BoxFit.contain),
                  ),
                ),
              );
            } catch (_) {}
          }
          continue;
        }

        if (insert is! String) continue;

        if (insert.contains('\n')) {
          final parts = insert.split('\n');
          for (var i = 0; i < parts.length; i++) {
            final part = parts[i];
            if (part.isNotEmpty) {
              currentSpans.add(_buildPdfSpan(part, attrs));
            }

            if (i < parts.length - 1) {
              if (attrs.containsKey('header')) {
                final level = attrs['header'] == 1 ? 18.0 : 15.0;
                contentWidgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
                    child: pw.RichText(
                      text: pw.TextSpan(
                        children: currentSpans,
                        style: pw.TextStyle(
                          fontSize: level,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                    ),
                  ),
                );
              } else if (attrs.containsKey('blockquote')) {
                contentWidgets.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 4),
                    padding: const pw.EdgeInsets.only(left: 8, top: 2, bottom: 2),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        left: pw.BorderSide(color: PdfColors.blue400, width: 3),
                      ),
                    ),
                    child: pw.RichText(text: pw.TextSpan(children: currentSpans)),
                  ),
                );
              } else if (attrs.containsKey('list')) {
                contentWidgets.add(
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(' • ', style: const pw.TextStyle(fontSize: 12)),
                      pw.Expanded(
                        child: pw.RichText(text: pw.TextSpan(children: currentSpans)),
                      ),
                    ],
                  ),
                );
              } else {
                if (currentSpans.isNotEmpty) {
                  contentWidgets.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.RichText(text: pw.TextSpan(children: currentSpans)),
                    ),
                  );
                } else {
                  contentWidgets.add(pw.SizedBox(height: 6));
                }
              }
              currentSpans = [];
            }
          }
        } else {
          currentSpans.add(_buildPdfSpan(insert, attrs));
        }
      }

      if (currentSpans.isNotEmpty) {
        contentWidgets.add(pw.RichText(text: pw.TextSpan(children: currentSpans)));
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            'Notebook Pro',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => contentWidgets,
      ),
    );

    return pdf.save();
  }

  static pw.InlineSpan _buildPdfSpan(String text, Map<String, dynamic> attrs) {
    final isBold = attrs['bold'] == true;
    final isItalic = attrs['italic'] == true;
    final isUnderline = attrs['underline'] == true;
    final isLink = attrs['link'] != null;

    var style = pw.TextStyle(
      fontSize: 11,
      color: isLink ? PdfColors.blue700 : PdfColors.black,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontStyle: isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
      decoration: isUnderline || isLink
          ? pw.TextDecoration.underline
          : pw.TextDecoration.none,
    );

    return pw.TextSpan(text: text, style: style);
  }

  /// Prompts user for a save location and exports the file.
  static Future<String?> exportAndSave({
    required Note note,
    required ExportFormat format,
  }) async {
    final rawTitle = note.title.trim().isEmpty ? 'Untitled Note' : note.title.trim();
    final sanitizedTitle = rawTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final suggestedName = '$sanitizedTitle.${format.extension}';

    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [
        XTypeGroup(
          label: format.label,
          extensions: [format.extension],
          mimeTypes: [format.mime],
        ),
      ],
    );

    if (location == null) return null;

    final targetPath = location.path;

    if (format == ExportFormat.pdf) {
      final bytes = await toPdf(note);
      await File(targetPath).writeAsBytes(bytes, flush: true);
    } else if (format == ExportFormat.markdown) {
      final content = toMarkdown(note);
      await File(targetPath).writeAsString(content, flush: true);
    } else if (format == ExportFormat.plainText) {
      final content = toPlainText(note);
      await File(targetPath).writeAsString(content, flush: true);
    }

    return targetPath;
  }
}

import 'dart:convert';

import 'package:notebook_pro/core/utils/id_generator.dart';
import 'package:notebook_pro/features/notes/domain/entities/note.dart';
import 'package:notebook_pro/features/notes/domain/tag_extractor.dart';

/// Converts Markdown text into a [Note] with a Quill-compatible delta body.
class NoteImporter {
  static Note fromMarkdown(
    String markdown, {
    String? folderId,
    DateTime? now,
  }) {
    final stamp = now ?? DateTime.now().toUtc();
    final lines = markdown.replaceAll('\r\n', '\n').split('\n');

    var title = '';
    final bodyLines = <String>[];
    var startedBody = false;

    for (final line in lines) {
      if (!startedBody && title.isEmpty && line.trim().startsWith('# ')) {
        title = line.trim().substring(2).trim();
        startedBody = true;
        continue;
      }
      if (!startedBody &&
          (line.trim().startsWith('> *Last modified:') ||
              line.trim().startsWith('> *Tags:'))) {
        continue;
      }
      startedBody = true;
      bodyLines.add(line);
    }

    if (title.isEmpty) {
      for (final line in bodyLines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          title = trimmed
              .replaceFirst(RegExp(r'^#+\s*'), '')
              .replaceAll(RegExp(r'[*_`#\[\]]'), '')
              .trim();
          if (title.length > 60) title = title.substring(0, 60);
          break;
        }
      }
    }

    final ops = <Map<String, dynamic>>[];
    for (final line in bodyLines) {
      final attrs = <String, dynamic>{};
      var text = line;

      if (text.startsWith('### ')) {
        attrs['header'] = 3;
        text = text.substring(4);
      } else if (text.startsWith('## ')) {
        attrs['header'] = 2;
        text = text.substring(3);
      } else if (text.startsWith('# ')) {
        attrs['header'] = 1;
        text = text.substring(2);
      } else if (text.startsWith('> ')) {
        attrs['blockquote'] = true;
        text = text.substring(2);
      } else if (text.startsWith('- [x] ') || text.startsWith('- [X] ')) {
        attrs['list'] = 'checked';
        text = text.substring(6);
      } else if (text.startsWith('- [ ] ')) {
        attrs['list'] = 'unchecked';
        text = text.substring(6);
      } else if (text.startsWith('- ') || text.startsWith('* ')) {
        attrs['list'] = 'bullet';
        text = text.substring(2);
      } else if (RegExp(r'^\d+\.\s').hasMatch(text)) {
        attrs['list'] = 'ordered';
        text = text.replaceFirst(RegExp(r'^\d+\.\s'), '');
      }

      text = _stripInlineMarkdown(text);
      ops.add({
        'insert': '$text\n',
        if (attrs.isNotEmpty) 'attributes': attrs,
      });
    }

    if (ops.isEmpty) {
      ops.add({'insert': '\n'});
    }

    final plain = bodyLines.join('\n').trim();
    final preview = plain.length > 160 ? plain.substring(0, 160) : plain;
    final tags = extractNoteTags(title: title, plainBody: plain);

    return Note(
      id: IdGenerator.next(),
      title: title.isEmpty ? 'Imported note' : title,
      bodyDelta: jsonEncode(ops),
      plainTextPreview: preview,
      tags: tags,
      createdAt: stamp,
      updatedAt: stamp,
      folderId: folderId,
      isDirty: true,
    );
  }

  static String _stripInlineMarkdown(String text) {
    return text
        .replaceAllMapped(
          RegExp(r'\*\*(.+?)\*\*'),
          (m) => m.group(1) ?? '',
        )
        .replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m.group(1) ?? '')
        .replaceAllMapped(
          RegExp(r'\[(.+?)\]\((.+?)\)'),
          (m) => m.group(1) ?? '',
        );
  }
}

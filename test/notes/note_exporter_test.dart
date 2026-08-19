import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_pro/features/notes/domain/entities/note.dart';
import 'package:notebook_pro/features/notes/domain/note_exporter.dart';

void main() {
  group('NoteExporter', () {
    final sampleNote = Note(
      id: 'test-note-1',
      title: 'Sprint Planning',
      subtitle: 'Sprint 24 Goals',
      bodyDelta: jsonEncode([
        {'insert': 'Sprint Goals:\n', 'attributes': {'header': 1}},
        {'insert': 'Complete authentication flow', 'attributes': {'bold': true}},
        {'insert': '\n'},
        {'insert': 'Review UI components', 'attributes': {'italic': true}},
        {'insert': '\n'},
        {'insert': 'First task', 'attributes': {'list': 'bullet'}},
        {'insert': '\n'},
        {'insert': 'Second task', 'attributes': {'list': 'bullet'}},
        {'insert': '\n'},
      ]),
      plainTextPreview: 'Sprint Goals:\nComplete authentication flow...',
      tags: ['sprint', 'dev'],
      createdAt: DateTime.utc(2026, 8, 19, 9, 0),
      updatedAt: DateTime.utc(2026, 8, 19, 9, 30),
    );

    test('toMarkdown generates valid formatted markdown string', () {
      final md = NoteExporter.toMarkdown(sampleNote);

      expect(md, contains('# Sprint Planning'));
      expect(md, contains('> *Tags: #sprint #dev*'));
      expect(md, contains('# Sprint Goals:'));
      expect(md, contains('**Complete authentication flow**'));
      expect(md, contains('*Review UI components*'));
      expect(md, contains('- First task'));
      expect(md, contains('- Second task'));
    });

    test('toPlainText generates clean plain text with metadata', () {
      final txt = NoteExporter.toPlainText(sampleNote);

      expect(txt, contains('Sprint Planning'));
      expect(txt, contains('Tags: #sprint #dev'));
      expect(txt, contains('Sprint Goals:'));
      expect(txt, contains('Complete authentication flow'));
    });

    test('toPdf generates non-empty PDF document bytes', () async {
      final pdfBytes = await NoteExporter.toPdf(sampleNote);

      expect(pdfBytes, isNotEmpty);
      // PDF documents start with %PDF header
      final header = String.fromCharCodes(pdfBytes.take(4));
      expect(header, '%PDF');
    });
  });
}

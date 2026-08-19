import 'dart:convert';

import 'package:notebook_pro/core/database/app_database.dart';
import 'package:notebook_pro/core/utils/id_generator.dart';
import 'package:notebook_pro/features/notes/domain/entities/note.dart';
import 'package:notebook_pro/features/notes/domain/repositories/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl(this._db);

  final AppDatabase _db;

  static String emptyDeltaJson() => jsonEncode([
    {'insert': '\n'},
  ]);

  @override
  Stream<List<Note>> watchNotes({String? folderId, bool inboxOnly = false}) {
    return _db.watchActiveNotes(folderId: folderId, inboxOnly: inboxOnly);
  }

  @override
  Future<Note?> getById(String id) => _db.getNoteById(id);

  @override
  Future<Note> create({
    String title = '',
    String? subtitle,
    String? folderId,
  }) async {
    final now = DateTime.now().toUtc();
    final note = Note(
      id: IdGenerator.next(),
      title: title,
      subtitle: subtitle,
      bodyDelta: emptyDeltaJson(),
      plainTextPreview: '',
      createdAt: now,
      updatedAt: now,
      folderId: folderId,
    );
    await _db.upsertNote(note);
    return note;
  }

  @override
  Future<void> update(Note note) => _db.upsertNote(note);

  @override
  Future<void> softDelete(String id) => _db.softDeleteNote(id);

  @override
  Future<void> togglePin(String id) => _db.togglePinNote(id);

  @override
  Future<void> moveToFolder(String noteId, String? folderId) {
    return _db.moveNoteToFolder(noteId, folderId);
  }

  @override
  Stream<Map<String?, int>> watchNoteCountsByFolder() {
    return _db.watchNoteCountsByFolder();
  }

  @override
  Stream<Map<String, int>> watchAllTagsWithCounts() {
    return _db.watchAllTagsWithCounts();
  }
}

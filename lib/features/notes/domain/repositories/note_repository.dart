import 'package:notebook_pro/features/notes/domain/entities/note.dart';

abstract class NoteRepository {
  Stream<List<Note>> watchNotes({String? folderId, bool inboxOnly = false});
  Future<Note?> getById(String id);
  Future<Note> create({String title = '', String? subtitle, String? folderId});
  Future<void> update(Note note);
  Future<void> softDelete(String id);
  Future<void> togglePin(String id);
  Future<void> moveToFolder(String noteId, String? folderId);
  Stream<Map<String?, int>> watchNoteCountsByFolder();
  Stream<Map<String, int>> watchAllTagsWithCounts();
}

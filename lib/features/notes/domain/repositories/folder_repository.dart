import 'package:notebook_pro/features/notes/domain/entities/note_folder.dart';

abstract class FolderRepository {
  Stream<List<NoteFolder>> watchFolders();
  Future<NoteFolder> create(String name);
  Future<void> rename(String id, String name);
  Future<void> togglePin(String id);
  Future<void> delete(String id);
}

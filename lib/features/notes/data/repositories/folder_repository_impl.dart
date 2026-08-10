import 'package:notebook_pro/core/database/app_database.dart';
import 'package:notebook_pro/core/utils/id_generator.dart';
import 'package:notebook_pro/features/notes/domain/entities/note_folder.dart';
import 'package:notebook_pro/features/notes/domain/repositories/folder_repository.dart';

class FolderRepositoryImpl implements FolderRepository {
  FolderRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<NoteFolder>> watchFolders() => _db.watchFolders();

  @override
  Future<NoteFolder> create(String name) async {
    final now = DateTime.now().toUtc();
    final folder = NoteFolder(
      id: IdGenerator.next(),
      name: name.trim().isEmpty ? 'New Folder' : name.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _db.upsertFolder(folder);
    return folder;
  }

  @override
  Future<void> rename(String id, String name) async {
    final folders = await _db.watchFolders().first;
    final existing = folders.where((f) => f.id == id).firstOrNull;
    if (existing == null) return;
    await _db.upsertFolder(
      existing.copyWith(
        name: name.trim().isEmpty ? existing.name : name.trim(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<void> togglePin(String id) => _db.togglePinFolder(id);

  @override
  Future<void> delete(String id) => _db.deleteFolder(id);
}

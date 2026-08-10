import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_pro/core/database/app_database.dart';
import 'package:notebook_pro/features/notes/data/repositories/folder_repository_impl.dart';
import 'package:notebook_pro/features/notes/data/repositories/note_repository_impl.dart';

void main() {
  late AppDatabase db;
  late FolderRepositoryImpl folders;
  late NoteRepositoryImpl notes;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    folders = FolderRepositoryImpl(db);
    notes = NoteRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('create folder and place note inside', () async {
    final folder = await folders.create('Work');
    final note = await notes.create(title: 'Meeting', folderId: folder.id);

    final inFolder = await notes.watchNotes(folderId: folder.id).first;
    expect(inFolder.single.id, note.id);

    final inbox = await notes.watchNotes(inboxOnly: true).first;
    expect(inbox, isEmpty);
  });

  test('delete folder moves notes to inbox', () async {
    final folder = await folders.create('Temp');
    final note = await notes.create(folderId: folder.id);
    await folders.delete(folder.id);

    final list = await folders.watchFolders().first;
    expect(list, isEmpty);

    final inbox = await notes.watchNotes(inboxOnly: true).first;
    expect(inbox.single.id, note.id);
  });

  test('move note between folders', () async {
    final a = await folders.create('A');
    final b = await folders.create('B');
    final note = await notes.create(folderId: a.id);

    await notes.moveToFolder(note.id, b.id);
    expect((await notes.watchNotes(folderId: a.id).first), isEmpty);
    expect((await notes.watchNotes(folderId: b.id).first).single.id, note.id);

    await notes.moveToFolder(note.id, null);
    expect((await notes.watchNotes(inboxOnly: true).first).single.id, note.id);
  });
}

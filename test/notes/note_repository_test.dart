import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_pro/core/database/app_database.dart';
import 'package:notebook_pro/features/notes/data/repositories/note_repository_impl.dart';

void main() {
  late AppDatabase db;
  late NoteRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = NoteRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('create and watch notes', () async {
    final note = await repo.create(title: 'Hello');
    expect(note.title, 'Hello');
    expect(note.id, isNotEmpty);

    final list = await repo.watchNotes().first;
    expect(list.length, 1);
    expect(list.first.id, note.id);
  });

  test('update note content', () async {
    final note = await repo.create(title: 'Draft');
    final updated = note.copyWith(
      title: 'Final',
      plainTextPreview: 'body text',
      updatedAt: DateTime.now().toUtc(),
    );
    await repo.update(updated);
    final fetched = await repo.getById(note.id);
    expect(fetched?.title, 'Final');
    expect(fetched?.plainTextPreview, 'body text');
  });

  test('soft delete hides note from list', () async {
    final note = await repo.create(title: 'Gone');
    await repo.softDelete(note.id);
    final list = await repo.watchNotes().first;
    expect(list, isEmpty);
    final still = await repo.getById(note.id);
    expect(still?.deletedAt, isNotNull);
  });

  test('toggle pin', () async {
    final note = await repo.create(title: 'Pin me');
    await repo.togglePin(note.id);
    final fetched = await repo.getById(note.id);
    expect(fetched?.isPinned, isTrue);
  });
}

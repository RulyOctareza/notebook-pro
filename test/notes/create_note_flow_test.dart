import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_pro/core/database/app_database.dart';
import 'package:notebook_pro/features/gamification/data/repositories/gamification_repository_impl.dart';
import 'package:notebook_pro/features/notes/data/repositories/note_repository_impl.dart';

/// End-to-end repository flow mirroring the UI "New note" + write path.
void main() {
  late AppDatabase db;
  late NoteRepositoryImpl notes;
  late GamificationRepositoryImpl game;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    notes = NoteRepositoryImpl(db);
    game = GamificationRepositoryImpl(db);
    await db.ensureProfile();
  });

  tearDown(() async {
    await db.close();
  });

  test('create note, edit, unlock first_note badge', () async {
    final note = await notes.create();
    final unlocks = await game.recordWritingActivity(noteCreated: true);
    expect(unlocks, contains('first_note'));

    final edited = note.copyWith(
      title: 'Morning pages',
      plainTextPreview: 'Hello world from Notebook Pro',
      bodyDelta: NoteRepositoryImpl.emptyDeltaJson(),
      updatedAt: DateTime.now().toUtc(),
    );
    await notes.update(edited);

    final words = await game.recordWritingActivity(wordsAdded: 5);
    expect(words, isEmpty); // already unlocked first_note

    final list = await notes.watchNotes().first;
    expect(list.single.title, 'Morning pages');

    final profile = await game.getProfile();
    expect(profile.currentStreak, 1);
    expect(profile.totalNotesCreated, 1);
    expect(profile.totalWordsWritten, 5);
  });
}

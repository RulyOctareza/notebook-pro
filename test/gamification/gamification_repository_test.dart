import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_pro/core/database/app_database.dart';
import 'package:notebook_pro/features/gamification/data/repositories/gamification_repository_impl.dart';

void main() {
  late AppDatabase db;
  late GamificationRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = GamificationRepositoryImpl(db);
    await db.ensureProfile();
  });

  tearDown(() async {
    await db.close();
  });

  test('creating a note unlocks first_note', () async {
    final newly = await repo.recordWritingActivity(noteCreated: true);
    expect(newly, contains('first_note'));
    final unlocked = await repo.getUnlockedIds();
    expect(unlocked, contains('first_note'));
  });

  test('word count accumulates', () async {
    await repo.recordWritingActivity(wordsAdded: 400);
    await repo.recordWritingActivity(wordsAdded: 600);
    final profile = await repo.getProfile();
    expect(profile.totalWordsWritten, 1000);
    final unlocked = await repo.getUnlockedIds();
    expect(unlocked, contains('words_1000'));
  });
}

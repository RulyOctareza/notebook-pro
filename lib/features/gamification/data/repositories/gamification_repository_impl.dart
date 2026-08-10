import 'package:notebook_pro/core/database/app_database.dart';
import 'package:notebook_pro/features/gamification/domain/achievement_catalog.dart';
import 'package:notebook_pro/features/gamification/domain/entities/gamification_profile.dart';
import 'package:notebook_pro/features/gamification/domain/repositories/gamification_repository.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  GamificationRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<GamificationProfile> watchProfile() => _db.watchProfile();

  @override
  Future<GamificationProfile> getProfile() => _db.getProfile();

  @override
  Future<Set<String>> getUnlockedIds() => _db.getUnlockedIds();

  @override
  Stream<Set<String>> watchUnlockedIds() => _db.watchUnlockedIds();

  @override
  Future<List<String>> recordWritingActivity({
    int wordsAdded = 0,
    bool noteCreated = false,
  }) async {
    await _db.ensureProfile();
    final current = await _db.getProfile();
    final updated = applyWritingActivity(
      profile: current,
      now: DateTime.now(),
      wordsAdded: wordsAdded,
      noteCreated: noteCreated,
    );
    await _db.saveProfile(updated);

    final unlocked = await _db.getUnlockedIds();
    final newly = evaluateNewUnlocks(updated, unlocked);
    if (newly.isNotEmpty) {
      await _db.unlockAchievements(newly);
    }
    return newly.toList();
  }
}

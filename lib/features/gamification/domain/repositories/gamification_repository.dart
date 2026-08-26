import 'package:notebook_pro/features/gamification/domain/entities/gamification_profile.dart';

abstract class GamificationRepository {
  Stream<GamificationProfile> watchProfile();
  Future<GamificationProfile> getProfile();
  Future<Set<String>> getUnlockedIds();
  Stream<Set<String>> watchUnlockedIds();
  Future<List<String>> recordWritingActivity({
    int wordsAdded = 0,
    bool noteCreated = false,
  });
  Future<void> setWeeklyWordsGoal(int goal);
}

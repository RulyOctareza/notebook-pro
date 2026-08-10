import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_pro/features/gamification/domain/achievement_catalog.dart';
import 'package:notebook_pro/features/gamification/domain/entities/gamification_profile.dart';

void main() {
  group('applyWritingActivity', () {
    test('starts streak at 1 on first write', () {
      const profile = GamificationProfile();
      final updated = applyWritingActivity(
        profile: profile,
        now: DateTime(2026, 8, 10, 9),
        wordsAdded: 5,
        noteCreated: true,
      );
      expect(updated.currentStreak, 1);
      expect(updated.totalNotesCreated, 1);
      expect(updated.totalWordsWritten, 5);
    });

    test('increments streak on consecutive day', () {
      final profile = GamificationProfile(
        currentStreak: 2,
        longestStreak: 2,
        lastActiveDate: DateTime(2026, 8, 9),
      );
      final updated = applyWritingActivity(
        profile: profile,
        now: DateTime(2026, 8, 10, 12),
      );
      expect(updated.currentStreak, 3);
      expect(updated.longestStreak, 3);
    });

    test('resets streak after a gap', () {
      final profile = GamificationProfile(
        currentStreak: 5,
        longestStreak: 5,
        lastActiveDate: DateTime(2026, 8, 1),
      );
      final updated = applyWritingActivity(
        profile: profile,
        now: DateTime(2026, 8, 10),
      );
      expect(updated.currentStreak, 1);
      expect(updated.longestStreak, 5);
    });

    test('does not double-count same day', () {
      final profile = GamificationProfile(
        currentStreak: 3,
        longestStreak: 3,
        lastActiveDate: DateTime(2026, 8, 10),
      );
      final updated = applyWritingActivity(
        profile: profile,
        now: DateTime(2026, 8, 10, 18),
        wordsAdded: 10,
      );
      expect(updated.currentStreak, 3);
      expect(updated.totalWordsWritten, 10);
    });
  });

  group('evaluateNewUnlocks', () {
    test('unlocks first_note at 1 note', () {
      const profile = GamificationProfile(totalNotesCreated: 1);
      final newly = evaluateNewUnlocks(profile, {});
      expect(newly, contains('first_note'));
    });

    test('unlocks streak_3 when streak reaches 3', () {
      const profile = GamificationProfile(currentStreak: 3);
      final newly = evaluateNewUnlocks(profile, {'first_note'});
      expect(newly, contains('streak_3'));
      expect(newly, isNot(contains('first_note')));
    });

    test('unlocks words_1000 at threshold', () {
      const profile = GamificationProfile(totalWordsWritten: 1000);
      final newly = evaluateNewUnlocks(profile, {});
      expect(newly, contains('words_1000'));
    });
  });
}

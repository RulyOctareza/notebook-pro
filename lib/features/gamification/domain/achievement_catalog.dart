import 'package:notebook_pro/features/gamification/domain/entities/achievement.dart';
import 'package:notebook_pro/features/gamification/domain/entities/gamification_profile.dart';

const kAchievementCatalog = <Achievement>[
  Achievement(
    id: 'first_note',
    title: 'First Note',
    description: 'Wrote your first note',
    icon: IconKind.firstNote,
    type: AchievementType.noteCount,
    threshold: 1,
  ),
  Achievement(
    id: 'streak_3',
    title: '3-Day Streak',
    description: 'Wrote 3 days in a row',
    icon: IconKind.streak3,
    type: AchievementType.streak,
    threshold: 3,
  ),
  Achievement(
    id: 'streak_7',
    title: 'Week Warrior',
    description: 'Wrote 7 days in a row',
    icon: IconKind.streak7,
    type: AchievementType.streak,
    threshold: 7,
  ),
  Achievement(
    id: 'words_1000',
    title: 'Wordsmith',
    description: 'Wrote 1,000 words total',
    icon: IconKind.words1000,
    type: AchievementType.wordCount,
    threshold: 1000,
  ),
];

/// Pure evaluator — returns newly earned achievement ids.
Set<String> evaluateNewUnlocks(
  GamificationProfile profile,
  Set<String> alreadyUnlocked,
) {
  final newly = <String>{};
  for (final a in kAchievementCatalog) {
    if (alreadyUnlocked.contains(a.id)) continue;
    final met = switch (a.type) {
      AchievementType.streak =>
        profile.currentStreak >= a.threshold ||
            profile.longestStreak >= a.threshold,
      AchievementType.noteCount => profile.totalNotesCreated >= a.threshold,
      AchievementType.wordCount => profile.totalWordsWritten >= a.threshold,
    };
    if (met) newly.add(a.id);
  }
  return newly;
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Applies streak rules when the user writes today.
GamificationProfile applyWritingActivity({
  required GamificationProfile profile,
  required DateTime now,
  int wordsAdded = 0,
  bool noteCreated = false,
}) {
  final today = dateOnly(now);
  final last = profile.lastActiveDate == null
      ? null
      : dateOnly(profile.lastActiveDate!);

  var streak = profile.currentStreak;
  if (last == null) {
    streak = 1;
  } else if (last == today) {
    // already counted today
  } else if (last == today.subtract(const Duration(days: 1))) {
    streak = profile.currentStreak + 1;
  } else {
    streak = 1;
  }

  final recent = {...profile.recentActiveDates.map(dateOnly), today}.toList()
    ..sort();
  final trimmed = recent.length > 14
      ? recent.sublist(recent.length - 14)
      : recent;

  return profile.copyWith(
    currentStreak: streak,
    longestStreak: streak > profile.longestStreak
        ? streak
        : profile.longestStreak,
    lastActiveDate: today,
    totalNotesCreated: profile.totalNotesCreated + (noteCreated ? 1 : 0),
    totalWordsWritten: profile.totalWordsWritten + wordsAdded,
    recentActiveDates: trimmed,
  );
}

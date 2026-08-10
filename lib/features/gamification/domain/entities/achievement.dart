import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement.freezed.dart';

enum AchievementType { streak, noteCount, wordCount }

@freezed
class Achievement with _$Achievement {
  const factory Achievement({
    required String id,
    required String title,
    required String description,
    required IconKind icon,
    required AchievementType type,
    required int threshold,
  }) = _Achievement;
}

/// Icon kinds avoid asset files for MVP — mapped to Material icons in UI.
enum IconKind { firstNote, streak3, streak7, words1000 }

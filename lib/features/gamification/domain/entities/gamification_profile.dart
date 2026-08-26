import 'package:freezed_annotation/freezed_annotation.dart';

part 'gamification_profile.freezed.dart';

@freezed
class GamificationProfile with _$GamificationProfile {
  const factory GamificationProfile({
    @Default(0) int currentStreak,
    @Default(0) int longestStreak,
    DateTime? lastActiveDate,
    @Default(0) int totalNotesCreated,
    @Default(0) int totalWordsWritten,
    @Default(<DateTime>[]) List<DateTime> recentActiveDates,
    @Default(500) int weeklyWordsGoal,
    @Default(0) int weeklyWordsWritten,
    DateTime? weekStartDate,
  }) = _GamificationProfile;
}

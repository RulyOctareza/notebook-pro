import 'package:flutter/material.dart';

import 'package:notebook_pro/core/theme/app_colors.dart';

/// Tokens reserved exclusively for streaks and badge unlocks.
@immutable
class GamificationColors extends ThemeExtension<GamificationColors> {
  const GamificationColors({
    required this.streak,
    required this.streakTint,
    required this.badgeLocked,
  });

  final Color streak;
  final Color streakTint;
  final Color badgeLocked;

  static const light = GamificationColors(
    streak: AppColors.ember,
    streakTint: AppColors.emberTintLight,
    badgeLocked: AppColors.badgeLockedLight,
  );

  static const dark = GamificationColors(
    streak: AppColors.emberDark,
    streakTint: AppColors.emberTintDark,
    badgeLocked: AppColors.badgeLockedDark,
  );

  @override
  GamificationColors copyWith({
    Color? streak,
    Color? streakTint,
    Color? badgeLocked,
  }) {
    return GamificationColors(
      streak: streak ?? this.streak,
      streakTint: streakTint ?? this.streakTint,
      badgeLocked: badgeLocked ?? this.badgeLocked,
    );
  }

  @override
  GamificationColors lerp(ThemeExtension<GamificationColors>? other, double t) {
    if (other is! GamificationColors) return this;
    return GamificationColors(
      streak: Color.lerp(streak, other.streak, t)!,
      streakTint: Color.lerp(streakTint, other.streakTint, t)!,
      badgeLocked: Color.lerp(badgeLocked, other.badgeLocked, t)!,
    );
  }
}

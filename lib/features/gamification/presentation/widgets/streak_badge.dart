import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:notebook_pro/core/theme/app_spacing.dart';
import 'package:notebook_pro/core/theme/gamification_colors.dart';
import 'package:notebook_pro/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:notebook_pro/features/gamification/presentation/widgets/achievements_sheet.dart';

class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(gamificationProfileProvider);
    final colors = Theme.of(context).extension<GamificationColors>()!;
    final streak = profile.valueOrNull?.currentStreak ?? 0;

    return Tooltip(
      message: 'Writing streak',
      child: Material(
        color: colors.streakTint,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: () => AchievementsSheet.show(context),
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: colors.streak.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_outlined,
                  size: 16,
                  color: colors.streak,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$streak',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.streak,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

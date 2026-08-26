import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:notebook_pro/core/theme/app_spacing.dart';
import 'package:notebook_pro/core/theme/gamification_colors.dart';
import 'package:notebook_pro/features/gamification/domain/achievement_catalog.dart';
import 'package:notebook_pro/features/gamification/domain/entities/achievement.dart';
import 'package:notebook_pro/features/gamification/domain/entities/gamification_profile.dart';
import 'package:notebook_pro/features/gamification/presentation/providers/gamification_providers.dart';

class AchievementsSheet {
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const _AchievementsDialog(),
    );
  }
}

class _AchievementsDialog extends ConsumerWidget {
  const _AchievementsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.extension<GamificationColors>()!;
    final profile = ref.watch(gamificationProfileProvider).valueOrNull;
    final items = ref.watch(achievementsWithStatusProvider);
    final streak = profile?.currentStreak ?? 0;
    final recent = profile?.recentActiveDates ?? const <DateTime>[];

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streak',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: colors.streak,
                ),
              ),
              Text('day streak', style: theme.textTheme.labelSmall),
              const SizedBox(height: AppSpacing.lg),
              _HeatStrip(recent: recent, accent: colors.streak),
              if (profile != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Weekly goal', style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                _WeeklyGoalBar(profile: profile),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text('Achievements', style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final (achievement, unlocked) in items)
                    _BadgeMedallion(
                      achievement: achievement,
                      unlocked: unlocked,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeatStrip extends StatelessWidget {
  const _HeatStrip({required this.recent, required this.accent});

  final List<DateTime> recent;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final active = recent.map(dateOnly).toSet();
    return Row(
      children: List.generate(14, (i) {
        final day = today.subtract(Duration(days: 13 - i));
        final wrote = active.contains(day);
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: wrote ? accent : Colors.transparent,
              border: Border.all(
                color: wrote ? accent : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _WeeklyGoalBar extends StatelessWidget {
  const _WeeklyGoalBar({required this.profile});

  final GamificationProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<GamificationColors>()!;
    final goal = profile.weeklyWordsGoal <= 0 ? 500 : profile.weeklyWordsGoal;
    final progress = (profile.weeklyWordsWritten / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: colors.badgeLocked.withValues(alpha: 0.25),
            color: colors.streak,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${profile.weeklyWordsWritten} / $goal words this week',
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _BadgeMedallion extends StatelessWidget {
  const _BadgeMedallion({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<GamificationColors>()!;
    final icon = switch (achievement.icon) {
      IconKind.firstNote => Icons.edit_note_outlined,
      IconKind.streak3 => Icons.local_fire_department_outlined,
      IconKind.streak7 => Icons.emoji_events_outlined,
      IconKind.streak30 => Icons.whatshot_outlined,
      IconKind.streak100 => Icons.military_tech_outlined,
      IconKind.words1000 => Icons.menu_book_outlined,
      IconKind.words5000 => Icons.auto_stories_outlined,
      IconKind.words10000 => Icons.library_books_outlined,
      IconKind.notes10 => Icons.sticky_note_2_outlined,
      IconKind.notes50 => Icons.collections_bookmark_outlined,
      IconKind.notes100 => Icons.workspace_premium_outlined,
    };

    return Tooltip(
      message: '${achievement.title}\n${achievement.description}',
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? colors.streakTint
                  : colors.badgeLocked.withValues(alpha: 0.5),
              border: Border.all(
                color: unlocked ? colors.streak : colors.badgeLocked,
                width: unlocked ? 1.5 : 1,
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: unlocked ? colors.streak : colors.badgeLocked,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: 72,
            child: Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

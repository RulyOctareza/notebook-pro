import 'package:flutter/material.dart';

import 'package:notebook_pro/core/theme/app_spacing.dart';
import 'package:notebook_pro/core/theme/gamification_colors.dart';
import 'package:notebook_pro/features/gamification/domain/entities/achievement.dart';

class BadgeUnlockToast extends StatefulWidget {
  const BadgeUnlockToast({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  final Achievement achievement;
  final VoidCallback onDismiss;

  @override
  State<BadgeUnlockToast> createState() => _BadgeUnlockToastState();
}

class _BadgeUnlockToastState extends State<BadgeUnlockToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scale = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<GamificationColors>()!;
    final icon = switch (widget.achievement.icon) {
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

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Material(
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.streakTint,
                      border: Border.all(color: colors.streak),
                    ),
                    child: Icon(icon, size: 20, color: colors.streak),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Badge unlocked: ${widget.achievement.title}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.achievement.description,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

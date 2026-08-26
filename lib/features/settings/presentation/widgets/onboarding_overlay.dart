import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:notebook_pro/core/theme/app_spacing.dart';
import 'package:notebook_pro/features/settings/presentation/providers/app_prefs_providers.dart';

class OnboardingOverlay extends ConsumerWidget {
  const OnboardingOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.black54,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome to Notebook Pro', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'A calm, offline-first notepad for focused writing.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _Tip(
                    icon: Icons.note_add_outlined,
                    text: '⌘N creates a note — start typing, we autosave.',
                  ),
                  const _Tip(
                    icon: Icons.folder_outlined,
                    text: 'Organize with folders, tags (#hashtag), and Trash.',
                  ),
                  const _Tip(
                    icon: Icons.cloud_outlined,
                    text: 'Sign in with Google to sync across devices.',
                  ),
                  const _Tip(
                    icon: Icons.local_fire_department_outlined,
                    text: 'Daily streaks and a weekly word goal keep you writing.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () =>
                          ref.read(onboardingCompleteProvider.notifier).complete(),
                      child: const Text('Start writing'),
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

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

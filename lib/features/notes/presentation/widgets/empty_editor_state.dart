import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:notebook_pro/core/theme/app_colors.dart';
import 'package:notebook_pro/core/theme/app_spacing.dart';

class EmptyEditorState extends StatelessWidget {
  const EmptyEditorState({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tertiary = isDark
        ? AppColors.darkTextTertiary
        : AppColors.lightTextTertiary;
    final editorBg = isDark ? AppColors.darkEditor : AppColors.lightEditor;

    return ColoredBox(
      color: editorBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 48, color: tertiary),
            const SizedBox(height: AppSpacing.lg),
            Text('No note selected', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Select a note or press ⌘N to start writing',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New note'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Text(
                HardwareKeyboard.instance.isMetaPressed ||
                        Theme.of(context).platform == TargetPlatform.macOS
                    ? '⌘N'
                    : 'Ctrl+N',
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

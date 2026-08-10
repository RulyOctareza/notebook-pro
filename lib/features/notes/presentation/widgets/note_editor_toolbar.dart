import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:notebook_pro/core/theme/app_spacing.dart';

class NoteEditorToolbar extends StatelessWidget {
  const NoteEditorToolbar({
    super.key,
    required this.controller,
    required this.onInsertLink,
    required this.onInsertImage,
    this.onAfterFormat,
  });

  final QuillController controller;
  final VoidCallback onInsertLink;
  final VoidCallback onInsertImage;
  final VoidCallback? onAfterFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: AppLayout.toolbarHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
        ),
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToolBtn(
                  icon: Icons.format_bold,
                  tooltip: 'Bold',
                  onPressed: () => _toggle(Attribute.bold),
                ),
                _ToolBtn(
                  icon: Icons.format_italic,
                  tooltip: 'Italic',
                  onPressed: () => _toggle(Attribute.italic),
                ),
                _ToolBtn(
                  icon: Icons.format_underlined,
                  tooltip: 'Underline',
                  onPressed: () => _toggle(Attribute.underline),
                ),
                _Divider(),
                _ToolBtn(
                  icon: Icons.text_decrease,
                  tooltip: 'Decrease font size',
                  onPressed: () => _nudgeFontSize(-1),
                ),
                _ToolBtn(
                  icon: Icons.text_increase,
                  tooltip: 'Increase font size',
                  onPressed: () => _nudgeFontSize(1),
                ),
                _Divider(),
                _ToolBtn(
                  icon: Icons.title,
                  tooltip: 'Heading 1',
                  onPressed: () => _toggle(Attribute.h1),
                ),
                _ToolBtn(
                  icon: Icons.text_fields,
                  tooltip: 'Heading 2',
                  onPressed: () => _toggle(Attribute.h2),
                ),
                _ToolBtn(
                  icon: Icons.format_quote_outlined,
                  tooltip: 'Quote',
                  onPressed: () => _toggle(Attribute.blockQuote),
                ),
                _ToolBtn(
                  icon: Icons.format_list_bulleted,
                  tooltip: 'Bullet list',
                  onPressed: () => _toggle(Attribute.ul),
                ),
                _Divider(),
                _ToolBtn(
                  icon: Icons.link,
                  tooltip: 'Insert link (clipboard supported)',
                  onPressed: () {
                    onInsertLink();
                    onAfterFormat?.call();
                  },
                ),
                _ToolBtn(
                  icon: Icons.image_outlined,
                  tooltip: 'Insert image (clipboard or file)',
                  onPressed: () {
                    onInsertImage();
                    onAfterFormat?.call();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggle(Attribute attribute) {
    final attrs = controller.getSelectionStyle().attributes;
    final key = attribute.key;
    if (attrs.containsKey(key)) {
      controller.formatSelection(Attribute.clone(attribute, null));
    } else {
      controller.formatSelection(attribute);
    }
    onAfterFormat?.call();
  }

  static const _fontSizeSteps = <int>[12, 14, 16, 18, 20, 24, 28, 32];

  void _nudgeFontSize(int direction) {
    final raw = controller
        .getSelectionStyle()
        .attributes[Attribute.size.key]
        ?.value;
    final current = _resolveFontSize(raw);
    var index = 0;
    var bestDist = 1 << 30;
    for (var i = 0; i < _fontSizeSteps.length; i++) {
      final dist = (_fontSizeSteps[i] - current).abs();
      if (dist < bestDist) {
        bestDist = dist;
        index = i;
      }
    }
    final nextIndex = (index + direction).clamp(0, _fontSizeSteps.length - 1);
    final next = _fontSizeSteps[nextIndex];
    if (next == 16) {
      controller.formatSelection(Attribute.clone(Attribute.size, null));
    } else {
      controller.formatSelection(SizeAttribute('$next'));
    }
    onAfterFormat?.call();
  }

  int _resolveFontSize(Object? raw) {
    if (raw == null) return 16;
    return switch (raw) {
      'small' => 12,
      'large' => 18,
      'huge' => 24,
      final String s => double.tryParse(s)?.round() ?? 16,
      final num n => n.round(),
      _ => 16,
    };
  }
}

class _ToolBtn extends StatelessWidget {
  const _ToolBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          onTap: onPressed,
          child: SizedBox(width: 32, height: 32, child: Icon(icon, size: 18)),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: Theme.of(context).colorScheme.outline,
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:notebook_pro/core/theme/app_colors.dart';
import 'package:notebook_pro/core/theme/app_spacing.dart';
import 'package:notebook_pro/core/theme/app_theme.dart';
import 'package:notebook_pro/core/utils/debouncer.dart';
import 'package:notebook_pro/core/utils/id_generator.dart';
import 'package:notebook_pro/features/gamification/domain/achievement_catalog.dart';
import 'package:notebook_pro/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:notebook_pro/features/notes/domain/entities/note.dart';
import 'package:notebook_pro/features/notes/domain/note_content.dart';
import 'package:notebook_pro/features/notes/domain/repositories/note_repository.dart';
import 'package:notebook_pro/features/notes/domain/tag_extractor.dart';
import 'package:notebook_pro/features/notes/domain/title_from_body.dart';
import 'package:notebook_pro/features/notes/presentation/providers/notes_providers.dart';
import 'package:notebook_pro/features/notes/presentation/widgets/command_palette_dialog.dart';
import 'package:notebook_pro/features/notes/presentation/widgets/export_note_dialog.dart';
import 'package:notebook_pro/features/notes/presentation/widgets/note_editor_toolbar.dart';
import 'package:notebook_pro/features/settings/presentation/providers/app_prefs_providers.dart';
import 'package:notebook_pro/features/settings/presentation/providers/editor_zoom_provider.dart';

class NoteEditorPane extends ConsumerStatefulWidget {
  const NoteEditorPane({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<NoteEditorPane> createState() => _NoteEditorPaneState();
}

class _NoteEditorPaneState extends ConsumerState<NoteEditorPane>
    with SingleTickerProviderStateMixin {
  QuillController? _quill;
  final _titleController = TextEditingController();
  final _titleFocus = FocusNode();
  final _editorFocus = FocusNode();
  final _editorScroll = ScrollController();
  final _findController = TextEditingController();
  final _findFocus = FocusNode();
  final _debouncer = Debouncer();
  Note? _note;
  late final AnimationController _enterAnim;
  String? _loadedId;
  int _lastWordCount = 0;
  int _findMatchIndex = 0;
  List<int> _findMatches = const [];

  /// When true, title tracks the first ≤6 words of the body.
  bool _titleIsAuto = true;
  String _lastAutoTitle = '';

  /// Becomes true after the note has been persisted with real content.
  /// Empty drafts are discarded instead of autosaved.
  bool _everPersisted = false;
  late final NoteRepository _noteRepo;
  late final StateController<String?> _selectedNoteCtrl;

  @override
  void initState() {
    super.initState();
    _noteRepo = ref.read(noteRepositoryProvider);
    _selectedNoteCtrl = ref.read(selectedNoteIdProvider.notifier);
    _enterAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _load();
  }

  @override
  void didUpdateWidget(covariant NoteEditorPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noteId != widget.noteId) {
      _flushSave(previousNoteId: oldWidget.noteId);
      _load();
    }
  }

  Future<void> _load() async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.getById(widget.noteId);
    if (!mounted || note == null) return;

    _quill?.dispose();
    Document doc;
    try {
      final ops = jsonDecode(note.bodyDelta) as List<dynamic>;
      doc = Document.fromJson(ops);
    } catch (_) {
      doc = Document();
    }

    late final QuillController controller;
    controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          // Prefer image paste (⌘V / Ctrl+V) before HTML/text handlers.
          onClipboardPaste: () async {
            final bytes = await Pasteboard.image;
            if (bytes == null || bytes.isEmpty) return false;
            final path = await _persistImageBytes(bytes);
            if (path == null) return false;
            _embedImageAtController(controller, path);
            return true;
          },
          onImagePaste: (bytes) => _persistImageBytes(bytes),
        ),
      ),
    );
    controller.addListener(_onBodyChanged);

    final plain = doc.toPlainText();
    final hasContent = noteHasContent(title: note.title, plainBody: plain);

    setState(() {
      _note = note;
      _quill = controller;
      _loadedId = note.id;
      _titleController.text = note.title;
      _titleIsAuto = note.title.trim().isEmpty;
      _lastAutoTitle = '';
      _lastWordCount = _countWords(plain);
      _everPersisted = hasContent;
    });
    if (_titleIsAuto) {
      _syncAutoTitle(plain);
    }
    _enterAnim.forward(from: 0);
  }

  void _onBodyChanged() {
    final plain = _quill?.document.toPlainText() ?? '';
    if (_titleIsAuto) {
      _syncAutoTitle(plain);
    }
    _scheduleSave();
  }

  void _syncAutoTitle(String plain) {
    if (!_titleIsAuto) return;
    final derived = deriveTitleFromBody(plain);
    if (derived == _lastAutoTitle && _titleController.text == derived) {
      return;
    }
    _lastAutoTitle = derived;
    _titleController.value = TextEditingValue(
      text: derived,
      selection: TextSelection.collapsed(offset: derived.length),
    );
  }

  void _onTitleChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _titleIsAuto = true;
      _syncAutoTitle(_quill?.document.toPlainText() ?? '');
    } else if (trimmed != _lastAutoTitle) {
      _titleIsAuto = false;
    }
    _scheduleSave();
  }

  void _scheduleSave() {
    _debouncer.run(() => _save(fromTyping: true));
  }

  Future<void> _flushSave({String? previousNoteId}) async {
    _debouncer.cancel();
    final noteId = previousNoteId ?? widget.noteId;
    final note = _note;
    final quill = _quill;
    if (note == null || quill == null) return;

    final plain = quill.document.toPlainText();
    var title = _titleController.text.trim();
    if (title.isEmpty) title = deriveTitleFromBody(plain);

    if (!noteHasContent(title: title, plainBody: plain)) {
      if (!_everPersisted) {
        await _noteRepo.softDelete(noteId);
        if (mounted && ref.read(selectedNoteIdProvider) == noteId) {
          ref.read(selectedNoteIdProvider.notifier).state = null;
        }
      }
      return;
    }

    await _save(fromTyping: false, noteIdOverride: noteId);
  }

  Future<void> _save({required bool fromTyping, String? noteIdOverride}) async {
    final note = _note;
    final quill = _quill;
    final expectedId = noteIdOverride ?? widget.noteId;
    if (note == null || quill == null || _loadedId != expectedId) return;

    final plain = quill.document.toPlainText().trim();
    var title = _titleController.text.trim();
    if (title.isEmpty) {
      title = deriveTitleFromBody(plain);
      if (title.isNotEmpty && noteIdOverride == null) {
        _titleIsAuto = true;
        _syncAutoTitle(plain);
      }
    }

    // Empty notes are never autosaved.
    if (!noteHasContent(title: title, plainBody: plain)) {
      return;
    }

    final words = _countWords(plain);
    final wordsAdded = (words - _lastWordCount).clamp(0, 100000);
    _lastWordCount = words;
    final isFirstPersist = !_everPersisted;

    final tags = extractNoteTags(
      title: title,
      plainBody: plain,
      explicitTags: note.tags,
    );

    final updated = note.copyWith(
      title: title,
      subtitle: null,
      bodyDelta: jsonEncode(quill.document.toDelta().toJson()),
      plainTextPreview: plain.length > 160 ? plain.substring(0, 160) : plain,
      tags: tags,
      updatedAt: DateTime.now().toUtc(),
      isDirty: true,
    );
    _note = updated;
    await _noteRepo.update(updated);
    _everPersisted = true;

    // Fire-and-forget cloud sync (no-op when Firebase is offline/unavailable).
    unawaited(ref.read(syncServiceProvider).pushPendingChanges());

    if (fromTyping || isFirstPersist) {
      final newly = await ref
          .read(gamificationRepositoryProvider)
          .recordWritingActivity(
            wordsAdded: wordsAdded,
            noteCreated: isFirstPersist,
          );
      _pushUnlocks(newly);
    }
  }

  void _pushUnlocks(List<String> ids) {
    if (ids.isEmpty) return;
    final catalog = {for (final a in kAchievementCatalog) a.id: a};
    final pending = ref.read(pendingUnlocksProvider.notifier);
    final current = [...ref.read(pendingUnlocksProvider)];
    for (final id in ids) {
      final a = catalog[id];
      if (a != null) current.add(a);
    }
    pending.state = current;
  }

  int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  Future<String?> _clipboardText() async {
    final fromPasteboard = await Pasteboard.text;
    if (fromPasteboard != null && fromPasteboard.trim().isNotEmpty) {
      return fromPasteboard.trim();
    }
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text?.trim();
  }

  Future<void> _insertLink() async {
    final quill = _quill;
    if (quill == null) return;

    final clip = await _clipboardText();
    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _InsertLinkDialog(
        initialUrl: looksLikeUrl(clip) ? clip! : '',
        clipboardUrl: looksLikeUrl(clip) ? clip : null,
      ),
    );

    if (result == null || result.trim().isEmpty) return;
    final url = normalizeUrl(result);
    final index = quill.selection.baseOffset;
    final length = quill.selection.extentOffset - index;
    if (length > 0) {
      quill.formatSelection(LinkAttribute(url));
    } else {
      quill.document.insert(index, url);
      quill.formatText(index, url.length, LinkAttribute(url));
      quill.updateSelection(
        TextSelection.collapsed(offset: index + url.length),
        ChangeSource.local,
      );
    }
    _scheduleSave();
  }

  Future<void> _insertImage() async {
    final quill = _quill;
    final note = _note;
    if (quill == null || note == null) return;

    final clipboardBytes = await Pasteboard.image;
    if (!mounted) return;
    if (clipboardBytes != null && clipboardBytes.isNotEmpty) {
      final choice = await showDialog<_ImageSourceChoice>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Insert image'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, _ImageSourceChoice.clipboard),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.content_paste_outlined),
                title: Text('From clipboard'),
                subtitle: Text('Paste the copied image'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, _ImageSourceChoice.file),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.folder_open_outlined),
                title: Text('From file…'),
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (choice == _ImageSourceChoice.clipboard) {
        await _insertImageBytes(clipboardBytes);
        return;
      }
      if (choice == _ImageSourceChoice.file) {
        await _insertImageFromFile();
      }
      return;
    }

    await _insertImageFromFile();
  }

  Future<void> _insertImageFromFile() async {
    const typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    final docs = await getApplicationDocumentsDirectory();
    final note = _note!;
    final dir = Directory(p.join(docs.path, 'notebook_pro', 'images', note.id));
    await dir.create(recursive: true);
    final ext = p.extension(file.path);
    final destPath = p.join(dir.path, '${IdGenerator.next()}$ext');
    await File(file.path).copy(destPath);
    _trackImagePath(destPath);
    await _embedImagePath(destPath);
  }

  Future<void> _insertImageBytes(Uint8List bytes) async {
    final destPath = await _persistImageBytes(bytes);
    if (destPath == null) return;
    await _embedImagePath(destPath);
  }

  /// Saves clipboard image bytes under the note's local image folder.
  ///
  /// Returns the absolute path for Quill `BlockEmbed.image`, or null if the
  /// editor has no note loaded.
  Future<String?> _persistImageBytes(Uint8List bytes) async {
    final note = _note;
    if (note == null || bytes.isEmpty) return null;

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'notebook_pro', 'images', note.id));
    await dir.create(recursive: true);
    final destPath = p.join(dir.path, '${IdGenerator.next()}.png');
    await File(destPath).writeAsBytes(bytes, flush: true);
    _trackImagePath(destPath);
    return destPath;
  }

  void _trackImagePath(String destPath) {
    final note = _note;
    if (note == null) return;
    if (note.imagePaths.contains(destPath)) return;
    _note = note.copyWith(imagePaths: [...note.imagePaths, destPath]);
    _scheduleSave();
  }

  void _embedImageAtController(QuillController quill, String destPath) {
    final index = quill.selection.baseOffset;
    quill.document.insert(index, BlockEmbed.image(destPath));
    quill.document.insert(index + 1, '\n');
    quill.updateSelection(
      TextSelection.collapsed(offset: index + 2),
      ChangeSource.local,
    );
    _editorFocus.requestFocus();
  }

  void _toggleFormat(Attribute attribute) {
    final quill = _quill;
    if (quill == null) return;
    final style = quill.getSelectionStyle();
    final has = style.attributes.containsKey(attribute.key);
    quill.formatSelection(has ? Attribute.clone(attribute, null) : attribute);
    _editorFocus.requestFocus();
  }

  void _runFind(String query) {
    final quill = _quill;
    if (quill == null) return;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _findMatches = const [];
        _findMatchIndex = 0;
      });
      return;
    }
    final plain = quill.document.toPlainText().toLowerCase();
    final matches = <int>[];
    var from = 0;
    while (true) {
      final i = plain.indexOf(q, from);
      if (i < 0) break;
      matches.add(i);
      from = i + q.length;
    }
    setState(() {
      _findMatches = matches;
      _findMatchIndex = matches.isEmpty ? 0 : 0;
    });
    if (matches.isNotEmpty) _jumpToFindMatch(0);
  }

  void _jumpToFindMatch(int index) {
    final quill = _quill;
    if (quill == null || _findMatches.isEmpty) return;
    final i = index % _findMatches.length;
    final start = _findMatches[i];
    final len = _findController.text.trim().length;
    setState(() => _findMatchIndex = i);
    quill.updateSelection(
      TextSelection(baseOffset: start, extentOffset: start + len),
      ChangeSource.local,
    );
    _editorFocus.requestFocus();
  }

  Future<void> _embedImagePath(String destPath) async {
    final quill = _quill;
    if (quill == null) return;
    _embedImageAtController(quill, destPath);
  }

  DefaultStyles _editorStyles(BuildContext context) {
    final theme = Theme.of(context);
    final base = DefaultStyles.getInstance(context);
    final body = theme.textTheme.bodyLarge!;
    final h1 = theme.textTheme.headlineLarge!;
    final h2 = theme.textTheme.titleLarge!.copyWith(
      fontFamily: AppTheme.readingFamily,
      fontSize: 20,
      height: 28 / 20,
    );
    return base.merge(
      DefaultStyles(
        paragraph: DefaultTextBlockStyle(
          body,
          const HorizontalSpacing(0, 0),
          const VerticalSpacing(0, 6),
          const VerticalSpacing(0, 0),
          null,
        ),
        placeHolder: DefaultTextBlockStyle(
          body.copyWith(color: theme.hintColor),
          const HorizontalSpacing(0, 0),
          const VerticalSpacing(0, 0),
          const VerticalSpacing(0, 0),
          null,
        ),
        h1: DefaultTextBlockStyle(
          h1,
          const HorizontalSpacing(0, 0),
          const VerticalSpacing(12, 4),
          const VerticalSpacing(0, 0),
          null,
        ),
        h2: DefaultTextBlockStyle(
          h2,
          const HorizontalSpacing(0, 0),
          const VerticalSpacing(10, 4),
          const VerticalSpacing(0, 0),
          null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debouncer.cancel();
    final shouldDiscard = !_everPersisted;
    final noteId = widget.noteId;
    final quill = _quill;
    final title = _titleController.text;
    final plain = quill?.document.toPlainText() ?? '';
    final stillEmpty = !noteHasContent(title: title, plainBody: plain);

    _quill?.dispose();
    _titleController.dispose();
    _titleFocus.dispose();
    _editorFocus.dispose();
    _editorScroll.dispose();
    _findController.dispose();
    _findFocus.dispose();
    _enterAnim.dispose();
    _debouncer.dispose();
    super.dispose();

    // Discard never-persisted empty drafts when leaving the editor.
    if (shouldDiscard && stillEmpty) {
      _noteRepo.softDelete(noteId).then((_) {
        if (_selectedNoteCtrl.state == noteId) {
          _selectedNoteCtrl.state = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final editorBg = isDark ? AppColors.darkEditor : AppColors.lightEditor;
    final tertiary = isDark
        ? AppColors.darkTextTertiary
        : AppColors.lightTextTertiary;
    final quill = _quill;
    final note = _note;

    if (quill == null || note == null) {
      return ColoredBox(
        color: editorBg,
        child: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final words = _countWords(quill.document.toPlainText());
    final edited = DateFormat.MMMd().add_jm().format(note.updatedAt.toLocal());
    final zoom = ref.watch(editorZoomProvider);
    final zoomLabel = zoom == 1.0 ? null : ' · ${(zoom * 100).round()}%';
    final focusMode = ref.watch(focusModeProvider);
    final showFind = ref.watch(findInNoteVisibleProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () =>
            _toggleFormat(Attribute.bold),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
            _toggleFormat(Attribute.bold),
        const SingleActivator(LogicalKeyboardKey.keyI, meta: true): () =>
            _toggleFormat(Attribute.italic),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
            _toggleFormat(Attribute.italic),
        const SingleActivator(LogicalKeyboardKey.keyU, meta: true): () =>
            _toggleFormat(Attribute.underline),
        const SingleActivator(LogicalKeyboardKey.keyU, control: true): () =>
            _toggleFormat(Attribute.underline),
      },
      child: ColoredBox(
        color: editorBg,
        child: Column(
          children: [
            if (!focusMode)
              NoteEditorToolbar(
                controller: quill,
                onInsertLink: _insertLink,
                onInsertImage: _insertImage,
                onExport: () => ExportNoteDialog.show(context, _note!),
                onCommandPalette: () => CommandPaletteDialog.show(context),
                onAfterFormat: () => _editorFocus.requestFocus(),
              ),
            if (showFind)
              Material(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _findController,
                          focusNode: _findFocus,
                          autofocus: true,
                          style: theme.textTheme.bodySmall,
                          decoration: const InputDecoration(
                            hintText: 'Find in note',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: _runFind,
                          onSubmitted: (_) {
                            if (_findMatches.isNotEmpty) {
                              _jumpToFindMatch(_findMatchIndex + 1);
                            }
                          },
                        ),
                      ),
                      Text(
                        _findMatches.isEmpty
                            ? '0'
                            : '${_findMatchIndex + 1}/${_findMatches.length}',
                        style: theme.textTheme.labelSmall,
                      ),
                      IconButton(
                        tooltip: 'Previous',
                        onPressed: _findMatches.isEmpty
                            ? null
                            : () => _jumpToFindMatch(_findMatchIndex - 1),
                        icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        tooltip: 'Next',
                        onPressed: _findMatches.isEmpty
                            ? null
                            : () => _jumpToFindMatch(_findMatchIndex + 1),
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () {
                          ref.read(findInNoteVisibleProvider.notifier).state =
                              false;
                          _findController.clear();
                          setState(() {
                            _findMatches = const [];
                            _findMatchIndex = 0;
                          });
                        },
                        icon: const Icon(Icons.close, size: 16),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: FadeTransition(
                opacity: _enterAnim,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.02),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _enterAnim,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columnWidth = constraints.maxWidth.clamp(
                        0.0,
                        AppLayout.editorMaxContent,
                      );
                      final padH = columnWidth < 420
                          ? AppSpacing.lg
                          : AppSpacing.xxl;
                      return Align(
                        alignment: Alignment.topCenter,
                        child: Transform.scale(
                          scale: zoom,
                          alignment: Alignment.topCenter,
                          filterQuality: FilterQuality.medium,
                          child: SizedBox(
                            width: columnWidth,
                            height: constraints.maxHeight,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                padH,
                                AppSpacing.xxl,
                                padH,
                                AppSpacing.xl,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _titleController,
                                    focusNode: _titleFocus,
                                    style: theme.textTheme.headlineLarge,
                                    decoration: InputDecoration(
                                      hintText: 'Title',
                                      hintStyle: theme
                                          .textTheme.headlineLarge
                                          ?.copyWith(color: tertiary),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: _onTitleChanged,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      Text(
                                        '$edited · $words words${zoomLabel ?? ''}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(color: tertiary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  Expanded(
                                    child: QuillEditor(
                                      controller: quill,
                                      focusNode: _editorFocus,
                                      scrollController: _editorScroll,
                                      config: QuillEditorConfig(
                                        placeholder: 'Start writing…',
                                        padding: EdgeInsets.zero,
                                        embedBuilders: [
                                          _LocalImageEmbedBuilder(),
                                        ],
                                        customStyles: _editorStyles(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


enum _ImageSourceChoice { clipboard, file }

class _InsertLinkDialog extends StatefulWidget {
  const _InsertLinkDialog({required this.initialUrl, this.clipboardUrl});

  final String initialUrl;
  final String? clipboardUrl;

  @override
  State<_InsertLinkDialog> createState() => _InsertLinkDialogState();
}

class _InsertLinkDialogState extends State<_InsertLinkDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final clip = widget.clipboardUrl;
    return AlertDialog(
      title: const Text('Insert link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'https://…',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (clip != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  _controller.text = clip;
                  _controller.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: clip.length,
                  );
                },
                icon: const Icon(Icons.content_paste_outlined, size: 16),
                label: const Text('Use clipboard'),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Insert')),
      ],
    );
  }
}

class _LocalImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final path = embedContext.node.value.data;
    if (path is! String) return const SizedBox.shrink();
    final file = File(path);
    if (!file.existsSync()) {
      return const Icon(Icons.broken_image_outlined);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Image.file(file, fit: BoxFit.contain, cacheWidth: 1400),
      ),
    );
  }
}

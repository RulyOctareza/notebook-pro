import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notebook_pro/core/theme/app_spacing.dart';
import 'package:notebook_pro/features/settings/presentation/providers/theme_mode_provider.dart';

/// Persisted widths for the folder sidebar and note list panes.
final panelLayoutProvider =
    StateNotifierProvider<PanelLayoutNotifier, PanelLayout>((ref) {
      return PanelLayoutNotifier(ref.watch(sharedPreferencesProvider));
    });

class PanelLayout {
  const PanelLayout({required this.folderWidth, required this.listWidth});

  final double folderWidth;
  final double listWidth;

  PanelLayout copyWith({double? folderWidth, double? listWidth}) {
    return PanelLayout(
      folderWidth: folderWidth ?? this.folderWidth,
      listWidth: listWidth ?? this.listWidth,
    );
  }
}

class PanelLayoutNotifier extends StateNotifier<PanelLayout> {
  PanelLayoutNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;
  static const _folderKey = 'panel_folder_width';
  static const _listKey = 'panel_list_width';

  static PanelLayout _read(SharedPreferences prefs) {
    return PanelLayout(
      folderWidth: (prefs.getDouble(_folderKey) ?? AppLayout.folderSidebarWidth)
          .clamp(AppLayout.folderMin, AppLayout.folderMax),
      listWidth: (prefs.getDouble(_listKey) ?? AppLayout.noteListWidth).clamp(
        AppLayout.noteListMin,
        AppLayout.noteListMax,
      ),
    );
  }

  void setFolderWidth(double width, {bool persist = false}) {
    final next = width.clamp(AppLayout.folderMin, AppLayout.folderMax);
    if (next == state.folderWidth && !persist) return;
    state = state.copyWith(folderWidth: next);
    if (persist) {
      _prefs.setDouble(_folderKey, next);
    }
  }

  void setListWidth(double width, {bool persist = false}) {
    final next = width.clamp(AppLayout.noteListMin, AppLayout.noteListMax);
    if (next == state.listWidth && !persist) return;
    state = state.copyWith(listWidth: next);
    if (persist) {
      _prefs.setDouble(_listKey, next);
    }
  }

  Future<void> resetFolder() async {
    state = state.copyWith(folderWidth: AppLayout.folderSidebarWidth);
    await _prefs.setDouble(_folderKey, AppLayout.folderSidebarWidth);
  }

  Future<void> resetList() async {
    state = state.copyWith(listWidth: AppLayout.noteListWidth);
    await _prefs.setDouble(_listKey, AppLayout.noteListWidth);
  }
}

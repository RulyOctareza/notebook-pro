import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notebook_pro/features/settings/presentation/providers/theme_mode_provider.dart';

/// Whether the middle note-title list pane is visible.
final noteListVisibleProvider =
    StateNotifierProvider<NoteListVisibleNotifier, bool>((ref) {
      return NoteListVisibleNotifier(ref.watch(sharedPreferencesProvider));
    });

class NoteListVisibleNotifier extends StateNotifier<bool> {
  NoteListVisibleNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'note_list_visible';

  static bool _read(SharedPreferences prefs) => prefs.getBool(_key) ?? true;

  Future<void> setVisible(bool visible) async {
    state = visible;
    await _prefs.setBool(_key, visible);
  }

  Future<void> toggle() => setVisible(!state);
}

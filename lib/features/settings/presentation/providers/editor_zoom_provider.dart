import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notebook_pro/features/settings/presentation/providers/theme_mode_provider.dart';

/// Editor display zoom (view scale), independent of per-selection font size.
final editorZoomProvider = StateNotifierProvider<EditorZoomNotifier, double>((
  ref,
) {
  return EditorZoomNotifier(ref.watch(sharedPreferencesProvider));
});

class EditorZoomNotifier extends StateNotifier<double> {
  EditorZoomNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'editor_zoom';
  static const min = 0.75;
  static const max = 2.0;
  static const step = 0.1;
  static const initial = 1.0;

  static double _read(SharedPreferences prefs) {
    final raw = prefs.getDouble(_key);
    if (raw == null) return initial;
    return raw.clamp(min, max);
  }

  Future<void> _persist(double value) async {
    state = value;
    await _prefs.setDouble(_key, value);
  }

  Future<void> zoomIn() async {
    final next = (state + step).clamp(min, max);
    final rounded = double.parse(next.toStringAsFixed(1));
    await _persist(rounded);
  }

  Future<void> zoomOut() async {
    final next = (state - step).clamp(min, max);
    final rounded = double.parse(next.toStringAsFixed(1));
    await _persist(rounded);
  }

  Future<void> reset() async => _persist(initial);
}

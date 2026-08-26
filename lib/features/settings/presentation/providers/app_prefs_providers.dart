import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notebook_pro/features/settings/presentation/providers/theme_mode_provider.dart';

final focusModeProvider =
    StateNotifierProvider<FocusModeNotifier, bool>((ref) {
  return FocusModeNotifier();
});

class FocusModeNotifier extends StateNotifier<bool> {
  FocusModeNotifier() : super(false);

  void toggle() => state = !state;

  void setEnabled(bool value) => state = value;

  void exit() => state = false;
}

enum NoteSortOption { updatedDesc, updatedAsc, titleAsc, createdDesc }

final noteSortProvider =
    StateNotifierProvider<NoteSortNotifier, NoteSortOption>((ref) {
  return NoteSortNotifier(ref.watch(sharedPreferencesProvider));
});

class NoteSortNotifier extends StateNotifier<NoteSortOption> {
  NoteSortNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'note_sort';

  static NoteSortOption _read(SharedPreferences prefs) {
    return switch (prefs.getString(_key)) {
      'updatedAsc' => NoteSortOption.updatedAsc,
      'titleAsc' => NoteSortOption.titleAsc,
      'createdDesc' => NoteSortOption.createdDesc,
      _ => NoteSortOption.updatedDesc,
    };
  }

  Future<void> setSort(NoteSortOption option) async {
    state = option;
    final value = switch (option) {
      NoteSortOption.updatedDesc => 'updatedDesc',
      NoteSortOption.updatedAsc => 'updatedAsc',
      NoteSortOption.titleAsc => 'titleAsc',
      NoteSortOption.createdDesc => 'createdDesc',
    };
    await _prefs.setString(_key, value);
  }
}

final findInNoteVisibleProvider = StateProvider<bool>((ref) => false);

final onboardingCompleteProvider =
    StateNotifierProvider<OnboardingCompleteNotifier, bool>((ref) {
  return OnboardingCompleteNotifier(ref.watch(sharedPreferencesProvider));
});

class OnboardingCompleteNotifier extends StateNotifier<bool> {
  OnboardingCompleteNotifier(this._prefs)
      : super(_prefs.getBool(_key) ?? false);

  final SharedPreferences _prefs;
  static const _key = 'onboarding_complete';

  Future<void> complete() async {
    state = true;
    await _prefs.setBool(_key, true);
  }
}

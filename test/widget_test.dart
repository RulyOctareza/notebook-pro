import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_pro/app/app.dart';
import 'package:notebook_pro/core/database/app_database.dart';
import 'package:notebook_pro/features/notes/presentation/providers/notes_providers.dart';
import 'package:notebook_pro/features/settings/presentation/providers/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  required SharedPreferences prefs,
  required AppDatabase db,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const NotebookApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _teardownApp(WidgetTester tester, AppDatabase db) async {
  // Unmount providers first, then flush Drift's zero-duration close timers.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
  await db.close();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home shell shows empty state', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    await db.ensureProfile();

    await _pumpApp(tester, prefs: prefs, db: db);

    expect(find.text('No note selected'), findsOneWidget);
    expect(find.text('New note'), findsWidgets);

    await _teardownApp(tester, db);
  });

  testWidgets('theme cycle toggles mode', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    await db.ensureProfile();

    await _pumpApp(tester, prefs: prefs, db: db);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(NotebookApp)),
    );
    expect(container.read(themeModeProvider), ThemeMode.system);
    await container.read(themeModeProvider.notifier).cycle();
    expect(container.read(themeModeProvider), ThemeMode.light);
    await container.read(themeModeProvider.notifier).cycle();
    expect(container.read(themeModeProvider), ThemeMode.dark);

    await _teardownApp(tester, db);
  });
}

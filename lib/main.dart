import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notebook_pro/app/app.dart';
import 'package:notebook_pro/core/auth/auth_providers.dart';
import 'package:notebook_pro/core/database/app_database.dart';
import 'package:notebook_pro/features/notes/presentation/providers/notes_providers.dart';
import 'package:notebook_pro/features/settings/presentation/providers/theme_mode_provider.dart';
import 'package:notebook_pro/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e, s) {
    developer.log(
      'Firebase init failed — continuing offline-only',
      name: 'notebook_pro',
      error: e,
      stackTrace: s,
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase();
  await db.ensureProfile();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(db),
      firebaseReadyProvider.overrideWithValue(firebaseReady),
    ],
  );

  if (firebaseReady) {
    unawaited(
      container.read(authServiceProvider).initializeGoogleSignIn().then((_) {
        return container.read(syncServiceProvider).pushPendingChanges();
      }),
    );
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NotebookApp(),
    ),
  );
}

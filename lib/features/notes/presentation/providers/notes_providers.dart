import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:notebook_pro/core/database/app_database.dart';
import 'package:notebook_pro/core/sync/firebase_sync_service.dart';
import 'package:notebook_pro/core/sync/noop_sync_service.dart';
import 'package:notebook_pro/core/sync/sync_service.dart';
import 'package:notebook_pro/features/gamification/data/repositories/gamification_repository_impl.dart';
import 'package:notebook_pro/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:notebook_pro/features/notes/data/repositories/folder_repository_impl.dart';
import 'package:notebook_pro/features/notes/data/repositories/note_repository_impl.dart';
import 'package:notebook_pro/features/notes/domain/entities/note.dart';
import 'package:notebook_pro/features/notes/domain/entities/note_folder.dart';
import 'package:notebook_pro/features/notes/domain/repositories/folder_repository.dart';
import 'package:notebook_pro/features/notes/domain/repositories/note_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Overridden in [main] after [Firebase.initializeApp] succeeds.
final firebaseReadyProvider = Provider<bool>((ref) => false);

final syncServiceProvider = Provider<SyncService>((ref) {
  if (!ref.watch(firebaseReadyProvider)) {
    return NoopSyncService();
  }
  return FirebaseSyncService(db: ref.watch(appDatabaseProvider));
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(ref.watch(appDatabaseProvider));
});

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return FolderRepositoryImpl(ref.watch(appDatabaseProvider));
});

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepositoryImpl(ref.watch(appDatabaseProvider));
});

/// `null` = All Notes, [kInboxFolderId] (`''`) = Inbox, otherwise folder uuid.
final selectedFolderIdProvider = StateProvider<String?>((ref) => null);

final foldersProvider = StreamProvider<List<NoteFolder>>((ref) {
  return ref.watch(folderRepositoryProvider).watchFolders();
});

final noteCountsByFolderProvider = StreamProvider<Map<String?, int>>((ref) {
  return ref.watch(noteRepositoryProvider).watchNoteCountsByFolder();
});

final notesListProvider = StreamProvider<List<Note>>((ref) {
  final selected = ref.watch(selectedFolderIdProvider);
  final repo = ref.watch(noteRepositoryProvider);
  if (selected == null) {
    return repo.watchNotes();
  }
  if (selected == kInboxFolderId) {
    return repo.watchNotes(inboxOnly: true);
  }
  return repo.watchNotes(folderId: selected);
});

final selectedNoteIdProvider = StateProvider<String?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notes = ref.watch(notesListProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  return notes.whenData((list) {
    if (query.isEmpty) return list;
    return list
        .where(
          (n) =>
              n.title.toLowerCase().contains(query) ||
              n.plainTextPreview.toLowerCase().contains(query),
        )
        .toList();
  });
});

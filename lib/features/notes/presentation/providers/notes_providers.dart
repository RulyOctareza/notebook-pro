import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:notebook_pro/core/backup/backup_service.dart';
import 'package:notebook_pro/core/database/app_database.dart';
import 'package:notebook_pro/core/sync/firebase_sync_service.dart';
import 'package:notebook_pro/core/sync/noop_sync_service.dart';
import 'package:notebook_pro/core/sync/sync_service.dart';
import 'package:notebook_pro/core/sync/sync_status.dart';
import 'package:notebook_pro/features/gamification/data/repositories/gamification_repository_impl.dart';
import 'package:notebook_pro/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:notebook_pro/features/notes/data/repositories/folder_repository_impl.dart';
import 'package:notebook_pro/features/notes/data/repositories/note_repository_impl.dart';
import 'package:notebook_pro/features/notes/domain/entities/note.dart';
import 'package:notebook_pro/features/notes/domain/entities/note_folder.dart';
import 'package:notebook_pro/features/notes/domain/repositories/folder_repository.dart';
import 'package:notebook_pro/features/notes/domain/repositories/note_repository.dart';
import 'package:notebook_pro/features/settings/presentation/providers/app_prefs_providers.dart';

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

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(syncServiceProvider).status;
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(appDatabaseProvider));
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

/// `null` = All Notes, [kInboxFolderId] (`''`) = Inbox,
/// [kTrashFolderId] = Trash, otherwise folder uuid.
final selectedFolderIdProvider = StateProvider<String?>((ref) => null);

final foldersProvider = StreamProvider<List<NoteFolder>>((ref) {
  return ref.watch(folderRepositoryProvider).watchFolders();
});

final noteCountsByFolderProvider = StreamProvider<Map<String?, int>>((ref) {
  return ref.watch(noteRepositoryProvider).watchNoteCountsByFolder();
});

final trashCountProvider = StreamProvider<int>((ref) {
  return ref.watch(noteRepositoryProvider).watchTrashCount();
});

final notesListProvider = StreamProvider<List<Note>>((ref) {
  final selected = ref.watch(selectedFolderIdProvider);
  final repo = ref.watch(noteRepositoryProvider);
  if (selected == kTrashFolderId) {
    return repo.watchDeletedNotes();
  }
  if (selected == null) {
    return repo.watchNotes();
  }
  if (selected == kInboxFolderId) {
    return repo.watchNotes(inboxOnly: true);
  }
  return repo.watchNotes(folderId: selected);
});

/// `null` = no tag filter, otherwise lowercase tag name without `#`.
final selectedTagProvider = StateProvider<String?>((ref) => null);

final allTagsProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(noteRepositoryProvider).watchAllTagsWithCounts();
});

final selectedNoteIdProvider = StateProvider<String?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notes = ref.watch(notesListProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final selectedTag = ref.watch(selectedTagProvider);
  final sort = ref.watch(noteSortProvider);
  final inTrash = ref.watch(selectedFolderIdProvider) == kTrashFolderId;

  return notes.whenData((list) {
    var result = list;
    if (!inTrash && selectedTag != null && selectedTag.isNotEmpty) {
      result = result
          .where(
            (n) => n.tags.any(
              (t) => t.toLowerCase().trim() == selectedTag.toLowerCase().trim(),
            ),
          )
          .toList();
    }
    if (query.isNotEmpty) {
      result = result
          .where(
            (n) =>
                n.title.toLowerCase().contains(query) ||
                n.plainTextPreview.toLowerCase().contains(query) ||
                n.tags.any((t) => t.toLowerCase().contains(query)),
          )
          .toList();
    }

    result = List<Note>.from(result);
    switch (sort) {
      case NoteSortOption.updatedDesc:
        result.sort((a, b) {
          final pin = (b.isPinned ? 1 : 0).compareTo(a.isPinned ? 1 : 0);
          if (pin != 0) return pin;
          return b.updatedAt.compareTo(a.updatedAt);
        });
      case NoteSortOption.updatedAsc:
        result.sort((a, b) {
          final pin = (b.isPinned ? 1 : 0).compareTo(a.isPinned ? 1 : 0);
          if (pin != 0) return pin;
          return a.updatedAt.compareTo(b.updatedAt);
        });
      case NoteSortOption.titleAsc:
        result.sort((a, b) {
          final pin = (b.isPinned ? 1 : 0).compareTo(a.isPinned ? 1 : 0);
          if (pin != 0) return pin;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
      case NoteSortOption.createdDesc:
        result.sort((a, b) {
          final pin = (b.isPinned ? 1 : 0).compareTo(a.isPinned ? 1 : 0);
          if (pin != 0) return pin;
          return b.createdAt.compareTo(a.createdAt);
        });
    }
    return result;
  });
});

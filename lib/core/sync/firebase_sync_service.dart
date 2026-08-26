import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:notebook_pro/core/database/app_database.dart';
import 'package:notebook_pro/core/sync/sync_service.dart';
import 'package:notebook_pro/core/sync/sync_status.dart';
import 'package:notebook_pro/features/notes/domain/entities/note.dart';
import 'package:notebook_pro/features/notes/domain/entities/note_folder.dart';

/// Offline-first sync: local Drift is source of truth while editing;
/// dirty rows are pushed to Firestore under `users/{uid}/…`.
class FirebaseSyncService implements SyncService {
  FirebaseSyncService({
    required AppDatabase db,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _db = db,
       _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final AppDatabase _db;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final _status = StreamController<SyncStatus>.broadcast();
  SyncStatus _current = SyncStatus.pending;
  DateTime? _lastSyncedAt;
  bool _running = false;
  bool _hadConflict = false;

  @override
  Stream<SyncStatus> get status async* {
    yield _current;
    yield* _status.stream;
  }

  @override
  DateTime? get lastSyncedAt => _lastSyncedAt;

  void _setStatus(SyncStatus next) {
    _current = next;
    if (!_status.isClosed) _status.add(next);
  }

  Future<User?> _ensureUser() async {
    final existing = _auth.currentUser;
    if (existing == null || existing.isAnonymous) {
      _setStatus(SyncStatus.offline);
      return null;
    }
    return existing;
  }

  @override
  Future<void> pushPendingChanges() async {
    if (_running) return;
    _running = true;
    _hadConflict = false;
    _setStatus(SyncStatus.pending);
    try {
      final user = await _ensureUser();
      if (user == null) return;

      final uid = user.uid;
      final userRoot = _firestore.collection('users').doc(uid);

      final folders = await _db.allFolders();
      if (folders.isNotEmpty) {
        final folderBatch = _firestore.batch();
        for (final folder in folders) {
          folderBatch.set(
            userRoot.collection('folders').doc(folder.id),
            _folderToMap(folder),
            SetOptions(merge: true),
          );
        }
        await folderBatch.commit();
      }

      final dirty = await _db.dirtyNotes();
      for (final note in dirty) {
        await userRoot.collection('notes').doc(note.id).set(
          _noteToMap(note),
          SetOptions(merge: true),
        );
        await _db.markNoteClean(note.id, remoteId: note.id);
      }

      await _pullFolders(userRoot);
      await _pullNotes(userRoot);

      _lastSyncedAt = DateTime.now().toUtc();
      _setStatus(_hadConflict ? SyncStatus.conflict : SyncStatus.synced);
    } catch (e, s) {
      developer.log(
        'Sync failed',
        name: 'notebook_pro.sync',
        error: e,
        stackTrace: s,
        level: 1000,
      );
      _setStatus(SyncStatus.offline);
    } finally {
      _running = false;
    }
  }

  Future<void> _pullFolders(
    DocumentReference<Map<String, dynamic>> userRoot,
  ) async {
    final snap = await userRoot.collection('folders').get();
    final local = {for (final f in await _db.allFolders()) f.id: f};
    for (final doc in snap.docs) {
      final remote = _folderFromMap(doc.id, doc.data());
      final existing = local[remote.id];
      if (existing == null || remote.updatedAt.isAfter(existing.updatedAt)) {
        await _db.upsertFolder(remote);
      }
    }
  }

  Future<void> _pullNotes(
    DocumentReference<Map<String, dynamic>> userRoot,
  ) async {
    final snap = await userRoot.collection('notes').get();
    for (final doc in snap.docs) {
      final remote = _noteFromMap(doc.id, doc.data());
      final existing = await _db.getNoteById(remote.id);

      if (existing == null) {
        await _db.upsertNote(
          remote.copyWith(isDirty: false, remoteId: remote.id),
        );
        continue;
      }

      // Local dirty edits always win until pushed; signal conflict if remote
      // is also newer so the UI can hint that a remote change was deferred.
      if (existing.isDirty) {
        if (remote.updatedAt.isAfter(existing.updatedAt)) {
          _hadConflict = true;
        }
        continue;
      }

      final remoteDelete =
          remote.deletedAt != null && existing.deletedAt == null;
      if (remote.updatedAt.isAfter(existing.updatedAt) || remoteDelete) {
        await _db.upsertNote(
          remote.copyWith(isDirty: false, remoteId: remote.id),
        );
      }
    }
  }

  Map<String, Object?> _folderToMap(NoteFolder folder) => {
    'name': folder.name,
    'sortIndex': folder.sortIndex,
    'isPinned': folder.isPinned,
    'createdAt': folder.createdAt.toIso8601String(),
    'updatedAt': folder.updatedAt.toIso8601String(),
  };

  NoteFolder _folderFromMap(String id, Map<String, dynamic> data) {
    return NoteFolder(
      id: id,
      name: data['name'] as String? ?? 'Folder',
      sortIndex: (data['sortIndex'] as num?)?.toInt() ?? 0,
      isPinned: data['isPinned'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      updatedAt:
          DateTime.tryParse(data['updatedAt'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, Object?> _noteToMap(Note note) => {
    'title': note.title,
    'subtitle': note.subtitle,
    'bodyDelta': note.bodyDelta,
    'plainTextPreview': note.plainTextPreview,
    'imagePaths': note.imagePaths,
    'tags': note.tags,
    'isPinned': note.isPinned,
    'sortIndex': note.sortIndex,
    'createdAt': note.createdAt.toIso8601String(),
    'updatedAt': note.updatedAt.toIso8601String(),
    'deletedAt': note.deletedAt?.toIso8601String(),
    'folderId': note.folderId,
  };

  Note _noteFromMap(String id, Map<String, dynamic> data) {
    final paths =
        (data['imagePaths'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final tags =
        (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    return Note(
      id: id,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String?,
      bodyDelta: data['bodyDelta'] as String? ?? '[{"insert":"\\n"}]',
      plainTextPreview: data['plainTextPreview'] as String? ?? '',
      imagePaths: paths,
      tags: tags,
      isPinned: data['isPinned'] as bool? ?? false,
      sortIndex: (data['sortIndex'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      updatedAt:
          DateTime.tryParse(data['updatedAt'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      deletedAt: DateTime.tryParse(data['deletedAt'] as String? ?? '')?.toUtc(),
      isDirty: false,
      remoteId: id,
      folderId: data['folderId'] as String?,
    );
  }

  Future<void> dispose() async {
    await _status.close();
  }
}

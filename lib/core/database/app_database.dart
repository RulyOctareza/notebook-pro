import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:notebook_pro/features/gamification/data/local/tables/gamification_profile_table.dart';
import 'package:notebook_pro/features/gamification/data/local/tables/unlocked_achievements_table.dart';
import 'package:notebook_pro/features/gamification/domain/entities/gamification_profile.dart';
import 'package:notebook_pro/features/notes/data/local/tables/folders_table.dart';
import 'package:notebook_pro/features/notes/data/local/tables/notes_table.dart';
import 'package:notebook_pro/features/notes/domain/entities/note.dart';
import 'package:notebook_pro/features/notes/domain/entities/note_folder.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    NotesTable,
    FoldersTable,
    GamificationProfileTable,
    UnlockedAchievementsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(foldersTable);
        await m.addColumn(notesTable, notesTable.folderId);
      }
      if (from < 3) {
        await m.addColumn(foldersTable, foldersTable.isPinned);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'notebook_pro');
  }

  // ── Notes ──────────────────────────────────────────────

  Stream<List<Note>> watchActiveNotes({
    String? folderId,
    bool inboxOnly = false,
  }) {
    final query = select(notesTable)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);

    if (inboxOnly) {
      query.where((t) => t.folderId.isNull());
    } else if (folderId != null) {
      query.where((t) => t.folderId.equals(folderId));
    }

    return query.watch().map((rows) => rows.map(_noteFromRow).toList());
  }

  Future<Note?> getNoteById(String id) async {
    final row = await (select(
      notesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _noteFromRow(row);
  }

  Future<void> upsertNote(Note note) async {
    await into(notesTable).insertOnConflictUpdate(_noteToCompanion(note));
  }

  Future<void> softDeleteNote(String id) async {
    await (update(notesTable)..where((t) => t.id.equals(id))).write(
      NotesTableCompanion(
        deletedAt: Value(DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
        isDirty: const Value(true),
      ),
    );
  }

  Future<List<Note>> dirtyNotes() async {
    final rows = await (select(
      notesTable,
    )..where((t) => t.isDirty.equals(true))).get();
    return rows.map(_noteFromRow).toList();
  }

  Future<void> markNoteClean(String id, {String? remoteId}) async {
    await (update(notesTable)..where((t) => t.id.equals(id))).write(
      NotesTableCompanion(
        isDirty: const Value(false),
        remoteId: remoteId == null ? const Value.absent() : Value(remoteId),
      ),
    );
  }

  Future<List<NoteFolder>> allFolders() => watchFolders().first;

  Future<void> togglePinNote(String id) async {
    final note = await getNoteById(id);
    if (note == null) return;
    await upsertNote(
      note.copyWith(
        isPinned: !note.isPinned,
        updatedAt: DateTime.now().toUtc(),
        isDirty: true,
      ),
    );
  }

  Future<void> moveNoteToFolder(String noteId, String? folderId) async {
    final note = await getNoteById(noteId);
    if (note == null) return;
    // Rebuild explicitly so folderId can be cleared to null (inbox).
    await upsertNote(
      Note(
        id: note.id,
        title: note.title,
        subtitle: note.subtitle,
        bodyDelta: note.bodyDelta,
        plainTextPreview: note.plainTextPreview,
        imagePaths: note.imagePaths,
        isPinned: note.isPinned,
        sortIndex: note.sortIndex,
        createdAt: note.createdAt,
        updatedAt: DateTime.now().toUtc(),
        deletedAt: note.deletedAt,
        isDirty: true,
        remoteId: note.remoteId,
        folderId: folderId,
      ),
    );
  }

  /// Counts active notes keyed by folderId (`null` key = inbox).
  Stream<Map<String?, int>> watchNoteCountsByFolder() {
    return (select(notesTable)..where((t) => t.deletedAt.isNull())).watch().map(
      (rows) {
        final counts = <String?, int>{};
        for (final row in rows) {
          counts.update(row.folderId, (v) => v + 1, ifAbsent: () => 1);
        }
        return counts;
      },
    );
  }

  Note _noteFromRow(NotesTableData row) {
    final paths = (jsonDecode(row.imagePaths) as List<dynamic>).cast<String>();
    return Note(
      id: row.id,
      title: row.title,
      subtitle: row.subtitle,
      bodyDelta: row.bodyDelta,
      plainTextPreview: row.plainTextPreview,
      imagePaths: paths,
      isPinned: row.isPinned,
      sortIndex: row.sortIndex,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      isDirty: row.isDirty,
      remoteId: row.remoteId,
      folderId: row.folderId,
    );
  }

  NotesTableCompanion _noteToCompanion(Note note) {
    return NotesTableCompanion(
      id: Value(note.id),
      title: Value(note.title),
      subtitle: Value(note.subtitle),
      bodyDelta: Value(note.bodyDelta),
      plainTextPreview: Value(note.plainTextPreview),
      imagePaths: Value(jsonEncode(note.imagePaths)),
      isPinned: Value(note.isPinned),
      sortIndex: Value(note.sortIndex),
      createdAt: Value(note.createdAt),
      updatedAt: Value(note.updatedAt),
      deletedAt: Value(note.deletedAt),
      isDirty: Value(note.isDirty),
      remoteId: Value(note.remoteId),
      folderId: Value(note.folderId),
    );
  }

  // ── Folders ────────────────────────────────────────────

  Stream<List<NoteFolder>> watchFolders() {
    final query = select(foldersTable)
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.isPinned,
          mode: OrderingMode.desc,
        ),
        (t) => OrderingTerm(expression: t.sortIndex),
        (t) => OrderingTerm(expression: t.name),
      ]);
    return query.watch().map((rows) => rows.map(_folderFromRow).toList());
  }

  Future<void> upsertFolder(NoteFolder folder) async {
    await into(foldersTable).insertOnConflictUpdate(
      FoldersTableCompanion(
        id: Value(folder.id),
        name: Value(folder.name),
        sortIndex: Value(folder.sortIndex),
        isPinned: Value(folder.isPinned),
        createdAt: Value(folder.createdAt),
        updatedAt: Value(folder.updatedAt),
      ),
    );
  }

  Future<void> togglePinFolder(String id) async {
    final folders = await watchFolders().first;
    final existing = folders.where((f) => f.id == id).firstOrNull;
    if (existing == null) return;
    await upsertFolder(
      existing.copyWith(
        isPinned: !existing.isPinned,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> deleteFolder(String id) async {
    // Move notes in this folder back to inbox before removing the folder.
    await (update(notesTable)..where((t) => t.folderId.equals(id))).write(
      NotesTableCompanion(
        folderId: const Value(null),
        updatedAt: Value(DateTime.now().toUtc()),
        isDirty: const Value(true),
      ),
    );
    await (delete(foldersTable)..where((t) => t.id.equals(id))).go();
  }

  NoteFolder _folderFromRow(FoldersTableData row) {
    return NoteFolder(
      id: row.id,
      name: row.name,
      sortIndex: row.sortIndex,
      isPinned: row.isPinned,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  // ── Gamification ───────────────────────────────────────

  static const int _profileId = 1;

  Future<void> ensureProfile() async {
    final existing = await (select(
      gamificationProfileTable,
    )..where((t) => t.id.equals(_profileId))).getSingleOrNull();
    if (existing == null) {
      await into(gamificationProfileTable).insert(
        GamificationProfileTableCompanion.insert(id: const Value(_profileId)),
      );
    }
  }

  Stream<GamificationProfile> watchProfile() {
    return (select(gamificationProfileTable)
          ..where((t) => t.id.equals(_profileId)))
        .watchSingle()
        .map(_profileFromRow);
  }

  Future<GamificationProfile> getProfile() async {
    await ensureProfile();
    final row = await (select(
      gamificationProfileTable,
    )..where((t) => t.id.equals(_profileId))).getSingle();
    return _profileFromRow(row);
  }

  Future<void> saveProfile(GamificationProfile profile) async {
    await into(gamificationProfileTable).insertOnConflictUpdate(
      GamificationProfileTableCompanion(
        id: const Value(_profileId),
        currentStreak: Value(profile.currentStreak),
        longestStreak: Value(profile.longestStreak),
        lastActiveDate: Value(profile.lastActiveDate),
        totalNotesCreated: Value(profile.totalNotesCreated),
        totalWordsWritten: Value(profile.totalWordsWritten),
        recentActiveDatesJson: Value(
          jsonEncode(
            profile.recentActiveDates.map((d) => d.toIso8601String()).toList(),
          ),
        ),
      ),
    );
  }

  Stream<Set<String>> watchUnlockedIds() {
    return select(
      unlockedAchievementsTable,
    ).watch().map((rows) => rows.map((r) => r.achievementId).toSet());
  }

  Future<Set<String>> getUnlockedIds() async {
    final rows = await select(unlockedAchievementsTable).get();
    return rows.map((r) => r.achievementId).toSet();
  }

  Future<void> unlockAchievements(Iterable<String> ids) async {
    final now = DateTime.now().toUtc();
    for (final id in ids) {
      await into(unlockedAchievementsTable).insertOnConflictUpdate(
        UnlockedAchievementsTableCompanion.insert(
          achievementId: id,
          unlockedAt: now,
        ),
      );
    }
  }

  GamificationProfile _profileFromRow(GamificationProfileTableData row) {
    final dates = (jsonDecode(row.recentActiveDatesJson) as List<dynamic>)
        .map((e) => DateTime.parse(e as String))
        .toList();
    return GamificationProfile(
      currentStreak: row.currentStreak,
      longestStreak: row.longestStreak,
      lastActiveDate: row.lastActiveDate,
      totalNotesCreated: row.totalNotesCreated,
      totalWordsWritten: row.totalWordsWritten,
      recentActiveDates: dates,
    );
  }
}

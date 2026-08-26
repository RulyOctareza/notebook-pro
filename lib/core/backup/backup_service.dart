import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:notebook_pro/core/database/app_database.dart';
import 'package:notebook_pro/features/gamification/domain/entities/gamification_profile.dart';
import 'package:notebook_pro/features/notes/domain/entities/note.dart';
import 'package:notebook_pro/features/notes/domain/entities/note_folder.dart';

/// Local JSON backup / restore of notes, folders, and gamification profile.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  Future<String?> exportBackup() async {
    final notes = await _db.allNotesIncludingDeleted();
    final folders = await _db.allFolders();
    final profile = await _db.getProfile();
    final unlocked = await _db.getUnlockedIds();

    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'folders': [
        for (final f in folders)
          {
            'id': f.id,
            'name': f.name,
            'sortIndex': f.sortIndex,
            'isPinned': f.isPinned,
            'createdAt': f.createdAt.toIso8601String(),
            'updatedAt': f.updatedAt.toIso8601String(),
          },
      ],
      'notes': [
        for (final n in notes)
          {
            'id': n.id,
            'title': n.title,
            'subtitle': n.subtitle,
            'bodyDelta': n.bodyDelta,
            'plainTextPreview': n.plainTextPreview,
            'imagePaths': n.imagePaths,
            'tags': n.tags,
            'isPinned': n.isPinned,
            'sortIndex': n.sortIndex,
            'createdAt': n.createdAt.toIso8601String(),
            'updatedAt': n.updatedAt.toIso8601String(),
            'deletedAt': n.deletedAt?.toIso8601String(),
            'folderId': n.folderId,
          },
      ],
      'gamification': {
        'currentStreak': profile.currentStreak,
        'longestStreak': profile.longestStreak,
        'lastActiveDate': profile.lastActiveDate?.toIso8601String(),
        'totalNotesCreated': profile.totalNotesCreated,
        'totalWordsWritten': profile.totalWordsWritten,
        'recentActiveDates': profile.recentActiveDates
            .map((d) => d.toIso8601String())
            .toList(),
        'weeklyWordsGoal': profile.weeklyWordsGoal,
        'weeklyWordsWritten': profile.weeklyWordsWritten,
        'weekStartDate': profile.weekStartDate?.toIso8601String(),
        'unlockedAchievements': unlocked.toList(),
      },
    };

    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final location = await getSaveLocation(
      suggestedName: 'notebook-pro-backup-$stamp.json',
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'JSON',
          extensions: ['json'],
          mimeTypes: ['application/json'],
        ),
      ],
    );
    if (location == null) return null;

    await File(location.path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return location.path;
  }

  Future<int> importBackup() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'JSON',
          extensions: ['json'],
          mimeTypes: ['application/json'],
        ),
      ],
    );
    if (file == null) return 0;

    final raw = await File(file.path).readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    var imported = 0;

    final folders = (data['folders'] as List<dynamic>? ?? const []);
    for (final item in folders) {
      final map = item as Map<String, dynamic>;
      await _db.upsertFolder(
        NoteFolder(
          id: map['id'] as String,
          name: map['name'] as String? ?? 'Folder',
          sortIndex: (map['sortIndex'] as num?)?.toInt() ?? 0,
          isPinned: map['isPinned'] as bool? ?? false,
          createdAt:
              DateTime.tryParse(map['createdAt'] as String? ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
          updatedAt:
              DateTime.tryParse(map['updatedAt'] as String? ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
        ),
      );
    }

    final notes = (data['notes'] as List<dynamic>? ?? const []);
    for (final item in notes) {
      final map = item as Map<String, dynamic>;
      final paths =
          (map['imagePaths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final tags =
          (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const <String>[];
      await _db.upsertNote(
        Note(
          id: map['id'] as String,
          title: map['title'] as String? ?? '',
          subtitle: map['subtitle'] as String?,
          bodyDelta: map['bodyDelta'] as String? ?? '[{"insert":"\\n"}]',
          plainTextPreview: map['plainTextPreview'] as String? ?? '',
          imagePaths: paths,
          tags: tags,
          isPinned: map['isPinned'] as bool? ?? false,
          sortIndex: (map['sortIndex'] as num?)?.toInt() ?? 0,
          createdAt:
              DateTime.tryParse(map['createdAt'] as String? ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
          updatedAt:
              DateTime.tryParse(map['updatedAt'] as String? ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
          deletedAt: DateTime.tryParse(
            map['deletedAt'] as String? ?? '',
          )?.toUtc(),
          isDirty: true,
          folderId: map['folderId'] as String?,
        ),
      );
      imported++;
    }

    final g = data['gamification'] as Map<String, dynamic>?;
    if (g != null) {
      final recent =
          (g['recentActiveDates'] as List<dynamic>? ?? const [])
              .map((e) => DateTime.parse(e as String))
              .toList();
      await _db.saveProfile(
        GamificationProfile(
          currentStreak: (g['currentStreak'] as num?)?.toInt() ?? 0,
          longestStreak: (g['longestStreak'] as num?)?.toInt() ?? 0,
          lastActiveDate: DateTime.tryParse(
            g['lastActiveDate'] as String? ?? '',
          ),
          totalNotesCreated: (g['totalNotesCreated'] as num?)?.toInt() ?? 0,
          totalWordsWritten: (g['totalWordsWritten'] as num?)?.toInt() ?? 0,
          recentActiveDates: recent,
          weeklyWordsGoal: (g['weeklyWordsGoal'] as num?)?.toInt() ?? 500,
          weeklyWordsWritten: (g['weeklyWordsWritten'] as num?)?.toInt() ?? 0,
          weekStartDate: DateTime.tryParse(g['weekStartDate'] as String? ?? ''),
        ),
      );
      final unlocked =
          (g['unlockedAchievements'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList();
      if (unlocked.isNotEmpty) {
        await _db.unlockAchievements(unlocked);
      }
    }

    return imported;
  }

  /// Copies image assets directory path for docs (informational).
  static Future<String> imagesDirectoryPath() async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'notebook_pro', 'images');
  }
}

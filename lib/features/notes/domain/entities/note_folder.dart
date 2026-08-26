import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_folder.freezed.dart';

@freezed
class NoteFolder with _$NoteFolder {
  const factory NoteFolder({
    required String id,
    required String name,
    @Default(0) int sortIndex,
    @Default(false) bool isPinned,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _NoteFolder;
}

/// Sentinel used by UI selection for the unfiled inbox (notes with null folderId).
const kInboxFolderId = '';

/// Sentinel used by UI selection for soft-deleted notes.
const kTrashFolderId = '__trash__';

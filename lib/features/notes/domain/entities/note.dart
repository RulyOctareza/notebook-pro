import 'package:freezed_annotation/freezed_annotation.dart';

part 'note.freezed.dart';

@freezed
class Note with _$Note {
  const factory Note({
    required String id,
    required String title,
    String? subtitle,
    required String bodyDelta,
    required String plainTextPreview,
    @Default(<String>[]) List<String> imagePaths,
    @Default(false) bool isPinned,
    @Default(0) int sortIndex,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    @Default(true) bool isDirty,
    String? remoteId,
    String? folderId,
  }) = _Note;
}

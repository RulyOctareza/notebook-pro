// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Note {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get subtitle => throw _privateConstructorUsedError;
  String get bodyDelta => throw _privateConstructorUsedError;
  String get plainTextPreview => throw _privateConstructorUsedError;
  List<String> get imagePaths => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  bool get isPinned => throw _privateConstructorUsedError;
  int get sortIndex => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  bool get isDirty => throw _privateConstructorUsedError;
  String? get remoteId => throw _privateConstructorUsedError;
  String? get folderId => throw _privateConstructorUsedError;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NoteCopyWith<Note> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteCopyWith<$Res> {
  factory $NoteCopyWith(Note value, $Res Function(Note) then) =
      _$NoteCopyWithImpl<$Res, Note>;
  @useResult
  $Res call({
    String id,
    String title,
    String? subtitle,
    String bodyDelta,
    String plainTextPreview,
    List<String> imagePaths,
    List<String> tags,
    bool isPinned,
    int sortIndex,
    DateTime createdAt,
    DateTime updatedAt,
    DateTime? deletedAt,
    bool isDirty,
    String? remoteId,
    String? folderId,
  });
}

/// @nodoc
class _$NoteCopyWithImpl<$Res, $Val extends Note>
    implements $NoteCopyWith<$Res> {
  _$NoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? subtitle = freezed,
    Object? bodyDelta = null,
    Object? plainTextPreview = null,
    Object? imagePaths = null,
    Object? tags = null,
    Object? isPinned = null,
    Object? sortIndex = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deletedAt = freezed,
    Object? isDirty = null,
    Object? remoteId = freezed,
    Object? folderId = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            subtitle: freezed == subtitle
                ? _value.subtitle
                : subtitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            bodyDelta: null == bodyDelta
                ? _value.bodyDelta
                : bodyDelta // ignore: cast_nullable_to_non_nullable
                      as String,
            plainTextPreview: null == plainTextPreview
                ? _value.plainTextPreview
                : plainTextPreview // ignore: cast_nullable_to_non_nullable
                      as String,
            imagePaths: null == imagePaths
                ? _value.imagePaths
                : imagePaths // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isPinned: null == isPinned
                ? _value.isPinned
                : isPinned // ignore: cast_nullable_to_non_nullable
                      as bool,
            sortIndex: null == sortIndex
                ? _value.sortIndex
                : sortIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            deletedAt: freezed == deletedAt
                ? _value.deletedAt
                : deletedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isDirty: null == isDirty
                ? _value.isDirty
                : isDirty // ignore: cast_nullable_to_non_nullable
                      as bool,
            remoteId: freezed == remoteId
                ? _value.remoteId
                : remoteId // ignore: cast_nullable_to_non_nullable
                      as String?,
            folderId: freezed == folderId
                ? _value.folderId
                : folderId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NoteImplCopyWith<$Res> implements $NoteCopyWith<$Res> {
  factory _$$NoteImplCopyWith(
    _$NoteImpl value,
    $Res Function(_$NoteImpl) then,
  ) = __$$NoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String? subtitle,
    String bodyDelta,
    String plainTextPreview,
    List<String> imagePaths,
    List<String> tags,
    bool isPinned,
    int sortIndex,
    DateTime createdAt,
    DateTime updatedAt,
    DateTime? deletedAt,
    bool isDirty,
    String? remoteId,
    String? folderId,
  });
}

/// @nodoc
class __$$NoteImplCopyWithImpl<$Res>
    extends _$NoteCopyWithImpl<$Res, _$NoteImpl>
    implements _$$NoteImplCopyWith<$Res> {
  __$$NoteImplCopyWithImpl(_$NoteImpl _value, $Res Function(_$NoteImpl) _then)
    : super(_value, _then);

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? subtitle = freezed,
    Object? bodyDelta = null,
    Object? plainTextPreview = null,
    Object? imagePaths = null,
    Object? tags = null,
    Object? isPinned = null,
    Object? sortIndex = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deletedAt = freezed,
    Object? isDirty = null,
    Object? remoteId = freezed,
    Object? folderId = freezed,
  }) {
    return _then(
      _$NoteImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        subtitle: freezed == subtitle
            ? _value.subtitle
            : subtitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        bodyDelta: null == bodyDelta
            ? _value.bodyDelta
            : bodyDelta // ignore: cast_nullable_to_non_nullable
                  as String,
        plainTextPreview: null == plainTextPreview
            ? _value.plainTextPreview
            : plainTextPreview // ignore: cast_nullable_to_non_nullable
                  as String,
        imagePaths: null == imagePaths
            ? _value._imagePaths
            : imagePaths // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isPinned: null == isPinned
            ? _value.isPinned
            : isPinned // ignore: cast_nullable_to_non_nullable
                  as bool,
        sortIndex: null == sortIndex
            ? _value.sortIndex
            : sortIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        deletedAt: freezed == deletedAt
            ? _value.deletedAt
            : deletedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isDirty: null == isDirty
            ? _value.isDirty
            : isDirty // ignore: cast_nullable_to_non_nullable
                  as bool,
        remoteId: freezed == remoteId
            ? _value.remoteId
            : remoteId // ignore: cast_nullable_to_non_nullable
                  as String?,
        folderId: freezed == folderId
            ? _value.folderId
            : folderId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$NoteImpl implements _Note {
  const _$NoteImpl({
    required this.id,
    required this.title,
    this.subtitle,
    required this.bodyDelta,
    required this.plainTextPreview,
    final List<String> imagePaths = const <String>[],
    final List<String> tags = const <String>[],
    this.isPinned = false,
    this.sortIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.isDirty = true,
    this.remoteId,
    this.folderId,
  }) : _imagePaths = imagePaths,
       _tags = tags;

  @override
  final String id;
  @override
  final String title;
  @override
  final String? subtitle;
  @override
  final String bodyDelta;
  @override
  final String plainTextPreview;
  final List<String> _imagePaths;
  @override
  @JsonKey()
  List<String> get imagePaths {
    if (_imagePaths is EqualUnmodifiableListView) return _imagePaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imagePaths);
  }

  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey()
  final bool isPinned;
  @override
  @JsonKey()
  final int sortIndex;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;
  @override
  @JsonKey()
  final bool isDirty;
  @override
  final String? remoteId;
  @override
  final String? folderId;

  @override
  String toString() {
    return 'Note(id: $id, title: $title, subtitle: $subtitle, bodyDelta: $bodyDelta, plainTextPreview: $plainTextPreview, imagePaths: $imagePaths, tags: $tags, isPinned: $isPinned, sortIndex: $sortIndex, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, isDirty: $isDirty, remoteId: $remoteId, folderId: $folderId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            (identical(other.bodyDelta, bodyDelta) ||
                other.bodyDelta == bodyDelta) &&
            (identical(other.plainTextPreview, plainTextPreview) ||
                other.plainTextPreview == plainTextPreview) &&
            const DeepCollectionEquality().equals(
              other._imagePaths,
              _imagePaths,
            ) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.isPinned, isPinned) ||
                other.isPinned == isPinned) &&
            (identical(other.sortIndex, sortIndex) ||
                other.sortIndex == sortIndex) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.isDirty, isDirty) || other.isDirty == isDirty) &&
            (identical(other.remoteId, remoteId) ||
                other.remoteId == remoteId) &&
            (identical(other.folderId, folderId) ||
                other.folderId == folderId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    subtitle,
    bodyDelta,
    plainTextPreview,
    const DeepCollectionEquality().hash(_imagePaths),
    const DeepCollectionEquality().hash(_tags),
    isPinned,
    sortIndex,
    createdAt,
    updatedAt,
    deletedAt,
    isDirty,
    remoteId,
    folderId,
  );

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteImplCopyWith<_$NoteImpl> get copyWith =>
      __$$NoteImplCopyWithImpl<_$NoteImpl>(this, _$identity);
}

abstract class _Note implements Note {
  const factory _Note({
    required final String id,
    required final String title,
    final String? subtitle,
    required final String bodyDelta,
    required final String plainTextPreview,
    final List<String> imagePaths,
    final List<String> tags,
    final bool isPinned,
    final int sortIndex,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final DateTime? deletedAt,
    final bool isDirty,
    final String? remoteId,
    final String? folderId,
  }) = _$NoteImpl;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get subtitle;
  @override
  String get bodyDelta;
  @override
  String get plainTextPreview;
  @override
  List<String> get imagePaths;
  @override
  List<String> get tags;
  @override
  bool get isPinned;
  @override
  int get sortIndex;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  DateTime? get deletedAt;
  @override
  bool get isDirty;
  @override
  String? get remoteId;
  @override
  String? get folderId;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoteImplCopyWith<_$NoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

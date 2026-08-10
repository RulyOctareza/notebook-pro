// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_folder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$NoteFolder {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get sortIndex => throw _privateConstructorUsedError;
  bool get isPinned => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of NoteFolder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NoteFolderCopyWith<NoteFolder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteFolderCopyWith<$Res> {
  factory $NoteFolderCopyWith(
    NoteFolder value,
    $Res Function(NoteFolder) then,
  ) = _$NoteFolderCopyWithImpl<$Res, NoteFolder>;
  @useResult
  $Res call({
    String id,
    String name,
    int sortIndex,
    bool isPinned,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$NoteFolderCopyWithImpl<$Res, $Val extends NoteFolder>
    implements $NoteFolderCopyWith<$Res> {
  _$NoteFolderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NoteFolder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? sortIndex = null,
    Object? isPinned = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            sortIndex: null == sortIndex
                ? _value.sortIndex
                : sortIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            isPinned: null == isPinned
                ? _value.isPinned
                : isPinned // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NoteFolderImplCopyWith<$Res>
    implements $NoteFolderCopyWith<$Res> {
  factory _$$NoteFolderImplCopyWith(
    _$NoteFolderImpl value,
    $Res Function(_$NoteFolderImpl) then,
  ) = __$$NoteFolderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    int sortIndex,
    bool isPinned,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$NoteFolderImplCopyWithImpl<$Res>
    extends _$NoteFolderCopyWithImpl<$Res, _$NoteFolderImpl>
    implements _$$NoteFolderImplCopyWith<$Res> {
  __$$NoteFolderImplCopyWithImpl(
    _$NoteFolderImpl _value,
    $Res Function(_$NoteFolderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteFolder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? sortIndex = null,
    Object? isPinned = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$NoteFolderImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        sortIndex: null == sortIndex
            ? _value.sortIndex
            : sortIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        isPinned: null == isPinned
            ? _value.isPinned
            : isPinned // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$NoteFolderImpl implements _NoteFolder {
  const _$NoteFolderImpl({
    required this.id,
    required this.name,
    this.sortIndex = 0,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final int sortIndex;
  @override
  @JsonKey()
  final bool isPinned;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'NoteFolder(id: $id, name: $name, sortIndex: $sortIndex, isPinned: $isPinned, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoteFolderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.sortIndex, sortIndex) ||
                other.sortIndex == sortIndex) &&
            (identical(other.isPinned, isPinned) ||
                other.isPinned == isPinned) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    sortIndex,
    isPinned,
    createdAt,
    updatedAt,
  );

  /// Create a copy of NoteFolder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteFolderImplCopyWith<_$NoteFolderImpl> get copyWith =>
      __$$NoteFolderImplCopyWithImpl<_$NoteFolderImpl>(this, _$identity);
}

abstract class _NoteFolder implements NoteFolder {
  const factory _NoteFolder({
    required final String id,
    required final String name,
    final int sortIndex,
    final bool isPinned,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$NoteFolderImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  int get sortIndex;
  @override
  bool get isPinned;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of NoteFolder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoteFolderImplCopyWith<_$NoteFolderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

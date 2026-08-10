import 'package:drift/drift.dart';

class NotesTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get subtitle => text().nullable()();
  TextColumn get bodyDelta => text()();
  TextColumn get plainTextPreview => text().withDefault(const Constant(''))();
  TextColumn get imagePaths => text().withDefault(const Constant('[]'))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  TextColumn get remoteId => text().nullable()();
  TextColumn get folderId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

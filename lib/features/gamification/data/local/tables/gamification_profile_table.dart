import 'package:drift/drift.dart';

/// Single-row profile table (id always = 1).
class GamificationProfileTable extends Table {
  IntColumn get id => integer()();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastActiveDate => dateTime().nullable()();
  IntColumn get totalNotesCreated => integer().withDefault(const Constant(0))();
  IntColumn get totalWordsWritten => integer().withDefault(const Constant(0))();
  TextColumn get recentActiveDatesJson =>
      text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

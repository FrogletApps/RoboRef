import 'package:drift/drift.dart';

class IncidentNotes extends Table {
  TextColumn get id => text()(); // UUID v4
  TextColumn get sku => text()();
  TextColumn get teamNumber => text()();
  TextColumn get matchId => text().nullable()();
  TextColumn get ruleCodesJson => text()(); // JSON list of string rule codes
  TextColumn get severity => text()(); // 'minor', 'major', 'warning', 'd_q'
  TextColumn get notes => text()();
  TextColumn get refereeName => text()();
  TextColumn get deviceId => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

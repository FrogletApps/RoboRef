import 'package:drift/drift.dart';

class Matches extends Table {
  TextColumn get matchId => text()();
  TextColumn get sku => text()();
  IntColumn get divisionId => integer()();
  TextColumn get name => text()();
  TextColumn get field => text().nullable()();
  TextColumn get scheduledTime => text().nullable()();
  TextColumn get redTeamsJson => text()();
  TextColumn get blueTeamsJson => text()();
  IntColumn get redScore => integer().nullable()();
  IntColumn get blueScore => integer().nullable()();

  @override
  Set<Column> get primaryKey => {matchId, sku};
}

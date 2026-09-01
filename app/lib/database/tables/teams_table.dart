import 'package:drift/drift.dart';

class Teams extends Table {
  TextColumn get teamNumber => text()();
  TextColumn get teamName => text()();
  TextColumn get sku => text()();
  TextColumn get organization => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get region => text().nullable()();
  TextColumn get country => text().nullable()();
  IntColumn get rank => integer().nullable()();

  @override
  Set<Column> get primaryKey => {teamNumber, sku};
}

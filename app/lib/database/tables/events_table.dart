import 'package:drift/drift.dart';

class Events extends Table {
  TextColumn get sku => text()();
  TextColumn get name => text()();
  TextColumn get program => text()();
  TextColumn get season => text()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {sku};
}

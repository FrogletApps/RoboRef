import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

DatabaseConnection connect() {
  return DatabaseConnection.delayed(Future.sync(() async {
    final db = await WasmDatabase.open(
      databaseName: 'roboref_db',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return db.resolvedExecutor;
  }));
}

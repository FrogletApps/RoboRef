import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

DatabaseConnection connect() {
  return DatabaseConnection.delayed(Future.sync(() async {
    try {
      final result = await WasmDatabase.open(
        databaseName: 'roboref_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
      return result.resolvedExecutor;
    } catch (e) {
      debugPrint('Drift WasmDatabase init error: $e');
      rethrow;
    }
  }));
}

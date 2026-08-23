import 'package:drift/drift.dart';
import 'unsupported.dart'
    if (dart.library.io) 'native.dart'
    if (dart.library.js_interop) 'web.dart' as impl;

DatabaseConnection connect() => impl.connect();

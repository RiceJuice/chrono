import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';

import 'powersync_schema.dart';
import 'database_path_stub.dart'
    if (dart.library.io) 'database_path.dart';

/// Injected in [main] via [ProviderScope.overrides]. Throws if used unconfigured.
final dbProvider = Provider<PowerSyncDatabase>((ref) {
  throw StateError(
    'dbProvider is not initialized. Override it in ProviderScope after '
    'initializeDatabase().',
  );
});

Future<PowerSyncDatabase> initializeDatabase() async {
  // Web: kein Dateisystem – PowerSync legt die DB im Browser-Speicher an.
  // Nativ: vorhandenen (ggf. älteren) Cache weiterverwenden, siehe database_path.dart.
  final path = kIsWeb
      ? resolveDatabasePath('')
      : resolveDatabasePath((await getApplicationDocumentsDirectory()).path);
  final db = PowerSyncDatabase(schema: powersyncSchema, path: path);
  await db.initialize();
  return db;
}

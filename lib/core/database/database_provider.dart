import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';

import 'powersync_schema.dart';
import 'database_path.dart';

/// Injected in [main] via [ProviderScope.overrides]. Throws if used unconfigured.
final dbProvider = Provider<PowerSyncDatabase>((ref) {
  throw StateError(
    'dbProvider is not initialized. Override it in ProviderScope after '
    'initializeDatabase().',
  );
});

Future<PowerSyncDatabase> initializeDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final path = resolveDatabasePath(dir.path);
  final db = PowerSyncDatabase(schema: powersyncSchema, path: path);
  await db.initialize();
  return db;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';

import 'powersync_schema.dart';

/// Injected in [main] via [ProviderScope.overrides]. Throws if used unconfigured.
final dbProvider = Provider<PowerSyncDatabase>((ref) {
  throw StateError(
    'dbProvider is not initialized. Override it in ProviderScope after '
    'initializeDatabase().',
  );
});

Future<PowerSyncDatabase> initializeDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  // v6: calendar_events updated (`class`, `image_paths`) + profiles + klassen.
  final path = p.join(dir.path, 'chrono_powersync_v6.db');
  final db = PowerSyncDatabase(schema: powersyncSchema, path: path);
  await db.initialize();
  return db;
}

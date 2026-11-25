import 'package:flutter/foundation.dart' show kIsWeb;
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
  // v16: homework_peer_dismissals für abgelehnte Klassen-Vorschläge.
  const fileName = 'chrono_powersync_v16.db';
  // Web: kein Dateisystem – PowerSync legt die DB im Browser-Speicher (OPFS/IndexedDB) an.
  final path = kIsWeb
      ? fileName
      : p.join((await getApplicationDocumentsDirectory()).path, fileName);
  final db = PowerSyncDatabase(schema: powersyncSchema, path: path);
  await db.initialize();
  return db;
}

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Schema changes are applied by PowerSync.initialize, so retain an existing
/// cache rather than starting empty after a database filename version change.
String resolveDatabasePath(String directory) {
  final current = p.join(directory, 'chrono_powersync_v16.db');
  if (_containsUserData(current)) return current;
  for (final version in [15, 14]) {
    final legacy = p.join(directory, 'chrono_powersync_v$version.db');
    if (_containsUserData(legacy)) return legacy;
  }
  return current;
}

bool _containsUserData(String path) {
  if (!File(path).existsSync()) return false;
  Database? db;
  try {
    db = sqlite3.open(path, mode: OpenMode.readOnly);
    final tables = db.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND (name GLOB 'ps_data__*' OR name = 'ps_crud')",
    );
    for (final table in tables) {
      final name = (table['name'] as String).replaceAll('"', '""');
      if (db.select('SELECT 1 FROM "$name" LIMIT 1').isNotEmpty) return true;
    }
    return false;
  } on SqliteException {
    // Do not switch away from an unreadable existing cache.
    return true;
  } finally {
    db?.close();
  }
}

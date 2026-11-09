import 'package:chronoapp/core/utils/class_name_order.dart';
import 'package:powersync/powersync.dart';
import 'package:sqlite3/common.dart';

import '../../../core/database/powersync_schema.dart';

class KlassenRepository {
  KlassenRepository(this._db, {this.loadRemoteClasses});

  final PowerSyncDatabase _db;
  final Future<List<String>> Function()? loadRemoteClasses;

  Stream<List<String>> watchClasses() {
    return _db
        .watch(
          '''
          SELECT class_name
          FROM $kKlassenTable
          WHERE class_name IS NOT NULL AND trim(class_name) != ''
          ORDER BY class_name COLLATE NOCASE ASC
          ''',
          triggerOnTables: const {kKlassenTable},
        )
        .map(_toClassNames)
        .asyncMap((local) async {
          if (local.isNotEmpty || loadRemoteClasses == null) return local;
          // A new account may reach onboarding before reference data has synced.
          final remote = await loadRemoteClasses!().timeout(
            const Duration(seconds: 12),
          );
          final classes = remote
              .map((name) => name.trim())
              .where((name) => name.isNotEmpty)
              .toSet()
              .toList();
          classes.sort(compareClassNames);
          return classes;
        });
  }

  List<String> _toClassNames(ResultSet rows) {
    final out = <String>[];
    final seen = <String>{};

    for (final row in rows) {
      final raw = row['class_name'];
      if (raw == null) continue;
      final className = raw.toString().trim();
      if (className.isEmpty || seen.contains(className)) continue;
      seen.add(className);
      out.add(className);
    }
    out.sort(compareClassNames);
    return out;
  }
}

import 'package:powersync/powersync.dart';
import 'package:sqlite3/common.dart';

import '../../../core/database/powersync_schema.dart';

class KlassenRepository {
  KlassenRepository(this._db);

  final PowerSyncDatabase _db;

  static final RegExp _numberPattern = RegExp(r'\d+');

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
        .map(_toClassNames);
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
    out.sort(_compareClassNames);
    return out;
  }

  int _compareClassNames(String a, String b) {
    final aMatch = _numberPattern.firstMatch(a);
    final bMatch = _numberPattern.firstMatch(b);

    if (aMatch != null && bMatch != null) {
      final aNumber = int.tryParse(aMatch.group(0)!);
      final bNumber = int.tryParse(bMatch.group(0)!);
      if (aNumber != null && bNumber != null && aNumber != bNumber) {
        return aNumber.compareTo(bNumber);
      }
    }

    return a.toLowerCase().compareTo(b.toLowerCase());
  }
}

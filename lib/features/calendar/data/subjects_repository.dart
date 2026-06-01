import 'package:powersync/powersync.dart';
import 'package:sqlite3/common.dart';

import '../../../core/database/powersync_schema.dart';
import '../domain/models/calendar_subject.dart';
import 'subject_color_codec.dart';

class SubjectsRepository {
  SubjectsRepository(this._db);

  final PowerSyncDatabase _db;

  Stream<List<CalendarSubject>> watchSubjects() {
    return _db
        .watch(
          '''
          SELECT id, name, default_color
          FROM $kSubjectsTable
          WHERE name IS NOT NULL AND trim(name) != ''
          ORDER BY name COLLATE NOCASE ASC
          ''',
          triggerOnTables: const {kSubjectsTable},
        )
        .map(_mapRows);
  }

  List<CalendarSubject> _mapRows(ResultSet rows) {
    final out = <CalendarSubject>[];
    final seen = <String>{};

    for (final row in rows) {
      final id = row['id']?.toString().trim();
      final name = row['name']?.toString().trim();
      if (id == null || id.isEmpty || name == null || name.isEmpty) continue;
      if (seen.contains(id)) continue;
      seen.add(id);

      final color = SubjectColorCodec.parseHex(row['default_color']);
      if (color == null) continue;

      out.add(CalendarSubject(id: id, name: name, defaultColor: color));
    }

    return out;
  }
}

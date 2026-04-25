import 'package:powersync/powersync.dart';
import 'package:sqlite3/common.dart';

import '../../../core/database/powersync_schema.dart';
import 'models/profile_snapshot.dart';

class SettingsProfileRepository {
  SettingsProfileRepository(this._db);

  final PowerSyncDatabase _db;

  Stream<ProfileSnapshot?> watchProfileByUserId(String userId) {
    return _db
        .watch(
          '''
          SELECT first_name, last_name, class_name, schooltrack, voice, role, choir, diet
          FROM $kProfilesTable
          WHERE id = ?
          LIMIT 1
          ''',
          parameters: [userId],
          triggerOnTables: const {kProfilesTable},
        )
        .map(_mapFirstRowOrNull);
  }

  ProfileSnapshot? _mapFirstRowOrNull(ResultSet rows) {
    if (rows.isEmpty) return null;
    final row = rows.first;
    return ProfileSnapshot(
      firstName: _asString(row['first_name']),
      lastName: _asString(row['last_name']),
      className: _asString(row['class_name']),
      schoolTrack: _asString(row['schooltrack']),
      voice: _asString(row['voice']),
      role: _asString(row['role']),
      choir: _asString(row['choir']),
      diet: _asString(row['diet']),
    );
  }

  String? _asString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

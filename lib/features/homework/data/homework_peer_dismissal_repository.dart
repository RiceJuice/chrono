import 'package:chronoapp/core/database/powersync_schema.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:powersync/powersync.dart';
import 'package:sqlite3/common.dart';

import 'homework_id_generator.dart';

class HomeworkPeerDismissalRepository {
  HomeworkPeerDismissalRepository(this._db);

  final PowerSyncDatabase _db;

  Stream<Set<String>> watchDismissalKeys({
    required String profileId,
    required DateTime lessonDate,
  }) {
    final date = formatLessonDate(lessonDate);
    return _db
        .watch(
          '''
          SELECT canonical_key, subject_id, lesson_date
          FROM $kHomeworkPeerDismissalsTable
          WHERE profile_id = ?
            AND lesson_date = ?
          ''',
          parameters: [profileId, date],
          triggerOnTables: const {kHomeworkPeerDismissalsTable},
        )
        .map(_mapDismissalKeys);
  }

  Future<void> dismissSuggestion({
    required String profileId,
    required String canonicalKey,
    required String subjectId,
    required DateTime lessonDate,
  }) async {
    final id = generateHomeworkId();
    final now = DateTime.now().toUtc().toIso8601String();
    final date = formatLessonDate(lessonDate);

    await _db.writeTransaction((tx) async {
      await tx.execute(
        '''
        INSERT OR IGNORE INTO $kHomeworkPeerDismissalsTable
          (id, profile_id, canonical_key, subject_id, lesson_date, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [id, profileId, canonicalKey, subjectId, date, now],
      );
    });
  }

  Set<String> _mapDismissalKeys(ResultSet rows) {
    return rows
        .map((row) {
          final canonicalKey = row['canonical_key'] as String? ?? '';
          final subjectId = row['subject_id'] as String? ?? '';
          final lessonDate = row['lesson_date'] as String? ?? '';
          return '$canonicalKey|$subjectId|$lessonDate';
        })
        .toSet();
  }
}

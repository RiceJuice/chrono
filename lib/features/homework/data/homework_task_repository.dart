import 'package:chronoapp/core/database/powersync_schema.dart';
import 'package:chronoapp/features/homework/domain/models/homework_fragment.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:powersync/powersync.dart';
import 'package:sqlite3/common.dart';
import 'package:chronoapp/features/homework/data/homework_id_generator.dart';

class HomeworkTaskRepository {
  HomeworkTaskRepository(this._db);

  final PowerSyncDatabase _db;

  Stream<List<HomeworkTask>> watchTasks(String profileId) {
    return _db
        .watch(
          '''
          SELECT *
          FROM $kHomeworkTasksTable
          WHERE profile_id = ?
          ORDER BY is_completed ASC, due_at ASC, created_at DESC
          ''',
          parameters: [profileId],
          triggerOnTables: const {kHomeworkTasksTable},
        )
        .map(_mapTasks);
  }

  Future<int> countTasks(String profileId) async {
    final rows = await _db.getAll(
      'SELECT COUNT(*) AS c FROM $kHomeworkTasksTable WHERE profile_id = ?',
      [profileId],
    );
    if (rows.isEmpty) return 0;
    return rows.first['c'] as int? ?? 0;
  }

  Future<void> insertTask({
    required String profileId,
    required String title,
    required List<HomeworkFragment> fragments,
    String? description,
    String? subjectId,
    DateTime? dueAt,
    HomeworkDueSource? dueSource,
    String? contributionId,
  }) async {
    final id = generateHomeworkId();
    final now = DateTime.now().toUtc().toIso8601String();
    final fragmentsJson = encodeFragmentsJson(fragments);
    final trimmedDescription = description?.trim();

    await _db.writeTransaction((tx) async {
      await tx.execute(
        '''
        INSERT INTO $kHomeworkTasksTable
          (id, profile_id, title, fragments, plain_text, subject_id,
           is_completed, due_at, due_source, contribution_id, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          id,
          profileId,
          title.trim(),
          fragmentsJson,
          trimmedDescription == null || trimmedDescription.isEmpty
              ? null
              : trimmedDescription,
          subjectId,
          0,
          dueAt?.toUtc().toIso8601String(),
          dueSource == null ? null : homeworkDueSourceToJson(dueSource),
          contributionId,
          now,
          now,
        ],
      );
    });
  }

  Future<void> toggleCompleted({
    required String taskId,
    required bool isCompleted,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.writeTransaction((tx) async {
      await tx.execute(
        '''
        UPDATE $kHomeworkTasksTable
        SET is_completed = ?, completed_at = ?, updated_at = ?
        WHERE id = ?
        ''',
        [
          isCompleted ? 1 : 0,
          isCompleted ? now : null,
          now,
          taskId,
        ],
      );
    });
  }

  List<HomeworkTask> _mapTasks(ResultSet rows) {
    final tasks = rows.map((row) => HomeworkTask.fromRow(row)).toList();
    return sortHomeworkTasks(tasks);
  }
}

import 'package:chronoapp/core/database/powersync_schema.dart';
import 'package:chronoapp/features/homework/domain/homework_fragment_merge.dart';
import 'package:chronoapp/features/homework/domain/models/homework_contribution.dart';
import 'package:chronoapp/features/homework/domain/models/homework_fragment.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:powersync/powersync.dart';
import 'package:sqlite3/common.dart';
import 'dart:convert';

import 'package:chronoapp/features/homework/data/homework_id_generator.dart';

class HomeworkContributionRepository {
  HomeworkContributionRepository(this._db);

  final PowerSyncDatabase _db;

  Stream<List<HomeworkContribution>> watchClassContributions({
    required String className,
    String? schooltrack,
    required DateTime lessonDate,
  }) {
    final date = formatLessonDate(lessonDate);
    final params = schooltrack == null || schooltrack.isEmpty
        ? [className, date]
        : [className, schooltrack, date];

    final query = schooltrack == null || schooltrack.isEmpty
        ? '''
          SELECT *
          FROM $kHomeworkContributionsTable
          WHERE class_name = ?
            AND lesson_date = ?
          ORDER BY updated_at DESC
          '''
        : '''
          SELECT *
          FROM $kHomeworkContributionsTable
          WHERE class_name = ?
            AND schooltrack = ?
            AND lesson_date = ?
          ORDER BY updated_at DESC
          ''';

    return _db
        .watch(
          query,
          parameters: params,
          triggerOnTables: const {kHomeworkContributionsTable},
        )
        .map(_mapContributions);
  }

  Future<HomeworkContribution?> findOwnContribution({
    required String profileId,
    required String className,
    String? schooltrack,
    required String subjectId,
    required DateTime lessonDate,
  }) async {
    final date = formatLessonDate(lessonDate);
    final rows = schooltrack == null || schooltrack.isEmpty
        ? await _db.getAll(
            '''
            SELECT *
            FROM $kHomeworkContributionsTable
            WHERE profile_id = ?
              AND class_name = ?
              AND subject_id = ?
              AND lesson_date = ?
            LIMIT 1
            ''',
            [profileId, className, subjectId, date],
          )
        : await _db.getAll(
            '''
            SELECT *
            FROM $kHomeworkContributionsTable
            WHERE profile_id = ?
              AND class_name = ?
              AND schooltrack = ?
              AND subject_id = ?
              AND lesson_date = ?
            LIMIT 1
            ''',
            [profileId, className, schooltrack, subjectId, date],
          );

    if (rows.isEmpty) return null;
    return HomeworkContribution.fromRow(rows.first);
  }

  Future<String> upsertContribution({
    required String profileId,
    required String className,
    String? schooltrack,
    required String subjectId,
    required DateTime lessonDate,
    required List<HomeworkFragment> localFragments,
    required List<HomeworkContribution> classContributions,
  }) async {
    final existing = await findOwnContribution(
      profileId: profileId,
      className: className,
      schooltrack: schooltrack,
      subjectId: subjectId,
      lessonDate: lessonDate,
    );

    final delta = computeDeltaToUpload(
      localFragments: localFragments,
      classContributions: classContributions,
      profileId: profileId,
    );

    if (delta.isEmpty && existing != null) return existing.id;

    final merged = mergeOwnContributionFragments(
      existingOwn: existing?.fragments,
      delta: delta.isEmpty ? localFragments : delta,
    );

    final hashes = fragmentHashesFor(merged);
    final now = DateTime.now().toUtc().toIso8601String();
    final date = formatLessonDate(lessonDate);
    final id = existing?.id ??
        homeworkContributionId(
          profileId: profileId,
          className: className,
          schooltrack: schooltrack,
          subjectId: subjectId,
          lessonDate: lessonDate,
        );
    final fragmentsJson = encodeFragmentsJson(merged);
    final hashesJson = jsonEncode(hashes);
    var resultId = id;

    await _db.writeTransaction((tx) async {
      if (existing == null) {
        final conflicting = await _findRowByNaturalKey(
          tx: tx,
          profileId: profileId,
          className: className,
          schooltrack: schooltrack,
          subjectId: subjectId,
          lessonDate: date,
        );

        if (conflicting != null) {
          final conflictingId = conflicting['id'] as String;
          await tx.execute(
            '''
            UPDATE $kHomeworkContributionsTable
            SET fragments = ?, fragment_hashes = ?, updated_at = ?
            WHERE id = ?
            ''',
            [fragmentsJson, hashesJson, now, conflictingId],
          );
          resultId = conflictingId;
          return;
        }

        await tx.execute(
          '''
          INSERT INTO $kHomeworkContributionsTable
            (id, profile_id, class_name, schooltrack, subject_id, lesson_date,
             fragments, fragment_hashes, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            fragments = excluded.fragments,
            fragment_hashes = excluded.fragment_hashes,
            updated_at = excluded.updated_at
          ''',
          [
            id,
            profileId,
            className,
            schooltrack,
            subjectId,
            date,
            fragmentsJson,
            hashesJson,
            now,
            now,
          ],
        );
      } else {
        await tx.execute(
          '''
          UPDATE $kHomeworkContributionsTable
          SET fragments = ?, fragment_hashes = ?, updated_at = ?
          WHERE id = ?
          ''',
          [fragmentsJson, hashesJson, now, id],
        );
      }
    });

    return resultId;
  }

  Future<Map<String, Object?>?> _findRowByNaturalKey({
    required dynamic tx,
    required String profileId,
    required String className,
    String? schooltrack,
    required String subjectId,
    required String lessonDate,
  }) async {
    final rows = schooltrack == null || schooltrack.isEmpty
        ? await tx.getAll(
            '''
            SELECT id
            FROM $kHomeworkContributionsTable
            WHERE profile_id = ?
              AND class_name = ?
              AND subject_id = ?
              AND lesson_date = ?
              AND (schooltrack IS NULL OR schooltrack = '')
            LIMIT 1
            ''',
            [profileId, className, subjectId, lessonDate],
          )
        : await tx.getAll(
            '''
            SELECT id
            FROM $kHomeworkContributionsTable
            WHERE profile_id = ?
              AND class_name = ?
              AND schooltrack = ?
              AND subject_id = ?
              AND lesson_date = ?
            LIMIT 1
            ''',
            [profileId, className, schooltrack, subjectId, lessonDate],
          );

    if (rows.isEmpty) return null;
    return rows.first;
  }

  List<HomeworkContribution> _mapContributions(ResultSet rows) {
    return rows
        .map((row) => HomeworkContribution.fromRow(row))
        .toList(growable: false);
  }
}

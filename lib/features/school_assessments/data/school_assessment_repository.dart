import 'package:chronoapp/core/database/powersync_schema.dart';
import 'package:chronoapp/features/school_assessments/data/school_assessment_id_generator.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment_kind.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment_schedule_source.dart';
import 'package:powersync/powersync.dart';

class SchoolAssessmentRepository {
  SchoolAssessmentRepository(this._db);

  final PowerSyncDatabase _db;

  Stream<List<SchoolAssessment>> watchAssessments(String profileId) {
    return _db
        .watch(
          '''
          SELECT *
          FROM $kSchoolAssessmentsTable
          WHERE profile_id = ?
          ORDER BY scheduled_at ASC, created_at DESC
          ''',
          parameters: [profileId],
          triggerOnTables: const {kSchoolAssessmentsTable},
        )
        .map(_mapAssessments);
  }

  Future<void> insertAssessment({
    required String profileId,
    required SchoolAssessmentKind kind,
    required String subjectId,
    required DateTime scheduledAt,
    required SchoolAssessmentScheduleSource scheduleSource,
  }) async {
    final id = generateSchoolAssessmentId();
    final now = DateTime.now().toUtc().toIso8601String();

    await _db.writeTransaction((tx) async {
      await tx.execute(
        '''
        INSERT INTO $kSchoolAssessmentsTable
          (id, profile_id, kind, subject_id, scheduled_at, schedule_source,
           created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          id,
          profileId,
          schoolAssessmentKindToJson(kind),
          subjectId,
          scheduledAt.toUtc().toIso8601String(),
          schoolAssessmentScheduleSourceToJson(scheduleSource),
          now,
          now,
        ],
      );
    });
  }

  List<SchoolAssessment> _mapAssessments(List<Map<String, Object?>> rows) {
    return rows
        .map((row) => SchoolAssessment.fromRow(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }
}

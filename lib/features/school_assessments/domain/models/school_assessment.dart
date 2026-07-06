import 'package:chronoapp/features/school_assessments/domain/models/school_assessment_kind.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment_schedule_source.dart';

class SchoolAssessment {
  const SchoolAssessment({
    required this.id,
    required this.profileId,
    required this.kind,
    required this.subjectId,
    required this.scheduledAt,
    required this.scheduleSource,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String profileId;
  final SchoolAssessmentKind kind;
  final String subjectId;
  final DateTime scheduledAt;
  final SchoolAssessmentScheduleSource scheduleSource;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory SchoolAssessment.fromRow(Map<String, dynamic> row) {
    final kind = schoolAssessmentKindFromJson(row['kind'] as String?);
    final scheduleSource = schoolAssessmentScheduleSourceFromJson(
      row['schedule_source'] as String?,
    );
    if (kind == null || scheduleSource == null) {
      throw FormatException('Invalid school_assessment row: ${row['id']}');
    }

    return SchoolAssessment(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      kind: kind,
      subjectId: row['subject_id'] as String,
      scheduledAt: DateTime.parse(row['scheduled_at'] as String).toLocal(),
      scheduleSource: scheduleSource,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.parse(row['updated_at'] as String).toLocal(),
    );
  }
}

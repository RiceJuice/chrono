import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment.dart';

String schoolAssessmentLessonLookupKey({
  required String subjectId,
  required DateTime lessonStart,
}) {
  final normalizedSubjectId = subjectId.trim();
  return '$normalizedSubjectId|${lessonStart.toUtc().millisecondsSinceEpoch}';
}

String? schoolAssessmentLessonLookupKeyForEntry(CalendarEntry entry) {
  if (entry.type != CalendarEntryType.lesson) return null;
  final subjectId = entry.subjectId?.trim();
  if (subjectId == null || subjectId.isEmpty) return null;
  return schoolAssessmentLessonLookupKey(
    subjectId: subjectId,
    lessonStart: entry.startTime,
  );
}

bool isSchoolAssessmentForLesson({
  required SchoolAssessment assessment,
  required CalendarEntry lesson,
}) {
  if (lesson.type != CalendarEntryType.lesson) return false;

  final lessonSubjectId = lesson.subjectId?.trim();
  final assessmentSubjectId = assessment.subjectId.trim();
  if (lessonSubjectId == null ||
      lessonSubjectId.isEmpty ||
      assessmentSubjectId.isEmpty ||
      lessonSubjectId != assessmentSubjectId) {
    return false;
  }

  return assessment.scheduledAt.toUtc().millisecondsSinceEpoch ==
      lesson.startTime.toUtc().millisecondsSinceEpoch;
}

Map<String, SchoolAssessment> indexSchoolAssessmentsByLessonKey(
  Iterable<SchoolAssessment> assessments,
) {
  final index = <String, SchoolAssessment>{};
  for (final assessment in assessments) {
    final key = schoolAssessmentLessonLookupKey(
      subjectId: assessment.subjectId,
      lessonStart: assessment.scheduledAt,
    );
    index[key] = assessment;
  }
  return index;
}

Map<String, SchoolAssessment> indexSchoolAssessmentPreviewsByLessonKey({
  required Iterable<SchoolAssessment> assessments,
  required List<CalendarEntry> lessons,
}) {
  final index = <String, SchoolAssessment>{};
  for (final assessment in assessments) {
    final previewLesson = findPreviewLessonForAssessment(
      assessment: assessment,
      lessons: lessons,
    );
    if (previewLesson == null) continue;
    final key = schoolAssessmentLessonLookupKeyForEntry(previewLesson);
    if (key == null) continue;
    index[key] = assessment;
  }
  return index;
}

CalendarEntry? findPreviewLessonForAssessment({
  required SchoolAssessment assessment,
  required List<CalendarEntry> lessons,
}) {
  final subjectId = assessment.subjectId.trim();
  if (subjectId.isEmpty) return null;

  final scheduledAt = assessment.scheduledAt.toUtc();
  final previewAnchor = scheduledAt.subtract(const Duration(days: 7));

  CalendarEntry? best;
  var bestDistance = double.infinity;

  for (final lesson in lessons) {
    if (lesson.type != CalendarEntryType.lesson) continue;
    if (lesson.subjectId?.trim() != subjectId) continue;

    final lessonStart = lesson.startTime.toUtc();
    if (!lessonStart.isBefore(scheduledAt)) continue;

    final distance = (lessonStart.millisecondsSinceEpoch -
            previewAnchor.millisecondsSinceEpoch)
        .abs()
        .toDouble();
    if (distance < bestDistance) {
      bestDistance = distance;
      best = lesson;
    }
  }

  return best;
}

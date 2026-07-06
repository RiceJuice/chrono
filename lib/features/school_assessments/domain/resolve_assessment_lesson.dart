import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/school_assessments/domain/upcoming_lessons_for_subject.dart';

CalendarEntry? resolveAssessmentLessonForCustomDate({
  required List<CalendarEntry> entries,
  required String subjectId,
  required DateTime day,
}) {
  return lessonForSubjectOnLocalDay(
    entries: entries,
    subjectId: subjectId,
    day: day,
  );
}

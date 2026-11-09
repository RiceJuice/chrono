import '../../../../core/database/arts_subject.dart';
import '../../../../core/database/school_subject_choices.dart';
import '../../../../core/database/backend_enums.dart';
import '../models/calendar_entry.dart';
import 'calendar_filters_state.dart';

String _normalized(String? value) => (value ?? '').trim().toLowerCase();

bool _personalLesson(CalendarEntry entry, CalendarFiltersState filters) =>
    entry.type == CalendarEntryType.lesson &&
    filters.defaultClassNames.length == 1 &&
    filters.defaultSchoolTracks.length == 1 &&
    _normalized(entry.className) == filters.defaultClassNames.single;

String? _choice(CalendarEntry entry, CalendarFiltersState filters, bool arts) =>
    savedSchoolSubjectChoice(
      options: arts ? artsSubjectOptions : languageSubjectOptions,
      legacy: arts ? filters.artsSubject : filters.languageSubject,
      choices: filters.timetableChoices,
      className: filters.defaultClassNames.single,
      schoolTrack: filters.defaultSchoolTracks.single,
      at: entry.startTime,
    );

/// Mirrors Supabase's resolve_school_lesson_subject, plus timetable answers.
bool calendarLessonMatchesSubjectChoices(
  CalendarEntry entry,
  CalendarFiltersState filters,
) {
  if (!_personalLesson(entry, filters)) return true;
  final className = filters.defaultClassNames.single;
  final track = filters.defaultSchoolTracks.single;
  final subject = _normalized(entry.eventName);
  if (requiresLanguageSubject(className) &&
      languageSubjectOptions.map(_normalized).contains(subject) &&
      subject != _normalized(_choice(entry, filters, false))) {
    return false;
  }
  if (requiresArtsSubject(className, track) &&
      artsSubjectOptions.map(_normalized).contains(subject)) {
    final chosen = _normalized(_choice(entry, filters, true));
    if (chosen != subject) return false;
    final entryTrack = entry.schoolTrack;
    if (entryTrack != BackendSchoolTrack.unknown &&
        ((subject == 'kunst' && entryTrack != BackendSchoolTrack.ntg) ||
            (subject == 'musik' && entryTrack != BackendSchoolTrack.musisch))) {
      return false;
    }
  }
  for (final answer in filters.timetableChoices.values) {
    if (!schoolSubjectAnswerApplies(answer, className, track, entry.startTime)) {
      continue;
    }
    final record = answer as Map;
    final options = (record['subjects'] as List).map(
      (s) => _normalized(s.toString()),
    );
    if (options.contains(subject) &&
        subject != _normalized(record['selected'].toString())) {
      return false;
    }
  }
  return true;
}

/// NTG pupils choosing music attend the corresponding Musisch music lesson.
bool calendarSubjectOverridesSchoolTrack(
  CalendarEntry entry,
  CalendarFiltersState filters,
) =>
    _personalLesson(entry, filters) &&
    requiresArtsSubject(
      filters.defaultClassNames.single,
      filters.defaultSchoolTracks.single,
    ) &&
    artsSubjectOptions
        .map(_normalized)
        .contains(_normalized(entry.eventName)) &&
    calendarLessonMatchesSubjectChoices(entry, filters);

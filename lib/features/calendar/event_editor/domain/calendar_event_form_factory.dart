import '../../../../core/database/backend_enums.dart';
import '../../../../core/time/app_date_time.dart';
import '../../domain/models/calendar_entry.dart';
import 'calendar_event_form_state.dart';

class CalendarEventFormFactory {
  CalendarEventFormFactory._();

  /// Leeres Formular für „Termin erstellen“ (Standard: gewählter Tag, 9–10 Uhr).
  static CalendarEventFormState forCreate({required DateTime day}) {
    final localDay = AppDateTime.localDay(day);
    final start = AppDateTime.localWallTimeAsUtcInstant(
      localDay,
      hour: 9,
      minute: 0,
    );
    final end = AppDateTime.localWallTimeAsUtcInstant(
      localDay,
      hour: 10,
      minute: 0,
    );
    return CalendarEventFormState(
      eventName: '',
      type: CalendarEntryType.event,
      startTime: start,
      endTime: end,
    );
  }

  static CalendarEventFormState fromEntry(CalendarEntry entry) {
    return CalendarEventFormState(
      eventName: entry.eventName,
      type: entry.type,
      description: entry.description ?? '',
      location: entry.location ?? '',
      note: entry.note ?? '',
      startTime: entry.startTime,
      endTime: entry.endTime,
      choir: entry.choir,
      voices: List<BackendVoice>.from(entry.voices),
      schoolTrack: entry.schoolTrack,
      className: entry.className,
      diet: entry.diet,
      subjectId: entry.subjectId,
      imagePaths: List<String>.from(entry.imagePaths ?? const <String>[]),
    );
  }
}

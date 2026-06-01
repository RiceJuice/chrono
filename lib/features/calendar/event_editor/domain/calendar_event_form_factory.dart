import '../../../../core/database/backend_enums.dart';
import '../../domain/models/calendar_entry.dart';
import 'calendar_event_form_state.dart';

class CalendarEventFormFactory {
  CalendarEventFormFactory._();

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
    );
  }
}

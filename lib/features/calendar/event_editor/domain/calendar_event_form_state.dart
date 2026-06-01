import '../../domain/models/calendar_entry.dart';
import '../../../../core/database/backend_enums.dart';
import 'calendar_series_edit_state.dart';

class CalendarEventFormState {
  CalendarEventFormState({
    required this.eventName,
    required this.type,
    this.description = '',
    this.location = '',
    this.note = '',
    required this.startTime,
    required this.endTime,
    this.choir = BackendChoir.unknown,
    this.voices = const <BackendVoice>[],
    this.schoolTrack = BackendSchoolTrack.unknown,
    this.className,
    this.diet = BackendDiet.unknown,
    this.seriesEdit,
    this.subjectId,
  });

  String eventName;
  CalendarEntryType type;
  String description;
  String location;
  String note;
  DateTime startTime;
  DateTime endTime;
  BackendChoir choir;
  List<BackendVoice> voices;
  BackendSchoolTrack schoolTrack;
  String? className;
  BackendDiet diet;

  /// Nur bei Serienterminen: RRULE und Serienzeitraum.
  final CalendarSeriesEditState? seriesEdit;

  /// Referenz auf [subjects] — nur für Serien-Stunden relevant.
  String? subjectId;

  bool get isRecurringEntry => seriesEdit != null;

  CalendarEventFormState copyWith({
    String? eventName,
    CalendarEntryType? type,
    String? description,
    String? location,
    String? note,
    DateTime? startTime,
    DateTime? endTime,
    BackendChoir? choir,
    List<BackendVoice>? voices,
    BackendSchoolTrack? schoolTrack,
    String? className,
    BackendDiet? diet,
    CalendarSeriesEditState? seriesEdit,
    String? subjectId,
    bool clearClassName = false,
    bool clearSeriesEdit = false,
    bool clearSubjectId = false,
  }) {
    return CalendarEventFormState(
      eventName: eventName ?? this.eventName,
      type: type ?? this.type,
      description: description ?? this.description,
      location: location ?? this.location,
      note: note ?? this.note,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      choir: choir ?? this.choir,
      voices: voices ?? this.voices,
      schoolTrack: schoolTrack ?? this.schoolTrack,
      className: clearClassName ? null : (className ?? this.className),
      diet: diet ?? this.diet,
      seriesEdit: clearSeriesEdit ? null : (seriesEdit ?? this.seriesEdit),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
    );
  }
}

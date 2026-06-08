import 'calendar_filter_text.dart';
import 'calendar_filters_state.dart';

/// Baut den initialen Kalender-Filter aus Profilfeldern (Gate, Snapshot, DB).
CalendarFiltersState calendarFiltersStateFromProfileFields({
  String? choir,
  String? voice,
  String? className,
  String? schoolTrack,
  String? diet,
}) {
  final defaultChoirs = normalizedCalendarFilterList([choir]);
  final defaultVoices = normalizedCalendarFilterList([voice]);
  final defaultClassNames = normalizedCalendarFilterList([className]);
  final defaultSchoolTracks = normalizedCalendarFilterList([schoolTrack]);
  final defaultDiets = normalizedCalendarFilterList([diet]);

  return CalendarFiltersState(
    choirs: defaultChoirs,
    voices: defaultVoices,
    classNames: defaultClassNames,
    schoolTracks: defaultSchoolTracks,
    diets: defaultDiets,
    defaultChoirs: defaultChoirs,
    defaultVoices: defaultVoices,
    defaultClassNames: defaultClassNames,
    defaultSchoolTracks: defaultSchoolTracks,
    defaultDiets: defaultDiets,
    hasInitializedDefaults: true,
  );
}

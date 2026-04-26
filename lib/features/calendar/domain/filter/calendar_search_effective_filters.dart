import 'calendar_filter_selection.dart';
import 'calendar_filters_state.dart';

CalendarFiltersState effectiveCalendarFiltersForSearch({
  required CalendarFiltersState filters,
  required bool hasQuery,
}) {
  if (!hasQuery) return filters;

  return filters.copyWith(
    choirs: effectiveSearchFilterValues(
      selected: filters.choirs,
      defaults: filters.defaultChoirs,
      isExplicit: filters.isChoirExplicit,
    ),
    voices: effectiveSearchFilterValues(
      selected: filters.voices,
      defaults: filters.defaultVoices,
      isExplicit: filters.isVoiceExplicit,
    ),
    classNames: effectiveSearchFilterValues(
      selected: filters.classNames,
      defaults: filters.defaultClassNames,
      isExplicit: filters.isClassNameExplicit,
    ),
    schoolTracks: effectiveSearchFilterValues(
      selected: filters.schoolTracks,
      defaults: filters.defaultSchoolTracks,
      isExplicit: filters.isSchoolTrackExplicit,
    ),
  );
}

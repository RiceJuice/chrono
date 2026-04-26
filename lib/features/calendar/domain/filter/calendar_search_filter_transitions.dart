import 'calendar_filter_selection.dart';
import 'calendar_filter_text.dart';
import 'calendar_filters_state.dart';

enum CalendarFilterCategory { choir, voice, className, schoolTrack }

class CalendarSearchFilterTransition {
  const CalendarSearchFilterTransition({
    required this.state,
    required this.restorePoint,
  });

  final CalendarFiltersState state;
  final CalendarFiltersState? restorePoint;
}

CalendarSearchFilterTransition toggleSearchFilterCategory({
  required CalendarFiltersState state,
  required CalendarFilterCategory category,
  required String value,
  required CalendarFiltersState? restorePoint,
}) {
  if (_isRestoringToggle(
    state: state,
    category: category,
    value: value,
    restorePoint: restorePoint,
  )) {
    return CalendarSearchFilterTransition(
      state: restorePoint!,
      restorePoint: null,
    );
  }

  final choirs = _nextSelectionForCategory(
    category: CalendarFilterCategory.choir,
    toggledCategory: category,
    current: state.choirs,
    defaults: state.defaultChoirs,
    isExplicit: state.isChoirExplicit,
    value: value,
  );
  final voices = _nextSelectionForCategory(
    category: CalendarFilterCategory.voice,
    toggledCategory: category,
    current: state.voices,
    defaults: state.defaultVoices,
    isExplicit: state.isVoiceExplicit,
    value: value,
  );
  final classNames = _nextSelectionForCategory(
    category: CalendarFilterCategory.className,
    toggledCategory: category,
    current: state.classNames,
    defaults: state.defaultClassNames,
    isExplicit: state.isClassNameExplicit,
    value: value,
  );
  final schoolTracks = _nextSelectionForCategory(
    category: CalendarFilterCategory.schoolTrack,
    toggledCategory: category,
    current: state.schoolTracks,
    defaults: state.defaultSchoolTracks,
    isExplicit: state.isSchoolTrackExplicit,
    value: value,
  );

  return CalendarSearchFilterTransition(
    state: state.copyWith(
      choirs: choirs.values,
      voices: voices.values,
      classNames: classNames.values,
      schoolTracks: schoolTracks.values,
      hasUserOverrides: true,
      isChoirExplicit: choirs.isExplicit,
      isVoiceExplicit: voices.isExplicit,
      isClassNameExplicit: classNames.isExplicit,
      isSchoolTrackExplicit: schoolTracks.isExplicit,
    ),
    restorePoint: restorePoint ?? state,
  );
}

bool _isRestoringToggle({
  required CalendarFiltersState state,
  required CalendarFilterCategory category,
  required String value,
  required CalendarFiltersState? restorePoint,
}) {
  if (restorePoint == null || !_isCategoryExplicit(state, category)) {
    return false;
  }

  final normalized = normalizeCalendarFilterText(value);
  if (normalized == null) return false;

  final selected = _selectedValuesForCategory(state, category);
  return selected.length == 1 && selected.contains(normalized);
}

CalendarFilterSelection _nextSelectionForCategory({
  required CalendarFilterCategory category,
  required CalendarFilterCategory toggledCategory,
  required List<String> current,
  required List<String> defaults,
  required bool isExplicit,
  required String value,
}) {
  if (category == toggledCategory) {
    return toggleSearchFilterValue(
      current: current,
      defaults: defaults,
      isExplicit: isExplicit,
      value: value,
    );
  }

  return removeImplicitDefaultValues(
    current: current,
    defaults: defaults,
    isExplicit: isExplicit,
  );
}

bool _isCategoryExplicit(
  CalendarFiltersState state,
  CalendarFilterCategory category,
) {
  return switch (category) {
    CalendarFilterCategory.choir => state.isChoirExplicit,
    CalendarFilterCategory.voice => state.isVoiceExplicit,
    CalendarFilterCategory.className => state.isClassNameExplicit,
    CalendarFilterCategory.schoolTrack => state.isSchoolTrackExplicit,
  };
}

List<String> _selectedValuesForCategory(
  CalendarFiltersState state,
  CalendarFilterCategory category,
) {
  return switch (category) {
    CalendarFilterCategory.choir => state.choirs,
    CalendarFilterCategory.voice => state.voices,
    CalendarFilterCategory.className => state.classNames,
    CalendarFilterCategory.schoolTrack => state.schoolTracks,
  };
}

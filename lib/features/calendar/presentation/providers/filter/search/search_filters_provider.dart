import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;

import '../../../../domain/filter/calendar_search_filter_transitions.dart';
import '../calendar/calendar_filters_state.dart';
import '../shared/calendar_filters_notifier_base.dart';

class SearchFiltersNotifier extends CalendarFiltersNotifierBase {
  CalendarFiltersState? _restorePointBeforeExplicitToggle;

  void initializeFromCalendar(CalendarFiltersState calendarFilters) {
    _restorePointBeforeExplicitToggle = null;
    final defaultChoirs = calendarFilters.choirs;
    final defaultVoices = calendarFilters.voices;
    final defaultClassNames = calendarFilters.classNames;
    final defaultSchoolTracks = calendarFilters.schoolTracks;
    initializeDefaults(
      choirs: defaultChoirs,
      voices: defaultVoices,
      classNames: defaultClassNames,
      schoolTracks: defaultSchoolTracks,
    );
  }

  @override
  void toggleChoir(String value) {
    _toggleSearchCategory(CalendarFilterCategory.choir, value);
  }

  @override
  void toggleVoice(String value) {
    _toggleSearchCategory(CalendarFilterCategory.voice, value);
  }

  @override
  void toggleClassName(String value) {
    _toggleSearchCategory(CalendarFilterCategory.className, value);
  }

  @override
  void toggleSchoolTrack(String value) {
    _toggleSearchCategory(CalendarFilterCategory.schoolTrack, value);
  }

  @override
  void clearChoirs() {
    _restorePointBeforeExplicitToggle = null;
    super.clearChoirs();
  }

  @override
  void clearVoices() {
    _restorePointBeforeExplicitToggle = null;
    super.clearVoices();
  }

  @override
  void clearClassNames() {
    _restorePointBeforeExplicitToggle = null;
    super.clearClassNames();
  }

  @override
  void clearSchoolTracks() {
    _restorePointBeforeExplicitToggle = null;
    super.clearSchoolTracks();
  }

  @override
  void removeChoir(String value) {
    _restorePointBeforeExplicitToggle = null;
    super.removeChoir(value);
  }

  @override
  void removeVoice(String value) {
    _restorePointBeforeExplicitToggle = null;
    super.removeVoice(value);
  }

  @override
  void removeClassName(String value) {
    _restorePointBeforeExplicitToggle = null;
    super.removeClassName(value);
  }

  @override
  void removeSchoolTrack(String value) {
    _restorePointBeforeExplicitToggle = null;
    super.removeSchoolTrack(value);
  }

  @override
  void resetToDefaults() {
    _restorePointBeforeExplicitToggle = null;
    super.resetToDefaults();
  }

  void _toggleSearchCategory(CalendarFilterCategory category, String value) {
    final transition = toggleSearchFilterCategory(
      state: state,
      category: category,
      value: value,
      restorePoint: _restorePointBeforeExplicitToggle,
    );
    state = transition.state;
    _restorePointBeforeExplicitToggle = transition.restorePoint;
  }
}

final searchFiltersProvider =
    fr.NotifierProvider<SearchFiltersNotifier, CalendarFiltersState>(
      SearchFiltersNotifier.new,
    );

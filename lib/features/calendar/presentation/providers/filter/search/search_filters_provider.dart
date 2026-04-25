import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;

import '../calendar/calendar_filters_state.dart';
import '../shared/calendar_filters_notifier_base.dart';

class SearchFiltersNotifier extends CalendarFiltersNotifierBase {
  void initializeFromCalendar(CalendarFiltersState calendarFilters) {
    final defaultChoirs = calendarFilters.choirs;
    final defaultVoices = calendarFilters.voices;
    final defaultClassNames = calendarFilters.classNames;
    initializeDefaults(
      choirs: defaultChoirs,
      voices: defaultVoices,
      classNames: defaultClassNames,
    );
  }

  @override
  void toggleChoir(String value) {
    final nextChoirs = _toggleFilterValue(
      current: state.choirs,
      defaults: state.defaultChoirs,
      explicit: state.isChoirExplicit,
      toggledValue: value,
    );
    state = state.copyWith(
      choirs: nextChoirs,
      voices: _stripDefaultsIfImplicit(
        current: state.voices,
        defaults: state.defaultVoices,
        explicit: state.isVoiceExplicit,
      ),
      classNames: _stripDefaultsIfImplicit(
        current: state.classNames,
        defaults: state.defaultClassNames,
        explicit: state.isClassNameExplicit,
      ),
      hasUserOverrides: true,
      isChoirExplicit: true,
    );
  }

  @override
  void toggleVoice(String value) {
    final nextVoices = _toggleFilterValue(
      current: state.voices,
      defaults: state.defaultVoices,
      explicit: state.isVoiceExplicit,
      toggledValue: value,
    );
    state = state.copyWith(
      choirs: _stripDefaultsIfImplicit(
        current: state.choirs,
        defaults: state.defaultChoirs,
        explicit: state.isChoirExplicit,
      ),
      voices: nextVoices,
      classNames: _stripDefaultsIfImplicit(
        current: state.classNames,
        defaults: state.defaultClassNames,
        explicit: state.isClassNameExplicit,
      ),
      hasUserOverrides: true,
      isVoiceExplicit: true,
    );
  }

  @override
  void toggleClassName(String value) {
    final nextClassNames = _toggleFilterValue(
      current: state.classNames,
      defaults: state.defaultClassNames,
      explicit: state.isClassNameExplicit,
      toggledValue: value,
    );
    state = state.copyWith(
      choirs: _stripDefaultsIfImplicit(
        current: state.choirs,
        defaults: state.defaultChoirs,
        explicit: state.isChoirExplicit,
      ),
      voices: _stripDefaultsIfImplicit(
        current: state.voices,
        defaults: state.defaultVoices,
        explicit: state.isVoiceExplicit,
      ),
      classNames: nextClassNames,
      hasUserOverrides: true,
      isClassNameExplicit: true,
    );
  }
}

final searchFiltersProvider =
    fr.NotifierProvider<SearchFiltersNotifier, CalendarFiltersState>(
      SearchFiltersNotifier.new,
    );

List<String> _withoutDefaults(List<String> current, List<String> defaults) {
  if (current.isEmpty || defaults.isEmpty) return current;
  final defaultsSet = defaults.toSet();
  return current.where((value) => !defaultsSet.contains(value)).toList();
}

List<String> _stripDefaultsIfImplicit({
  required List<String> current,
  required List<String> defaults,
  required bool explicit,
}) {
  if (explicit) return current;
  return _withoutDefaults(current, defaults);
}

List<String> _toggleFilterValue({
  required List<String> current,
  required List<String> defaults,
  required bool explicit,
  required String toggledValue,
}) {
  final base = (explicit ? current : _withoutDefaults(current, defaults)).toSet();
  if (base.contains(toggledValue)) {
    base.remove(toggledValue);
  } else {
    base.add(toggledValue);
  }
  final next = base.toList()..sort();
  return next;
}

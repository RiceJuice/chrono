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
}

final searchFiltersProvider =
    fr.NotifierProvider<SearchFiltersNotifier, CalendarFiltersState>(
      SearchFiltersNotifier.new,
    );



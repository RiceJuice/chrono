import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;

import '../../../../domain/filter/calendar_filter_text.dart';
import '../../../../../settings/data/models/profile_snapshot.dart';
import 'calendar_filters_state.dart';
import '../shared/calendar_filters_notifier_base.dart';

class CalendarFiltersNotifier extends CalendarFiltersNotifierBase {
  void initializeFromProfile(ProfileSnapshot? profile) {
    final defaultChoirs = normalizedCalendarFilterList([profile?.choir]);
    final defaultVoices = const <String>[];
    final defaultClassNames = normalizedCalendarFilterList([profile?.className]);
    final defaultSchoolTracks = normalizedCalendarFilterList([profile?.schoolTrack]);
    initializeDefaults(
      choirs: defaultChoirs,
      voices: defaultVoices,
      classNames: defaultClassNames,
      schoolTracks: defaultSchoolTracks,
    );
  }
}

final calendarFiltersProvider =
    fr.NotifierProvider<CalendarFiltersNotifier, CalendarFiltersState>(
      CalendarFiltersNotifier.new,
    );

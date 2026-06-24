import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filters_provider.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/search/search_filters_provider.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String guardianCalendarFilterSyncKey(
  String? activeChildId,
  ProfileSnapshot? profile,
) {
  return [
    activeChildId,
    profile?.choir,
    profile?.voice,
    profile?.className,
    profile?.schoolTrack,
    profile?.diet,
  ].join('|');
}

void syncGuardianCalendarFilters(WidgetRef ref, ProfileSnapshot? profile) {
  ref.read(calendarFiltersProvider.notifier).replaceFromProfile(profile);
  ref
      .read(searchFiltersProvider.notifier)
      .initializeFromCalendar(ref.read(calendarFiltersProvider));
}

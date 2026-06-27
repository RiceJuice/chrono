import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filters_provider.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/search/search_filters_provider.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_share_permissions.dart';
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

void syncGuardianCalendarFilters(
  WidgetRef ref,
  ProfileSnapshot? profile, {
  GuardianChildSharePermissions? sharePermissions,
}) {
  ref.read(calendarFiltersProvider.notifier).replaceFromProfile(profile);
  if (sharePermissions != null) {
    ref.read(calendarFiltersProvider.notifier).applyGuardianSharePermissions(
          shareSchool: sharePermissions.shareSchool,
          shareMeal: sharePermissions.shareMeal,
          shareChoir: sharePermissions.shareChoir,
        );
  }
  ref
      .read(searchFiltersProvider.notifier)
      .initializeFromCalendar(ref.read(calendarFiltersProvider));
}

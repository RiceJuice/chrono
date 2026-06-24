import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filters_provider.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/search/search_filters_provider.dart';
import 'package:chronoapp/features/settings/data/settings_profile_repository.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_active_child_id.dart';
import 'package:chronoapp/features/settings/presentation/providers/effective_calendar_profile_provider.dart';
import 'package:chronoapp/features/settings/presentation/providers/settings_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> updateGuardianActiveChildCalendarDefaults(
  WidgetRef ref, {
  String? className,
  String? schoolTrack,
  String? voice,
  String? diet,
  String? choir,
}) async {
  final childId = ref.read(activeGuardianChildIdProvider);
  if (childId == null || childId.isEmpty) {
    throw SettingsProfileRepositoryException('Kein aktives Kind ausgewählt.');
  }

  await ref.read(settingsProfileRepositoryProvider).updateLinkedChildCalendarDefaults(
        childId: childId,
        className: className,
        schoolTrack: schoolTrack,
        voice: voice,
        diet: diet,
        choir: choir,
      );

  ref.invalidate(linkedChildProfileProvider(childId));

  ref
      .read(calendarFiltersProvider.notifier)
      .applyProfileFilterChanges(
        choir: choir,
        voice: voice,
        className: className,
        schoolTrack: schoolTrack,
        diet: diet,
      );
  ref
      .read(searchFiltersProvider.notifier)
      .initializeFromCalendar(ref.read(calendarFiltersProvider));
}

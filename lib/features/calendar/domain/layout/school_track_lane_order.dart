import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filter_text.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';

/// Stabile Lane-Reihenfolge für Schulstunden bei mehreren aktiven Schulzweigen.
///
/// Eigener Profil-Zweig steht links, danach feste Reihenfolge NTG → Musisch → unbekannt.
int schoolTrackLanePriority(
  CalendarEntry entry, {
  required List<String> ownSchoolTracks,
}) {
  if (entry.type != CalendarEntryType.lesson) {
    return 100;
  }

  final normalizedTrack = normalizeCalendarFilterText(
    entry.schoolTrack.toBackend(),
  );
  if (normalizedTrack != null && ownSchoolTracks.contains(normalizedTrack)) {
    return 0;
  }

  return switch (entry.schoolTrack) {
    BackendSchoolTrack.ntg => 1,
    BackendSchoolTrack.musisch => 2,
    BackendSchoolTrack.unknown => 3,
  };
}

int compareCalendarEntriesForLaneOrder(
  CalendarEntry a,
  CalendarEntry b, {
  required List<String> ownSchoolTracks,
}) {
  final byStart = a.startTime.compareTo(b.startTime);
  if (byStart != 0) return byStart;

  final byEnd = b.endTime.compareTo(a.endTime);
  if (byEnd != 0) return byEnd;

  final byTrack = schoolTrackLanePriority(
    a,
    ownSchoolTracks: ownSchoolTracks,
  ).compareTo(
    schoolTrackLanePriority(b, ownSchoolTracks: ownSchoolTracks),
  );
  if (byTrack != 0) return byTrack;

  return a.id.compareTo(b.id);
}

bool isOtherSchoolTrackLesson(
  CalendarEntry entry, {
  required List<String> ownSchoolTracks,
}) {
  if (entry.type != CalendarEntryType.lesson || ownSchoolTracks.isEmpty) {
    return false;
  }
  if (entry.schoolTrack == BackendSchoolTrack.unknown) {
    return false;
  }
  final normalizedTrack = normalizeCalendarFilterText(
    entry.schoolTrack.toBackend(),
  );
  return normalizedTrack == null || !ownSchoolTracks.contains(normalizedTrack);
}

/// Stundenplan-Live-Activity: nur eigene Profil-Klasse und -Zweig zählen/anzeigen.
bool lessonMatchesOwnSchoolProfile({
  required CalendarEntry entry,
  required CalendarFiltersState filters,
}) {
  if (entry.type != CalendarEntryType.lesson) return true;

  final ownClasses = filters.defaultClassNames;
  if (ownClasses.isNotEmpty) {
    final className = normalizeCalendarFilterText(entry.className);
    if (className != null && !ownClasses.contains(className)) {
      return false;
    }
  }

  final ownTracks = filters.defaultSchoolTracks;
  if (ownTracks.isNotEmpty && entry.schoolTrack != BackendSchoolTrack.unknown) {
    final track = normalizeCalendarFilterText(entry.schoolTrack.toBackend());
    if (track != null && !ownTracks.contains(track)) {
      return false;
    }
  }

  return true;
}

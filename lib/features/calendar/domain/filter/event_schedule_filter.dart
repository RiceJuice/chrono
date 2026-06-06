import '../../../../core/database/backend_enums.dart';
import '../models/event_schedule.dart';
import 'calendar_filters_state.dart';
import 'calendar_filter_text.dart';

/// Filter für die Ablaufplan-Liste im Event-Detail.
enum EventScheduleListFilter {
  all,
  mine,
}

/// Prüft, ob ein Ablaufplanpunkt zum Profil des Nutzers passt (Chor/Stimme).
bool eventScheduleMatchesUserProfile({
  required EventSchedule schedule,
  required CalendarFiltersState filters,
}) {
  final userChoirs = filters.defaultChoirs;
  final userVoices = filters.defaultVoices;

  if (schedule.choirs.isEmpty && schedule.voices.isEmpty) {
    return true;
  }

  var choirOk = true;
  if (schedule.choirs.isNotEmpty) {
    if (userChoirs.isEmpty) {
      choirOk = false;
    } else {
      final labels = schedule.choirs
          .map((c) => normalizeCalendarFilterText(c.toBackend()))
          .whereType<String>()
          .toSet();
      choirOk = labels.any(userChoirs.contains);
    }
  }

  if (!choirOk) return false;

  if (schedule.voices.isEmpty) return true;

  if (userVoices.isEmpty) return false;

  final voiceLabels = schedule.voices
      .map((v) => normalizeCalendarFilterText(v.toBackend()))
      .whereType<String>()
      .toSet();
  return voiceLabels.any(userVoices.contains);
}

/// Filterlogik für Ablaufplanpunkte (choir/voices) — Kalender-Filter.
bool eventScheduleVisible({
  required EventSchedule schedule,
  required CalendarFiltersState filters,
}) {
  if (schedule.choirs.isNotEmpty && filters.choirs.isNotEmpty) {
    final labels = schedule.choirs
        .map((c) => normalizeCalendarFilterText(c.toBackend()))
        .whereType<String>()
        .toSet();
    final hasMatch = labels.any(filters.choirs.contains);
    if (!hasMatch) return false;
  }

  if (schedule.voices.isNotEmpty && filters.voices.isNotEmpty) {
    final labels = schedule.voices
        .map((v) => normalizeCalendarFilterText(v.toBackend()))
        .whereType<String>()
        .toSet();
    final hasMatch = labels.any(filters.voices.contains);
    if (!hasMatch) return false;
  }

  return true;
}

import '../../../../core/database/backend_enums.dart';
import '../models/calendar_entry.dart';
import 'calendar_filters_state.dart';
import 'calendar_filter_text.dart';

bool calendarEntryMatchesFilters({
  required CalendarEntry entry,
  required CalendarFiltersState filters,
  required bool hideUnknownWhenFilterActive,
}) {
  if (filters.choirs.isNotEmpty) {
    final value = normalizeCalendarFilterText(entry.choir.toBackend());
    if (!_matchesCategory(
      selectedValues: filters.choirs,
      entryValue: value,
      isUnknown: entry.choir == BackendChoir.unknown,
      hideUnknownWhenFilterActive: hideUnknownWhenFilterActive,
    )) {
      return false;
    }
  }

  if (filters.voices.isNotEmpty) {
    final values = entry.voices
        .map((voice) => normalizeCalendarFilterText(voice.toBackend()))
        .whereType<String>()
        .toSet();
    final fallback = normalizeCalendarFilterText(entry.voice.toBackend());
    if (values.isEmpty &&
        entry.voice != BackendVoice.unknown &&
        fallback != null) {
      values.add(fallback);
    }
    final hasVoiceMatch = values.any(filters.voices.contains);
    if (!hasVoiceMatch && (hideUnknownWhenFilterActive || values.isNotEmpty)) {
      return false;
    }
  }

  if (filters.classNames.isNotEmpty) {
    final value = normalizeCalendarFilterText(entry.className);
    if (!_matchesCategory(
      selectedValues: filters.classNames,
      entryValue: value,
      isUnknown: value == null,
      hideUnknownWhenFilterActive: hideUnknownWhenFilterActive,
    )) {
      return false;
    }
  }

  if (filters.schoolTracks.isNotEmpty) {
    final value = normalizeCalendarFilterText(entry.schoolTrack.toBackend());
    if (!_matchesCategory(
      selectedValues: filters.schoolTracks,
      entryValue: value,
      isUnknown: entry.schoolTrack == BackendSchoolTrack.unknown,
      hideUnknownWhenFilterActive: hideUnknownWhenFilterActive,
    )) {
      return false;
    }
  }

  return true;
}

bool _matchesCategory({
  required List<String> selectedValues,
  required String? entryValue,
  required bool isUnknown,
  required bool hideUnknownWhenFilterActive,
}) {
  if (entryValue == null || isUnknown) {
    return !hideUnknownWhenFilterActive;
  }
  return selectedValues.contains(entryValue);
}

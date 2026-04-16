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
    if (values.isEmpty && entry.voice != BackendVoice.unknown && fallback != null) {
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

  return true;
}

List<String> toggleCalendarFilterValue(List<String> values, String value) {
  final normalized = normalizeCalendarFilterText(value);
  if (normalized == null) return values;

  final set = values.toSet();
  if (set.contains(normalized)) {
    set.remove(normalized);
  } else {
    set.add(normalized);
  }
  final items = set.toList()..sort();
  return items;
}

List<String> removeCalendarFilterValue(List<String> values, String value) {
  final normalized = normalizeCalendarFilterText(value);
  if (normalized == null) return values;
  final items = values.where((item) => item != normalized).toList()..sort();
  return items;
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

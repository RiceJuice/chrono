import '../../../../../../core/database/backend_enums.dart';
import '../../../../domain/models/calendar_entry.dart';
import 'calendar_filters_state.dart';

String? normalizeFilterText(String? value) {
  if (value == null) return null;
  final normalized = value.trim().toLowerCase();
  return normalized.isEmpty ? null : normalized;
}

List<String> normalizedFilterList(Iterable<String?> values) {
  final set = <String>{};
  for (final value in values) {
    final normalized = normalizeFilterText(value);
    if (normalized != null) {
      set.add(normalized);
    }
  }
  final items = set.toList()..sort();
  return items;
}

bool matchesFilters({
  required CalendarEntry entry,
  required CalendarFiltersState filters,
  required bool hideUnknownWhenFilterActive,
}) {
  if (filters.choirs.isNotEmpty) {
    final value = normalizeFilterText(entry.choir.toBackend());
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
        .map((voice) => normalizeFilterText(voice.toBackend()))
        .whereType<String>()
        .toSet();
    final fallback = normalizeFilterText(entry.voice.toBackend());
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
    final value = normalizeFilterText(entry.className);
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

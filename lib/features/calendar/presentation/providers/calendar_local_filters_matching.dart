part of 'calendar_providers.dart';

bool _matchesFilters({
  required CalendarEntry entry,
  required CalendarLocalFilters filters,
  required bool hideUnknownWhenFilterActive,
}) {
  final choirFilter = filters.choir;
  final voiceFilter = filters.voice;
  final classFilter = filters.className;

  if (choirFilter != null) {
    final value = _normalizeText(entry.choir.toBackend());
    if (!_matchesFilterValue(
      filterValue: choirFilter,
      entryValue: value,
      isUnknown: entry.choir == BackendChoir.unknown,
      hideUnknownWhenFilterActive: hideUnknownWhenFilterActive,
    )) {
      return false;
    }
  }

  if (voiceFilter != null) {
    final value = _normalizeText(entry.voice.toBackend());
    if (!_matchesFilterValue(
      filterValue: voiceFilter,
      entryValue: value,
      isUnknown: entry.voice == BackendVoice.unknown,
      hideUnknownWhenFilterActive: hideUnknownWhenFilterActive,
    )) {
      return false;
    }
  }

  if (classFilter != null) {
    final value = _normalizeText(entry.className);
    if (!_matchesFilterValue(
      filterValue: classFilter,
      entryValue: value,
      isUnknown: value == null,
      hideUnknownWhenFilterActive: hideUnknownWhenFilterActive,
    )) {
      return false;
    }
  }

  return true;
}

bool _matchesFilterValue({
  required String filterValue,
  required String? entryValue,
  required bool isUnknown,
  required bool hideUnknownWhenFilterActive,
}) {
  if (entryValue == null || isUnknown) {
    return !hideUnknownWhenFilterActive;
  }
  return entryValue == filterValue;
}

String? _normalizeText(String? value) {
  if (value == null) return null;
  final normalized = value.trim().toLowerCase();
  return normalized.isEmpty ? null : normalized;
}

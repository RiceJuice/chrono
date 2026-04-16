String? normalizeCalendarFilterText(String? value) {
  if (value == null) return null;
  final normalized = value.trim().toLowerCase();
  return normalized.isEmpty ? null : normalized;
}

List<String> normalizedCalendarFilterList(Iterable<String?> values) {
  final set = <String>{};
  for (final value in values) {
    final normalized = normalizeCalendarFilterText(value);
    if (normalized != null) {
      set.add(normalized);
    }
  }
  final items = set.toList()..sort();
  return items;
}

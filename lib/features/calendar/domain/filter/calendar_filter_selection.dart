import 'calendar_filter_text.dart';

class CalendarFilterSelection {
  const CalendarFilterSelection({
    required this.values,
    required this.isExplicit,
  });

  final List<String> values;
  final bool isExplicit;
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

CalendarFilterSelection toggleSearchFilterValue({
  required List<String> current,
  required List<String> defaults,
  required bool isExplicit,
  required String value,
}) {
  final base = isExplicit ? current : _withoutDefaults(current, defaults);
  return CalendarFilterSelection(
    values: toggleCalendarFilterValue(base, value),
    isExplicit: true,
  );
}

CalendarFilterSelection removeImplicitDefaultValues({
  required List<String> current,
  required List<String> defaults,
  required bool isExplicit,
}) {
  if (isExplicit || current.isEmpty || defaults.isEmpty) {
    return CalendarFilterSelection(values: current, isExplicit: isExplicit);
  }

  final stripped = _withoutDefaults(current, defaults);
  return CalendarFilterSelection(
    values: stripped,
    isExplicit: stripped.length != current.length,
  );
}

List<String> effectiveSearchFilterValues({
  required List<String> selected,
  required List<String> defaults,
  required bool isExplicit,
}) {
  if (isExplicit || defaults.isEmpty) return selected;
  final merged = <String>{...selected, ...defaults}.toList()..sort();
  return merged;
}

List<String> _withoutDefaults(List<String> current, List<String> defaults) {
  if (current.isEmpty || defaults.isEmpty) return current;
  final defaultsSet = defaults.toSet();
  return current.where((value) => !defaultsSet.contains(value)).toList();
}

import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_all_day_day_label.dart';

/// Sichtbarer Abschnitt eines Ganztags-Balkens in der Wochenansicht.
enum WeekAllDayBreakBarSegment { single, start, middle, end }

/// Ein Ganztags-Eintrag (Ferien/Feiertag) als horizontaler Balken im Wochenraster.
class WeekAllDayBreakSpan {
  const WeekAllDayBreakSpan({
    required this.label,
    required this.startColumn,
    required this.endColumn,
    required this.lane,
  });

  final String label;
  final int startColumn;
  final int endColumn;
  final int lane;

  WeekAllDayBreakBarSegment segmentAt(int columnIndex) {
    if (startColumn == endColumn) return WeekAllDayBreakBarSegment.single;
    if (columnIndex == startColumn) return WeekAllDayBreakBarSegment.start;
    if (columnIndex == endColumn) return WeekAllDayBreakBarSegment.end;
    return WeekAllDayBreakBarSegment.middle;
  }

  bool containsColumn(int columnIndex) {
    return columnIndex >= startColumn && columnIndex <= endColumn;
  }

  /// Spalte für den Titel: immer [startColumn], außer der Block beginnt links
  /// außerhalb des sichtbaren Bereichs — dann erste sichtbare Spalte des Blocks.
  int labelColumnIndex({int? firstVisibleColumnInWeek}) {
    if (firstVisibleColumnInWeek == null ||
        startColumn >= firstVisibleColumnInWeek) {
      return startColumn;
    }
    if (containsColumn(firstVisibleColumnInWeek)) {
      return firstVisibleColumnInWeek;
    }
    return startColumn;
  }

  bool shouldShowLabelAtColumn(
    int columnIndex, {
    int? firstVisibleColumnInWeek,
  }) {
    if (!containsColumn(columnIndex)) return false;
    return columnIndex == labelColumnIndex(
      firstVisibleColumnInWeek: firstVisibleColumnInWeek,
    );
  }
}

class WeekAllDayBreakLayout {
  const WeekAllDayBreakLayout({required this.spans});

  final List<WeekAllDayBreakSpan> spans;

  int get laneCount {
    if (spans.isEmpty) return 0;
    return spans.map((span) => span.lane).reduce((a, b) => a > b ? a : b) + 1;
  }

  List<WeekAllDayBreakSpan> spansForColumn(int columnIndex) {
    return spans
        .where((span) => span.containsColumn(columnIndex))
        .toList(growable: false);
  }
}

String _normalizedBreakLabel(CalendarEntry entry) {
  return entry.eventName.trim().toLowerCase();
}

void _appendContiguousBreakRuns({
  required String displayLabel,
  required List<int> sortedColumns,
  required List<WeekAllDayBreakSpan> spans,
}) {
  if (sortedColumns.isEmpty) return;

  var runStart = sortedColumns.first;
  var previous = sortedColumns.first;
  for (var i = 1; i <= sortedColumns.length; i++) {
    final isRunEnd = i == sortedColumns.length || sortedColumns[i] != previous + 1;
    if (!isRunEnd) {
      previous = sortedColumns[i];
      continue;
    }

    spans.add(
      WeekAllDayBreakSpan(
        label: displayLabel,
        startColumn: runStart,
        endColumn: previous,
        lane: 0,
      ),
    );

    if (i < sortedColumns.length) {
      runStart = sortedColumns[i];
      previous = sortedColumns[i];
    }
  }
}

/// [entriesByDay] muss Mo–So (Index 0–6) enthalten.
WeekAllDayBreakLayout layoutWeekAllDayBreaks({
  required List<List<CalendarEntry>> entriesByDay,
}) {
  final columnsByNormalizedLabel = <String, Set<int>>{};
  final displayLabelByNormalized = <String, String>{};

  for (var column = 0; column < entriesByDay.length && column < 7; column++) {
    final labelsThisDay = <String>{};
    for (final entry in entriesByDay[column]) {
      if (entry.type != CalendarEntryType.breakType) continue;
      final normalized = _normalizedBreakLabel(entry);
      if (normalized.isEmpty) continue;
      labelsThisDay.add(normalized);
      columnsByNormalizedLabel.putIfAbsent(normalized, () => <int>{}).add(column);
      displayLabelByNormalized.putIfAbsent(
        normalized,
        () => entry.eventName.trim(),
      );
    }
  }

  final spans = <WeekAllDayBreakSpan>[];
  for (final normalized in columnsByNormalizedLabel.keys) {
    final columns = columnsByNormalizedLabel[normalized]!.toList()..sort();
    _appendContiguousBreakRuns(
      displayLabel: displayLabelByNormalized[normalized] ?? 'Ferien / Feiertag',
      sortedColumns: columns,
      spans: spans,
    );
  }

  spans.sort((a, b) {
    final start = a.startColumn.compareTo(b.startColumn);
    if (start != 0) return start;
    final durationA = a.endColumn - a.startColumn;
    final durationB = b.endColumn - b.startColumn;
    if (durationA != durationB) return durationB.compareTo(durationA);
    return a.label.compareTo(b.label);
  });

  final laneEnds = <int>[];
  final assigned = <WeekAllDayBreakSpan>[];
  for (final span in spans) {
    var lane = 0;
    while (lane < laneEnds.length && laneEnds[lane] >= span.startColumn) {
      lane++;
    }
    if (lane == laneEnds.length) {
      laneEnds.add(span.endColumn);
    } else {
      laneEnds[lane] = span.endColumn;
    }
    assigned.add(
      WeekAllDayBreakSpan(
        label: span.label,
        startColumn: span.startColumn,
        endColumn: span.endColumn,
        lane: lane,
      ),
    );
  }

  return WeekAllDayBreakLayout(spans: assigned);
}

const double kWeekAllDayLaneHeight = 22;
const double kWeekAllDayLaneGap = 2;
const double kWeekAllDayRowVerticalPadding = 6;

/// Mindesthöhe der Balkenfläche, wenn keine Ganztags-Termine vorliegen.
const double kWeekAllDayMinBarAreaHeight = 10;

double weekAllDayRowHeight(int laneCount) {
  if (laneCount <= 0) return 0;
  return kWeekAllDayRowVerticalPadding +
      laneCount * kWeekAllDayLaneHeight +
      (laneCount - 1) * kWeekAllDayLaneGap;
}

double weekAllDayBarAreaHeight(int laneCount) {
  if (laneCount <= 0) return kWeekAllDayMinBarAreaHeight;
  return weekAllDayRowHeight(laneCount);
}

/// Gesamthöhe inkl. Tageszeile — immer > 0 in der Wochenansicht.
double weekAllDaySectionHeight(int laneCount) {
  return kWeekAllDayDayLabelHeight + weekAllDayBarAreaHeight(laneCount);
}

int weekAllDayVisibleLaneLimit(double sectionHeight) {
  final rowHeight = sectionHeight - kWeekAllDayDayLabelHeight;
  if (rowHeight <= kWeekAllDayRowVerticalPadding) return 0;
  final inner = rowHeight - kWeekAllDayRowVerticalPadding + kWeekAllDayLaneGap;
  final perLane = kWeekAllDayLaneHeight + kWeekAllDayLaneGap;
  return (inner / perLane).floor().clamp(0, 99);
}

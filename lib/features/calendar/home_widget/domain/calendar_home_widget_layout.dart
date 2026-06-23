import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/time/app_date_time.dart';

import '../../domain/filter/calendar_filters_logic.dart';
import '../../domain/filter/calendar_filters_state.dart';
import '../../domain/models/calendar_entry.dart';
import '../../presentation/widgets/search_results/search_results_sections.dart';

enum CalendarHomeWidgetRowKind { header, entry }

class CalendarHomeWidgetRow {
  const CalendarHomeWidgetRow._({
    required this.kind,
    this.day,
    this.entry,
  });

  factory CalendarHomeWidgetRow.header(DateTime day) {
    return CalendarHomeWidgetRow._(kind: CalendarHomeWidgetRowKind.header, day: day);
  }

  factory CalendarHomeWidgetRow.entry(CalendarEntry entry) {
    return CalendarHomeWidgetRow._(
      kind: CalendarHomeWidgetRowKind.entry,
      entry: entry,
    );
  }

  final CalendarHomeWidgetRowKind kind;
  final DateTime? day;
  final CalendarEntry? entry;
}

class CalendarHomeWidgetLayout {
  CalendarHomeWidgetLayout._();

  static const double dayHeaderHeight = 40;
  static const double rowSpacing = AppSpacing.m;
  static const double estimatedCardHeight = 96;
  static const double heightSafetyMargin = 12;

  static List<CalendarEntry> filterEntries({
    required List<CalendarEntry> entries,
    required CalendarFiltersState filters,
  }) {
    return entries
        .where(
          (entry) => calendarEntryMatchesFilters(
            entry: entry,
            filters: filters,
            hideUnknownWhenFilterActive: false,
          ),
        )
        .toList(growable: false);
  }

  /// Baut Zeilen ab [sectionsResult.initialSectionIndex] und füllt bis [maxHeight].
  static List<CalendarHomeWidgetRow> buildFittedRows({
    required SearchResultsSections sectionsResult,
    required double maxHeight,
  }) {
    final budget = maxHeight - heightSafetyMargin;
    if (sectionsResult.sections.isEmpty || budget <= dayHeaderHeight) {
      return const <CalendarHomeWidgetRow>[];
    }

    final fitted = <CalendarHomeWidgetRow>[];
    var heightUsed = 0.0;

    for (
      var sectionIndex = sectionsResult.initialSectionIndex;
      sectionIndex < sectionsResult.sections.length;
      sectionIndex++
    ) {
      final section = sectionsResult.sections[sectionIndex];
      if (section.entries.isEmpty) continue;

      final block = <CalendarHomeWidgetRow>[
        CalendarHomeWidgetRow.header(section.day),
      ];
      var blockHeight = dayHeaderHeight;
      var entriesAdded = 0;

      for (final entry in section.entries) {
        final spacingBefore = block.length > 1 ? rowSpacing : 0;
        final sectionSpacing = fitted.isEmpty ? 0.0 : rowSpacing;
        final nextHeight = spacingBefore + estimatedCardHeight;
        if (heightUsed + sectionSpacing + blockHeight + nextHeight > budget) {
          break;
        }
        blockHeight += nextHeight;
        block.add(CalendarHomeWidgetRow.entry(entry));
        entriesAdded++;
      }

      if (entriesAdded == 0) {
        if (fitted.isNotEmpty) break;
        continue;
      }

      if (fitted.isNotEmpty) {
        heightUsed += rowSpacing;
      }
      heightUsed += blockHeight;
      fitted.addAll(block);

      if (entriesAdded < section.entries.length) {
        break;
      }
    }

    return fitted;
  }

  static SearchResultsSections buildSectionsFromEntries({
    required List<CalendarEntry> entries,
    DateTime? now,
  }) {
    final today = AppDateTime.todayLocal(now: now);
    final upcoming = entries
        .where((entry) => !AppDateTime.localDay(entry.startTime).isBefore(today))
        .toList(growable: false);
    return buildSearchResultsSections(entries: upcoming, now: now);
  }
}

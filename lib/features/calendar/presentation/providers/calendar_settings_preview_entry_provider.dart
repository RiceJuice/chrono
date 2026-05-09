import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;

import '../../domain/preview/calendar_settings_kind.dart';
import '../../domain/preview/calendar_settings_preview_entry.dart';
import '../../domain/models/calendar_entry.dart';
import 'filter/calendar/calendar_filtered_entries_providers.dart';

final calendarSettingsPreviewEntryProvider = fr.Provider.family<
    fr.AsyncValue<CalendarEntry>,
    CalendarSettingsKind
>((ref, kind) {
  final source = ref.watch(filteredCalendarAllEntriesProvider);
  return source.whenData((entries) {
    final picked = pickNextCalendarSettingsPreviewEntry(
      entries: entries,
      kind: kind,
    );
    return picked ?? calendarSettingsPreviewPlaceholder(kind);
  });
});

/// Liefert den nächsten Vorschau-Eintrag für genau einen Akzent-Typ.
final calendarAccentTypePreviewEntryProvider = fr.Provider.family<
    fr.AsyncValue<CalendarEntry>,
    CalendarEntryType
>((ref, type) {
  final source = ref.watch(filteredCalendarAllEntriesProvider);
  return source.whenData((entries) {
    final picked = pickNextCalendarPreviewEntryForType(
      entries: entries,
      type: type,
    );
    return picked ?? calendarPreviewPlaceholderForType(type);
  });
});

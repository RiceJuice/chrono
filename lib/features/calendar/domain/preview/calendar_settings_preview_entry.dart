import '../../../../core/database/backend_enums.dart';
import '../../../../core/time/app_date_time.dart';
import '../../data/calendar_entry_mapper.dart';
import '../models/calendar_entry.dart';
import 'calendar_settings_kind.dart';

/// Welche [CalendarEntryType]s gehören zu einem [CalendarSettingsKind]?
/// Bestimmt, wie viele Vorschau-Seiten der Akzentfarben-Picker erhält.
List<CalendarEntryType> accentTypesForSettingsKind(CalendarSettingsKind kind) {
  return switch (kind) {
    CalendarSettingsKind.choir => const [
        CalendarEntryType.choir,
        CalendarEntryType.event,
      ],
    CalendarSettingsKind.meal => const [CalendarEntryType.meal],
    CalendarSettingsKind.school => const [CalendarEntryType.lesson],
  };
}

CalendarEntry? pickNextCalendarSettingsPreviewEntry({
  required List<CalendarEntry> entries,
  required CalendarSettingsKind kind,
}) {
  final now = AppDateTime.nowLocal();
  bool isUpcoming(CalendarEntry e) =>
      !AppDateTime.isPastInstant(e.startTime, now: now);

  Iterable<CalendarEntry> candidates = switch (kind) {
    CalendarSettingsKind.choir => entries.where(
        (e) =>
            isUpcoming(e) &&
            (e.type == CalendarEntryType.choir ||
                e.type == CalendarEntryType.event),
      ),
    CalendarSettingsKind.meal => entries.where(
        (e) => e.type == CalendarEntryType.meal && isUpcoming(e),
      ),
    CalendarSettingsKind.school => entries.where(
        (e) => e.type == CalendarEntryType.lesson && isUpcoming(e),
      ),
  };

  final list = candidates.toList(growable: false)
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  return list.isEmpty ? null : list.first;
}

/// Wählt den nächstanstehenden Eintrag eines bestimmten [CalendarEntryType]s.
CalendarEntry? pickNextCalendarPreviewEntryForType({
  required List<CalendarEntry> entries,
  required CalendarEntryType type,
}) {
  final now = AppDateTime.nowLocal();
  final list = entries
      .where(
        (e) => e.type == type && !AppDateTime.isPastInstant(e.startTime, now: now),
      )
      .toList(growable: false)
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  return list.isEmpty ? null : list.first;
}

/// Platzhalter-Eintrag, falls für einen [CalendarEntryType] kein Termin
/// existiert.
CalendarEntry calendarPreviewPlaceholderForType(CalendarEntryType type) {
  final now = DateTime.now().toUtc();
  final end = now.add(const Duration(hours: 2));
  final accent = CalendarEntryMapper.defaultAccentColorForType(type);
  return switch (type) {
    CalendarEntryType.choir => CalendarEntry(
        id: 'preview-placeholder-choir',
        eventName: 'Kein bevorstehender Chortermin',
        startTime: now,
        endTime: end,
        accentColor: accent,
        type: type,
      ),
    CalendarEntryType.event => CalendarEntry(
        id: 'preview-placeholder-event',
        eventName: 'Kein bevorstehender Konzerttermin',
        startTime: now,
        endTime: end,
        accentColor: accent,
        type: type,
      ),
    CalendarEntryType.meal => CalendarEntry(
        id: 'preview-placeholder-meal',
        eventName: 'Kein bevorstehender Speiseplan-Termin',
        startTime: now,
        endTime: end,
        accentColor: accent,
        type: type,
        diet: BackendDiet.unknown,
      ),
    CalendarEntryType.lesson => CalendarEntry(
        id: 'preview-placeholder-lesson',
        eventName: 'Keine bevorstehende Schulstunde',
        startTime: now,
        endTime: end,
        accentColor: accent,
        type: type,
      ),
  };
}

/// Minimaler Platzhalter, wenn kein passender Termin existiert.
CalendarEntry calendarSettingsPreviewPlaceholder(CalendarSettingsKind kind) {
  final now = DateTime.now().toUtc();
  final end = now.add(const Duration(hours: 2));
  return switch (kind) {
    CalendarSettingsKind.choir => CalendarEntry(
        id: 'preview-placeholder-choir',
        eventName: 'Kein bevorstehender Chor- oder Konzerttermin',
        startTime: now,
        endTime: end,
        accentColor: CalendarEntryMapper.defaultAccentColorForType(
          CalendarEntryType.choir,
        ),
        type: CalendarEntryType.choir,
      ),
    CalendarSettingsKind.meal => CalendarEntry(
        id: 'preview-placeholder-meal',
        eventName: 'Kein bevorstehender Speiseplan-Termin',
        startTime: now,
        endTime: end,
        accentColor: CalendarEntryMapper.defaultAccentColorForType(
          CalendarEntryType.meal,
        ),
        type: CalendarEntryType.meal,
        diet: BackendDiet.unknown,
      ),
    CalendarSettingsKind.school => CalendarEntry(
        id: 'preview-placeholder-school',
        eventName: 'Keine bevorstehende Schulstunde',
        startTime: now,
        endTime: end,
        accentColor: CalendarEntryMapper.defaultAccentColorForType(
          CalendarEntryType.lesson,
        ),
        type: CalendarEntryType.lesson,
      ),
  };
}

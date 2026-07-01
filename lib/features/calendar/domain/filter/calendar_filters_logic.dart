import '../../../../core/database/backend_enums.dart';
import '../models/calendar_entry.dart';
import 'calendar_filters_state.dart';
import 'calendar_filter_text.dart';
import 'calendar_meal_diet_filter.dart';

bool calendarEntryCountsAsAppointment(CalendarEntry entry) {
  return entry.type != CalendarEntryType.breakType;
}

bool calendarEntryMatchesFilters({
  required CalendarEntry entry,
  required CalendarFiltersState filters,
  required bool hideUnknownWhenFilterActive,
  Set<MealDietSlotKey> mealSlotsWithDietAlternatives = const {},
}) {
  if (!calendarEntryCountsAsAppointment(entry)) {
    return false;
  }

  if (!_isEntryCalendarVisible(entry: entry, filters: filters)) {
    return false;
  }

  if (filters.choirs.isNotEmpty && _isChoirCategoryEntry(entry.type)) {
    final value = normalizeCalendarFilterText(entry.choir.toBackend());
    if (!_matchesCategory(
      selectedValues: filters.choirs,
      entryValue: value,
      isUnknown: entry.choir == BackendChoir.unknown,
      hideUnknownWhenFilterActive: _hideUnknownChoirMetadata(
        entryType: entry.type,
        hideUnknownWhenFilterActive: hideUnknownWhenFilterActive,
      ),
    )) {
      return false;
    }
  }

  if (filters.voices.isNotEmpty && _isChoirCategoryEntry(entry.type)) {
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
    final hideUnknownVoice = _hideUnknownChoirMetadata(
      entryType: entry.type,
      hideUnknownWhenFilterActive: hideUnknownWhenFilterActive,
    );
    if (!hasVoiceMatch && (hideUnknownVoice || values.isNotEmpty)) {
      return false;
    }
  }

  if (filters.classNames.isNotEmpty && _isSchoolCategoryEntry(entry.type)) {
    final value = normalizeCalendarFilterText(entry.className);
    if (!_matchesCategory(
      selectedValues: filters.classNames,
      entryValue: value,
      isUnknown: value == null,
      // Stundenplan-Serien haben oft keine Klasse am Eintrag — nur bei
      // gesetztem Wert ausschließen, nicht bei fehlenden Metadaten.
      hideUnknownWhenFilterActive: false,
    )) {
      return false;
    }
  }

  if (filters.schoolTracks.isNotEmpty && _isSchoolCategoryEntry(entry.type)) {
    final value = normalizeCalendarFilterText(entry.schoolTrack.toBackend());
    if (!_matchesCategory(
      selectedValues: filters.schoolTracks,
      entryValue: value,
      isUnknown: entry.schoolTrack == BackendSchoolTrack.unknown,
      hideUnknownWhenFilterActive: false,
    )) {
      return false;
    }
  }

  if (filters.diets.isNotEmpty && entry.type == CalendarEntryType.meal) {
    final slotHasBothAlternatives = mealSlotsWithDietAlternatives.contains(
      mealDietSlotKey(entry),
    );
    if (slotHasBothAlternatives) {
      final value = normalizeCalendarFilterText(entry.diet.toBackend());
      if (!_matchesCategory(
        selectedValues: filters.diets,
        entryValue: value,
        isUnknown: entry.diet == BackendDiet.unknown,
        hideUnknownWhenFilterActive: false,
      )) {
        return false;
      }
    }
  }

  return true;
}

bool _isChoirCategoryEntry(CalendarEntryType type) {
  return type == CalendarEntryType.choir || type == CalendarEntryType.event;
}

bool _isSchoolCategoryEntry(CalendarEntryType type) {
  return type == CalendarEntryType.lesson;
}

bool _isEntryCalendarVisible({
  required CalendarEntry entry,
  required CalendarFiltersState filters,
}) {
  return switch (entry.type) {
    CalendarEntryType.choir => filters.showChoirCalendar,
    CalendarEntryType.meal => filters.showMealCalendar,
    CalendarEntryType.lesson => filters.showSchoolCalendar,
    CalendarEntryType.event => filters.showChoirCalendar,
    CalendarEntryType.breakType => true,
  };
}

bool calendarEntryVisibleInEventList({
  required CalendarEntry entry,
  required CalendarFiltersState filters,
  required bool hideUnknownWhenFilterActive,
  Set<MealDietSlotKey> mealSlotsWithDietAlternatives = const {},
}) {
  // Ferien/Feiertage sollen in der Event-List immer sichtbar sein.
  if (entry.type == CalendarEntryType.breakType) {
    return true;
  }
  return calendarEntryMatchesFilters(
    entry: entry,
    filters: filters,
    hideUnknownWhenFilterActive: hideUnknownWhenFilterActive,
    mealSlotsWithDietAlternatives: mealSlotsWithDietAlternatives,
  );
}

bool _hideUnknownChoirMetadata({
  required CalendarEntryType entryType,
  required bool hideUnknownWhenFilterActive,
}) {
  // Allgemeine Events ohne Chor-Metadaten sollen sichtbar bleiben;
  // strenge Profilfilter gelten nur für Chor-Termine.
  return hideUnknownWhenFilterActive && entryType == CalendarEntryType.choir;
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

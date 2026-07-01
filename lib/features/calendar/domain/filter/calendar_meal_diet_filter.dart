import '../../../../core/database/backend_enums.dart';
import '../../../../core/time/app_date_time.dart';
import '../meal_period.dart';
import '../models/calendar_entry.dart';

typedef MealDietSlotKey = String;

/// Schlüssel für Tag + Mahlzeit (Mittag/Abend), an dem Diät-Alternativen existieren.
MealDietSlotKey mealDietSlotKey(CalendarEntry entry) {
  final dayNumber = AppDateTime.localCalendarDayNumber(entry.startTime);
  final period = resolveMealPeriod(entry.startTime);
  return '$dayNumber|${period.name}';
}

/// Slots mit mindestens einer vegetarischen und einer fleischhaltigen Alternative.
Set<MealDietSlotKey> collectMealSlotsWithDietAlternatives(
  Iterable<CalendarEntry> entries,
) {
  final vegetarianSlots = <MealDietSlotKey>{};
  final noRestrictionSlots = <MealDietSlotKey>{};

  for (final entry in entries) {
    if (entry.type != CalendarEntryType.meal) {
      continue;
    }
    final slot = mealDietSlotKey(entry);
    switch (entry.diet) {
      case BackendDiet.vegetarian:
        vegetarianSlots.add(slot);
      case BackendDiet.noRestriction:
        noRestrictionSlots.add(slot);
      case BackendDiet.unknown:
        break;
    }
  }

  return vegetarianSlots.intersection(noRestrictionSlots);
}

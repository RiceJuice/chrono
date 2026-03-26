import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show FutureProvider;
import '../../domain/models/calendar_entry.dart';
import '../../domain/repositories/calendar_repository.dart';

// Diese Datei wird generiert: flutter pub run build_runner build
part 'calendar_providers.g.dart';

/// Hält das aktuell ausgewählte Datum.
/// Nutzt 'Notifier', da sich der Zustand durch Nutzerinteraktion ändert.
@riverpod
class SelectedDay extends _$SelectedDay {
  @override
  DateTime build() {
    // Initialisierung mit dem heutigen Datum (ohne Uhrzeit)
    // WICHTIG: .toLocal() verwenden für Zeitzonen-Konsistenz
    final now = DateTime.now().toLocal();
    return DateTime(now.year, now.month, now.day);
  }

  void update(DateTime newDate) {
    // Normalisiere auf lokale Zeit und ohne Uhrzeit
    // Dies stellt sicher, dass Vergleiche mit repository.getEntriesForDay() funktionieren
    final localDay = newDate.toLocal();
    state = DateTime(localDay.year, localDay.month, localDay.day);
  }
}

/// Hält den aktuell fokussierten Tag des Kalenders (z.B. beim Monatswechsel).
@riverpod
class FocusedDay extends _$FocusedDay {
  @override
  DateTime build() {
    final now = DateTime.now().toLocal();
    // Normalisiere auf lokales Datum um Mitternacht
    return DateTime(now.year, now.month, now.day);
  }

  void update(DateTime newDay) {
    final localDay = newDay.toLocal();
    state = DateTime(localDay.year, localDay.month, localDay.day);
  }
}

/// Stellt das Repository bereit.
@riverpod
CalendarRepository calendarRepository(Ref ref) { // <--- Einfach 'Ref' nutzen
  return CalendarRepository();
}

/// Lädt die Einträge basierend auf dem ausgewählten Tag.
@riverpod
Future<List<CalendarEntry>> calendarEntries(Ref ref) async { // <--- Auch hier 'Ref'
  final selectedDay = ref.watch(selectedDayProvider);
  final repository = ref.watch(calendarRepositoryProvider);
  
  return repository.getEntriesForDay(selectedDay);
}

/// Robuster: lädt Einträge für ein explizites Datum (Family-Key = day).
///
/// Das macht die Abhängigkeit im Widget-Baum “sichtbar” und garantiert,
/// dass bei einem neuen `selectedDay` ein neuer Request/Cache-Key genutzt wird.
final calendarEntriesForDayProvider =
    FutureProvider.autoDispose.family<List<CalendarEntry>, DateTime>((ref, day) async {
  final repository = ref.watch(calendarRepositoryProvider);
  return repository.getEntriesForDay(day);
});
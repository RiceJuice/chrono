import '../models/calendar_entry.dart';
import 'calendar_settings_kind.dart';

/// Steuert, ob das Erscheinungsbild-Sheet globale Typ-Farben oder ein Fach bearbeitet.
sealed class CalendarAppearanceConfig {
  const CalendarAppearanceConfig();
}

final class CalendarAppearanceByKind extends CalendarAppearanceConfig {
  const CalendarAppearanceByKind(this.kind);

  final CalendarSettingsKind kind;
}

final class CalendarAppearanceBySubject extends CalendarAppearanceConfig {
  const CalendarAppearanceBySubject({
    required this.subjectId,
    required this.previewEntry,
  });

  final String subjectId;
  final CalendarEntry previewEntry;
}

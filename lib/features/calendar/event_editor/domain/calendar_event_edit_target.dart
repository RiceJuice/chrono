import '../../domain/models/calendar_entry.dart';

enum CalendarEventEditTargetKind {
  standalone,
  seriesInstance,
}

class CalendarEventEditTarget {
  const CalendarEventEditTarget({
    required this.kind,
    required this.sourceEntry,
    this.existingEventRowId,
    this.seriesId,
    this.recurrenceId,
  });

  final CalendarEventEditTargetKind kind;
  final CalendarEntry sourceEntry;

  /// Echte Zeilen-ID in [calendar_events], falls bereits ein Override existiert.
  final String? existingEventRowId;

  final String? seriesId;
  final DateTime? recurrenceId;

  bool get isRecurring => seriesId != null;
}

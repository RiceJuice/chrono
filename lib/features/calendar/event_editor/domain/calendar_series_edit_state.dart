import 'package:rrule/rrule.dart';

/// Bearbeitbare Serien-Metadaten (RRULE + Serienzeitraum).
class CalendarSeriesEditState {
  CalendarSeriesEditState({
    required this.frequency,
    required this.weekdays,
    required this.seriesStart,
    this.seriesEnd,
    this.interval = 1,
  });

  final Frequency frequency;
  final Set<int> weekdays;
  final DateTime seriesStart;
  final DateTime? seriesEnd;
  final int interval;

  CalendarSeriesEditState copyWith({
    Frequency? frequency,
    Set<int>? weekdays,
    DateTime? seriesStart,
    DateTime? seriesEnd,
    bool clearSeriesEnd = false,
    int? interval,
  }) {
    return CalendarSeriesEditState(
      frequency: frequency ?? this.frequency,
      weekdays: weekdays ?? this.weekdays,
      seriesStart: seriesStart ?? this.seriesStart,
      seriesEnd: clearSeriesEnd ? null : (seriesEnd ?? this.seriesEnd),
      interval: interval ?? this.interval,
    );
  }
}

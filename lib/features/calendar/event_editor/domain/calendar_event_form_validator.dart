import 'package:rrule/rrule.dart';

import 'calendar_series_edit_state.dart';

class CalendarEventFormValidationResult {
  const CalendarEventFormValidationResult({this.errorMessage});

  final String? errorMessage;

  bool get isValid => errorMessage == null;
}

class CalendarEventFormValidator {
  CalendarEventFormValidator._();

  static CalendarEventFormValidationResult validate({
    required String eventName,
    required DateTime startTime,
    required DateTime endTime,
    CalendarSeriesEditState? seriesEdit,
  }) {
    if (eventName.trim().isEmpty) {
      return const CalendarEventFormValidationResult(
        errorMessage: 'Bitte einen Terminnamen eingeben.',
      );
    }
    if (!endTime.isAfter(startTime)) {
      return const CalendarEventFormValidationResult(
        errorMessage: 'Die Endzeit muss nach der Startzeit liegen.',
      );
    }

    final series = seriesEdit;
    if (series != null) {
      if (series.frequency == Frequency.weekly && series.weekdays.isEmpty) {
        return const CalendarEventFormValidationResult(
          errorMessage: 'Bitte mindestens einen Wochentag wählen.',
        );
      }
      final end = series.seriesEnd;
      if (end != null && end.isBefore(series.seriesStart)) {
        return const CalendarEventFormValidationResult(
          errorMessage: 'Das Serienende muss nach dem Serienbeginn liegen.',
        );
      }
    }

    return const CalendarEventFormValidationResult();
  }
}

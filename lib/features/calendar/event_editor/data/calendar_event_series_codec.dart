import '../../../../core/time/app_date_time.dart';
import '../domain/calendar_event_form_state.dart';
import '../domain/calendar_series_edit_state.dart';
import 'calendar_event_form_codec.dart';
import 'calendar_event_rrule_codec.dart';

/// Kodiert Serien-Master-Zeilen für [calendar_series] (TIME + DATE + RRULE).
class CalendarEventSeriesCodec {
  CalendarEventSeriesCodec._();

  static Map<String, Object?> toSeriesRow({
    required CalendarEventFormState state,
    required CalendarSeriesEditState series,
  }) {
    final shared = CalendarEventFormCodec.toSeriesSharedFields(state);
    return {
      ...shared,
      'start_time': formatSeriesWallTime(state.startTime),
      'end_time': formatSeriesWallTime(state.endTime),
      'rrule': CalendarEventRruleCodec.toStorageText(series),
      'series_start': formatSeriesDate(series.seriesStart),
      'series_end': series.seriesEnd == null
          ? null
          : formatSeriesDate(series.seriesEnd!),
    };
  }

  /// Lokale Uhrzeit als TIME-String (HH:MM:SS), wie vom Backend erwartet.
  static String formatSeriesWallTime(DateTime utcInstant) {
    final local = utcInstant.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static String formatSeriesDate(DateTime value) {
    final day = AppDateTime.localDay(value);
    final y = day.year.toString().padLeft(4, '0');
    final mo = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$y-$mo-$d';
  }

  static DateTime? parseSeriesDateOrNull(Object? value) {
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return AppDateTime.localDay(DateTime.parse(s));
  }
}

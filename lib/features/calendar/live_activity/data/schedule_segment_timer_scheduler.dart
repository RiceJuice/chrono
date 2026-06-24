import 'dart:async';

/// Plant Einmal-Timer für Segment-Starts und Tagesenden (kein periodisches Polling).
class ScheduleSegmentTimerScheduler {
  final Map<String, Timer> _timers = {};

  void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  void reschedule({
    required List<({String eventId, String scheduleId, DateTime at})> starts,
    required List<({String eventId, DateTime at})> dayEnds,
    required void Function(String eventId) onSegmentStart,
    required void Function(String eventId) onDayEnd,
  }) {
    cancelAll();

    final now = DateTime.now();

    for (final start in starts) {
      if (!start.at.isAfter(now)) continue;
      final key = 'start_${start.eventId}_${start.scheduleId}';
      _timers[key] = Timer(start.at.difference(now), () {
        onSegmentStart(start.eventId);
      });
    }

    for (final end in dayEnds) {
      if (!end.at.isAfter(now)) continue;
      final key = 'end_${end.eventId}';
      if (_timers.containsKey(key)) continue;
      _timers[key] = Timer(end.at.difference(now), () {
        onDayEnd(end.eventId);
      });
    }
  }

  void dispose() {
    cancelAll();
  }
}

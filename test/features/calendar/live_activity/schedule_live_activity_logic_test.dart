import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/calendar/domain/filter/event_schedule_filter.dart';
import 'package:chronoapp/features/calendar/domain/models/event_schedule.dart';
import 'package:chronoapp/features/calendar/live_activity/data/schedule_segment_timer_scheduler.dart';
import 'package:chronoapp/features/calendar/live_activity/domain/schedule_live_activity_event.dart';
import 'package:chronoapp/features/calendar/live_activity/domain/schedule_live_activity_resolver.dart';
import 'package:chronoapp/features/calendar/live_activity/domain/schedule_live_activity_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScheduleLiveActivitySnapshot.remainingMinutesAt', () {
    late ScheduleLiveActivitySnapshot snapshot;

    setUp(() {
      final start = DateTime(2026, 6, 24, 10, 0);
      final end = DateTime(2026, 6, 24, 10, 30);
      snapshot = ScheduleLiveActivitySnapshot(
        eventId: 'event-1',
        customId: 'event_event-1',
        currentScheduleId: 'sched-1',
        currentTitle: 'Probe',
        currentSubtitle: '',
        hasNext: false,
        nextTitle: '',
        nextSubtitle: '',
        segmentStartMs: start.millisecondsSinceEpoch,
        segmentEndMs: end.millisecondsSinceEpoch,
      );
    });

    test('zeigt 30:13 bei 13 Sekunden nach Segmentstart', () {
      expect(
        snapshot.remainingSecondsAt(DateTime(2026, 6, 24, 10, 0, 47)),
        30 * 60 - 47,
      );
      expect(
        snapshot.remainingMinutesAt(DateTime(2026, 6, 24, 10, 0, 47)),
        30,
      );
    });

    test('wechselt sekundengenau auf 29:00 an der Minutengrenze', () {
      expect(
        snapshot.remainingSecondsAt(DateTime(2026, 6, 24, 10, 1, 0)),
        29 * 60,
      );
      expect(
        snapshot.remainingMinutesAt(DateTime(2026, 6, 24, 10, 1, 0)),
        29,
      );
    });

    test('segmentStartMs bleibt am geplanten Start, nicht am Push-Zeitpunkt', () {
      final pushTime = DateTime(2026, 6, 24, 10, 0, 47);
      expect(snapshot.progressAt(pushTime), closeTo(47 / (30 * 60), 0.001));
      expect(snapshot.remainingMinutesAt(pushTime), 30);
    });

    test('contentFingerprint ändert sich bei Titel-Update', () {
      final original = snapshot.contentFingerprint;
      final updated = ScheduleLiveActivitySnapshot(
        eventId: snapshot.eventId,
        customId: snapshot.customId,
        currentScheduleId: snapshot.currentScheduleId,
        currentTitle: 'Neuer Titel',
        currentSubtitle: snapshot.currentSubtitle,
        hasNext: snapshot.hasNext,
        nextTitle: snapshot.nextTitle,
        nextSubtitle: snapshot.nextSubtitle,
        segmentStartMs: snapshot.segmentStartMs,
        segmentEndMs: snapshot.segmentEndMs,
      );
      expect(updated.contentFingerprint, isNot(original));
    });
  });

  group('ScheduleLiveActivityResolver', () {
    const filters = CalendarFiltersState();

    test('segmentEndMs bis zum nächsten Punkt ohne explizite Endzeit', () {
      final aufbauenStart = DateTime(2026, 7, 6, 8, 0);
      final abbauenStart = DateTime(2026, 7, 6, 10, 0);
      final now = DateTime(2026, 7, 6, 8, 30);

      final snapshot = ScheduleLiveActivityResolver.resolve(
        eventId: 'event-1',
        schedules: [
          EventSchedule(
            id: 'sched-1',
            eventId: 'event-1',
            title: 'Aufbauen',
            startTime: aufbauenStart,
          ),
          EventSchedule(
            id: 'sched-2',
            eventId: 'event-1',
            title: 'Abbauen',
            startTime: abbauenStart,
          ),
        ],
        listFilter: EventScheduleListFilter.all,
        filters: filters,
        now: now,
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.currentTitle, 'Aufbauen');
      expect(snapshot.segmentStartMs, aufbauenStart.millisecondsSinceEpoch);
      expect(snapshot.segmentEndMs, abbauenStart.millisecondsSinceEpoch);
      expect(snapshot.hasNext, isTrue);
      expect(snapshot.nextTitle, 'Abbauen');
    });

    test('segmentStartMs und segmentEndMs aus Schedule-Zeiten', () {
      final start = DateTime(2026, 6, 24, 14, 0);
      final end = DateTime(2026, 6, 24, 14, 45);
      final now = DateTime(2026, 6, 24, 14, 10);

      final snapshot = ScheduleLiveActivityResolver.resolve(
        eventId: 'event-1',
        schedules: [
          EventSchedule(
            id: 'sched-1',
            eventId: 'event-1',
            title: 'Einspielen',
            startTime: start,
            endTime: end,
          ),
        ],
        listFilter: EventScheduleListFilter.all,
        filters: filters,
        now: now,
      );

      expect(snapshot, isNotNull);
      expect(
        snapshot!.segmentStartMs,
        start.millisecondsSinceEpoch,
      );
      expect(snapshot.segmentEndMs, end.millisecondsSinceEpoch);
    });

    test('resolveFromEvent für Termin ohne Ablaufplan', () {
      final start = DateTime(2026, 6, 24, 18, 0);
      final end = DateTime(2026, 6, 24, 20, 0);
      final now = DateTime(2026, 6, 24, 18, 30);

      final snapshot = ScheduleLiveActivityResolver.resolveFromEvent(
        event: ScheduleLiveActivityEvent(
          id: 'event-only',
          eventName: 'Sommerfest',
          location: 'Aula',
          startTime: start,
          endTime: end,
        ),
        filters: filters,
        now: now,
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.currentTitle, 'Sommerfest');
      expect(snapshot.currentSubtitle, 'Aula');
      expect(snapshot.hasNext, isFalse);
      expect(snapshot.segmentStartMs, start.millisecondsSinceEpoch);
      expect(snapshot.segmentEndMs, end.millisecondsSinceEpoch);
    });

    test('resolveFromEvent vor Terminstart liefert null', () {
      final start = DateTime(2026, 6, 24, 18, 0);
      final end = DateTime(2026, 6, 24, 20, 0);
      final now = DateTime(2026, 6, 24, 17, 30);

      final snapshot = ScheduleLiveActivityResolver.resolveFromEvent(
        event: ScheduleLiveActivityEvent(
          id: 'event-only',
          eventName: 'Sommerfest',
          startTime: start,
          endTime: end,
        ),
        filters: filters,
        now: now,
      );

      expect(snapshot, isNull);
    });
  });

  group('ScheduleSegmentTimerScheduler', () {
    test('feuert Segment-Start nach geplanter Verzögerung', () async {
      final scheduler = ScheduleSegmentTimerScheduler();
      final started = <String>[];

      scheduler.reschedule(
        starts: [
          (
            eventId: 'event-1',
            scheduleId: 'sched-1',
            at: DateTime.now().add(const Duration(milliseconds: 50)),
          ),
        ],
        dayEnds: const [],
        onSegmentStart: started.add,
        onDayEnd: (_) {},
      );

      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(started, ['event-1']);
      scheduler.dispose();
    });

    test('feuert Tagesende', () async {
      final scheduler = ScheduleSegmentTimerScheduler();
      final ended = <String>[];

      scheduler.reschedule(
        starts: const [],
        dayEnds: [
          (
            eventId: 'event-2',
            at: DateTime.now().add(const Duration(milliseconds: 50)),
          ),
        ],
        onSegmentStart: (_) {},
        onDayEnd: ended.add,
      );

      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(ended, ['event-2']);
      scheduler.dispose();
    });

    test('cancelAll verhindert ausstehende Timer', () async {
      final scheduler = ScheduleSegmentTimerScheduler();
      final started = <String>[];

      scheduler.reschedule(
        starts: [
          (
            eventId: 'event-1',
            scheduleId: 'sched-1',
            at: DateTime.now().add(const Duration(milliseconds: 80)),
          ),
        ],
        dayEnds: const [],
        onSegmentStart: started.add,
        onDayEnd: (_) {},
      );

      scheduler.cancelAll();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(started, isEmpty);
      scheduler.dispose();
    });
  });
}

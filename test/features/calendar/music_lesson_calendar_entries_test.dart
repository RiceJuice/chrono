import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/domain/music_lesson_calendar_entries.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/music_lessons/domain/music_lesson_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'weekly lessons skip school breaks and keep Berlin time through DST',
    () {
      final schedule = MusicLessonSchedule.fromRow({
        'starts_on': '2026-03-19',
        'voice_weekday': 5,
        'voice_start_minute': 14 * 60,
        'voice_additum': true,
        'voice_teacher': 'Frau Beispiel',
        'instrument_weekday': 5,
        'instrument_start_minute': 15 * 60,
        'instrument_name': 'Klavier',
        'instrument_double': false,
      });

      final entries = musicLessonCalendarEntries(
        schedule,
        startUtc: DateTime.utc(2026, 3, 1),
        endExclusiveUtc: DateTime.utc(2026, 4, 10),
        freeDays: {AppDateTime.localDay(DateTime.utc(2026, 4, 3, 12))},
      ).toList();

      expect(entries.map((entry) => entry.startTime), [
        DateTime.utc(2026, 3, 20, 13),
        DateTime.utc(2026, 3, 27, 13),
        DateTime.utc(2026, 3, 20, 14),
        DateTime.utc(2026, 3, 27, 14),
      ]);
      expect(
        entries.every((entry) => entry.type == CalendarEntryType.lesson),
        isTrue,
      );
      expect(entries.first.description, 'Lehrkraft: Frau Beispiel');
      expect(
        entries.first.endTime.difference(entries.first.startTime).inMinutes,
        45,
      );
      expect(entries.last.eventName, 'Klavier');
      expect(entries.map((entry) => entry.accentPreferenceKey), [
        'music-lesson:voice',
        'music-lesson:voice',
        'music-lesson:instrument',
        'music-lesson:instrument',
      ]);
      expect(entries.every((entry) => entry.subjectId == null), isTrue);
      expect(
        entries.last.endTime.difference(entries.last.startTime).inMinutes,
        25,
      );

      final afterDst = musicLessonCalendarEntries(
        schedule,
        startUtc: DateTime.utc(2026, 4, 10),
        endExclusiveUtc: DateTime.utc(2026, 4, 11),
        freeDays: {},
      );
      expect(afterDst.first.startTime, DateTime.utc(2026, 4, 10, 12));
      expect(
        afterDst.first.accentPreferenceKey,
        entries.first.accentPreferenceKey,
      );
    },
  );
}

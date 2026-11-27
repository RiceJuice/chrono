enum MusicLessonKind {
  voice(15),
  instrument(25);

  const MusicLessonKind(this.standardMinutes);
  final int standardMinutes;
}

class MusicLesson {
  const MusicLesson({
    required this.kind,
    required this.weekday,
    required this.startMinute,
    this.extended = false,
    this.teacher,
    this.instrument,
  });

  final MusicLessonKind kind;
  final int weekday;
  final int startMinute;
  final bool extended;
  final String? teacher;
  final String? instrument;

  int get durationMinutes => extended ? 45 : kind.standardMinutes;

  String get title => switch (kind) {
    MusicLessonKind.voice => 'Stimmbildung',
    MusicLessonKind.instrument => instrument!,
  };
}

/// One row per student. An empty row means they chose to skip the step.
class MusicLessonSchedule {
  const MusicLessonSchedule({
    required this.startsOn,
    this.voice,
    this.instrument,
  });

  factory MusicLessonSchedule.fromRow(Map<String, dynamic> row) {
    MusicLesson? readLesson(
      MusicLessonKind kind,
      String prefix,
      String lengthKey,
    ) {
      final weekday = row['${prefix}_weekday'] as int?;
      if (weekday == null) return null;
      return MusicLesson(
        kind: kind,
        weekday: weekday,
        startMinute: row['${prefix}_start_minute'] as int,
        extended: row[lengthKey] as bool,
        teacher: row['${prefix}_teacher'] as String?,
        instrument: kind == MusicLessonKind.instrument
            ? row['instrument_name'] as String?
            : null,
      );
    }

    return MusicLessonSchedule(
      startsOn: DateTime.parse('${row['starts_on']}T00:00:00Z'),
      voice: readLesson(MusicLessonKind.voice, 'voice', 'voice_additum'),
      instrument: readLesson(
        MusicLessonKind.instrument,
        'instrument',
        'instrument_double',
      ),
    );
  }

  final DateTime startsOn;
  final MusicLesson? voice;
  final MusicLesson? instrument;

  List<MusicLesson> get lessons => [?voice, ?instrument];
}

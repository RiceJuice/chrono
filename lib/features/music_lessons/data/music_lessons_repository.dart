import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/music_lesson_schedule.dart';

class MusicLessonsRepository {
  const MusicLessonsRepository(this._client);

  final SupabaseClient _client;
  static const table = 'student_music_lessons';
  static const _cachePrefix = 'student_music_lessons_';

  Future<MusicLessonSchedule> save({
    MusicLesson? voice,
    MusicLesson? instrument,
  }) => _saveColumns({
    ..._lessonColumns(MusicLessonKind.voice, voice),
    ..._lessonColumns(MusicLessonKind.instrument, instrument),
  });

  Future<MusicLessonSchedule> saveLesson(
    MusicLessonKind kind,
    MusicLesson? lesson,
  ) => _saveColumns(_lessonColumns(kind, lesson));

  static Map<String, dynamic> _lessonColumns(
    MusicLessonKind kind,
    MusicLesson? lesson,
  ) => switch (kind) {
    MusicLessonKind.voice => {
      'voice_weekday': lesson?.weekday,
      'voice_start_minute': lesson?.startMinute,
      'voice_teacher': lesson?.teacher,
      'voice_additum': lesson?.extended ?? false,
    },
    MusicLessonKind.instrument => {
      'instrument_weekday': lesson?.weekday,
      'instrument_start_minute': lesson?.startMinute,
      'instrument_teacher': lesson?.teacher,
      'instrument_name': lesson?.instrument,
      'instrument_double': lesson?.extended ?? false,
    },
  };

  Future<MusicLessonSchedule> _saveColumns(Map<String, dynamic> columns) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final row = await _client
        .from(table)
        .upsert({'profile_id': user.id, ...columns}, defaultToNull: false)
        .select()
        .single();
    await cache(user.id, row);
    return MusicLessonSchedule.fromRow(row);
  }

  static Future<void> cache(String userId, Map<String, dynamic>? row) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cachePrefix$userId';
    if (row == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, jsonEncode(row));
    }
  }

  static Future<MusicLessonSchedule?> loadCached(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_cachePrefix$userId');
    if (raw == null) return null;
    return MusicLessonSchedule.fromRow(jsonDecode(raw) as Map<String, dynamic>);
  }
}

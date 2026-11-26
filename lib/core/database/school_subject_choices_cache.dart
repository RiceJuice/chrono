import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'school_subject_choices.dart';

/// Retains the server's subject choices offline, including when an older
/// PowerSync deployment does not yet send these profile columns.
class SchoolSubjectChoicesCache {
  static const _prefix = 'profile_school_subject_choices_';

  static Future<void> save(String userId, Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$userId',
      jsonEncode({
        for (final key in [
          'class_name',
          'schooltrack',
          'arts_subject',
          'language_subject',
          'timetable_subject_choices',
        ])
          key: profile[key],
      }),
    );
  }

  static Future<Map<String, dynamic>> supplement(
    String userId,
    Map<String, dynamic> local,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = decodeSchoolSubjectChoices(
      prefs.getString('$_prefix$userId'),
    );
    String normalized(Object? value) =>
        (value?.toString() ?? '').trim().toLowerCase();
    if (normalized(local['class_name']) != normalized(cached['class_name']) ||
        normalized(local['schooltrack']) != normalized(cached['schooltrack'])) {
      return local;
    }
    return {
      ...local,
      'arts_subject': local['arts_subject'] ?? cached['arts_subject'],
      'language_subject':
          local['language_subject'] ?? cached['language_subject'],
      'timetable_subject_choices':
          decodeSchoolSubjectChoices(
            local['timetable_subject_choices'],
          ).isNotEmpty
          ? local['timetable_subject_choices']
          : cached['timetable_subject_choices'],
    };
  }
}

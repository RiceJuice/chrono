import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';

typedef _LessonNameRule = ({bool Function(String lower) matches, String short});

const _lessonWeekGridNameRules = <_LessonNameRule>[
  (matches: _isMathematik, short: 'Mathe'),
  (matches: _isWirtschaftUndRecht, short: 'WuR'),
  (matches: _isPolitikUndGesellschaft, short: 'PuG'),
  (matches: _isGeo, short: 'Geo'),
];

bool _isMathematik(String lower) => lower == 'mathematik';

bool _isWirtschaftUndRecht(String lower) =>
    lower == 'wirtschaft und recht' || lower == 'wirtschaft u. recht';

bool _isPolitikUndGesellschaft(String lower) =>
    lower == 'politik und gesellschaft' || lower == 'politik u. gesellschaft';

bool _isGeo(String lower) =>
    lower == 'erdkunde' || lower == 'geographie' || lower == 'geo';

String lessonWeekGridDisplayName(String eventName) {
  final trimmed = eventName.trim();
  if (trimmed.isEmpty) return trimmed;

  final lower = trimmed.toLowerCase();
  for (final rule in _lessonWeekGridNameRules) {
    if (rule.matches(lower)) return rule.short;
  }
  return trimmed;
}

String calendarEntryCardTitle(CalendarEntry entry, {required bool compact}) {
  if (!compact || entry.type != CalendarEntryType.lesson) {
    return entry.eventName;
  }
  return lessonWeekGridDisplayName(entry.eventName);
}

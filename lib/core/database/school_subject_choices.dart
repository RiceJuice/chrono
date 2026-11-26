import 'dart:convert';
import 'arts_subject.dart';

Map<String, dynamic> decodeSchoolSubjectChoices(Object? raw) {
  if (raw is String) {
    try {
      raw = jsonDecode(raw);
    } catch (_) {
      return {};
    }
  }
  return raw is Map ? Map<String, dynamic>.from(raw) : {};
}

String _normalize(Object? value) =>
    (value?.toString() ?? '').trim().toLowerCase();

/// Legacy fields and timetable-derived answers must describe the same choice.
Map<String, dynamic> updateSchoolSubjectChoices({
  required Map<String, dynamic> existing,
  required String? className,
  required String? schoolTrack,
  String? languageSubject,
  String? artsSubject,
}) {
  return existing.map((key, value) {
    if (value is! Map ||
        _normalize(value['class_name']) != _normalize(className) ||
        _normalize(value['schooltrack']) != _normalize(schoolTrack)) {
      return MapEntry(key, value);
    }
    final options =
        (value['subjects'] is List ? value['subjects'] as List : const [])
            .map(_normalize)
            .toSet();
    final selected =
        languageSubject != null &&
            languageSubjectOptions.map(_normalize).every(options.contains)
        ? languageSubject
        : artsSubject != null &&
              artsSubjectOptions.map(_normalize).every(options.contains)
        ? artsSubject
        : null;
    return MapEntry(
      key,
      selected == null ? value : {...value, 'selected': selected},
    );
  });
}

String? savedSchoolSubjectChoice({
  required List<String> options,
  required String? legacy,
  required Map<String, dynamic> choices,
  required String? className,
  required String? schoolTrack,
  required DateTime at,
}) {
  for (final value in choices.values) {
    if (!schoolSubjectAnswerApplies(value, className, schoolTrack, at)) {
      continue;
    }
    final subjects = (value['subjects'] as List).map(_normalize).toSet();
    if (!options.map(_normalize).every(subjects.contains)) continue;
    for (final option in options) {
      if (_normalize(value['selected']) == _normalize(option)) return option;
    }
  }
  return options.contains(legacy) ? legacy : null;
}

bool schoolSubjectAnswerApplies(
  Object? raw,
  String? className,
  String? schoolTrack,
  DateTime at,
) {
  if (raw is! Map ||
      raw['subjects'] is! List ||
      raw['selected'] is! String ||
      _normalize(raw['class_name']) != _normalize(className) ||
      _normalize(raw['schooltrack']) != _normalize(schoolTrack)) {
    return false;
  }
  final options = (raw['subjects'] as List).map(_normalize);
  if (!options.contains(_normalize(raw['selected']))) return false;
  final start = DateTime.tryParse(raw['period_start']?.toString() ?? '');
  final end = DateTime.tryParse(raw['period_end']?.toString() ?? '');
  return start != null &&
      end != null &&
      !at.isBefore(start) &&
      at.isBefore(end);
}

/// Die Wahl betrifft nur NTG ab Jahrgangsstufe 11 (auch Klassen wie Q12).
bool requiresArtsSubject(String? className, String? schoolTrack) {
  final match = RegExp(
    r'^(?:q\s*)?(\d{1,2})(?:[a-z])?$',
  ).firstMatch((className ?? '').trim().toLowerCase());
  final grade = int.tryParse(match?.group(1) ?? '');
  return schoolTrack?.trim().toLowerCase() == 'ntg' &&
      grade != null &&
      grade >= 11;
}

const artsSubjectOptions = ['Kunst', 'Musik'];

bool hasValidArtsSubject(String? value) => artsSubjectOptions.contains(value);

/// In Jahrgangsstufe 11 ist eine zweite Fremdsprache verpflichtend.
bool requiresLanguageSubject(String? className) {
  final match = RegExp(
    r'^(?:q\s*)?(\d{1,2})(?:[a-z])?$',
  ).firstMatch((className ?? '').trim().toLowerCase());
  return int.tryParse(match?.group(1) ?? '') == 11;
}

const languageSubjectOptions = ['Latein', 'Französisch'];
bool hasValidLanguageSubject(String? value) =>
    languageSubjectOptions.contains(value);

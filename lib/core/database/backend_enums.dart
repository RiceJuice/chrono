enum CalendarEventType { lesson, event, meal, choir, unknown }

enum BackendChoir { dkm, raedlinger, giehl, szuczies, schola, unknown }

enum BackendVoice { sopran, alt, tenor, bass, unknown }

enum BackendSchoolTrack { ntg, musisch, unknown }

/// Entspricht dem Postgres-Enum `diet` (Anzeige = gespeicherter Wert).
enum BackendDiet { vegetarian, noRestriction, unknown }

extension CalendarEventTypeCodec on CalendarEventType {
  static CalendarEventType fromBackend(String? raw) {
    final value = _normalize(raw);
    return switch (value) {
      'lesson' => CalendarEventType.lesson,
      // Legacy-Tippfehler aus älteren DB-Ständen.
      'lession' => CalendarEventType.lesson,
      'event' => CalendarEventType.event,
      'meal' => CalendarEventType.meal,
      'choir' => CalendarEventType.choir,
      // Legacy-Schreibweise aus altem App-Enum.
      'chor' => CalendarEventType.choir,
      _ => CalendarEventType.unknown,
    };
  }

  String? toBackend() {
    return switch (this) {
      CalendarEventType.lesson => 'lesson',
      CalendarEventType.event => 'event',
      CalendarEventType.meal => 'meal',
      CalendarEventType.choir => 'choir',
      CalendarEventType.unknown => null,
    };
  }
}

extension BackendChoirCodec on BackendChoir {
  static BackendChoir fromBackend(String? raw) {
    final value = _normalize(raw);
    return switch (value) {
      'dkm' => BackendChoir.dkm,
      'raedlinger' || 'rädlinger' => BackendChoir.raedlinger,
      'giehl' => BackendChoir.giehl,
      'szuczies' => BackendChoir.szuczies,
      'schola' => BackendChoir.schola,
      _ => BackendChoir.unknown,
    };
  }

  String? toBackend() {
    return switch (this) {
      BackendChoir.dkm => 'DKM',
      BackendChoir.raedlinger => 'Rädlinger',
      BackendChoir.giehl => 'Giehl',
      BackendChoir.szuczies => 'Szuczies',
      BackendChoir.schola => 'Schola',
      BackendChoir.unknown => null,
    };
  }
}

extension BackendVoiceCodec on BackendVoice {
  static BackendVoice fromBackend(String? raw) {
    final value = _normalize(raw);
    return switch (value) {
      'sopran' => BackendVoice.sopran,
      'alt' => BackendVoice.alt,
      'tenor' => BackendVoice.tenor,
      'bass' => BackendVoice.bass,
      _ => BackendVoice.unknown,
    };
  }

  String? toBackend() {
    return switch (this) {
      BackendVoice.sopran => 'Sopran',
      BackendVoice.alt => 'Alt',
      BackendVoice.tenor => 'Tenor',
      BackendVoice.bass => 'Bass',
      BackendVoice.unknown => null,
    };
  }
}

extension BackendSchoolTrackCodec on BackendSchoolTrack {
  static BackendSchoolTrack fromBackend(String? raw) {
    final value = _normalize(raw);
    return switch (value) {
      'ntg' => BackendSchoolTrack.ntg,
      'musisch' => BackendSchoolTrack.musisch,
      _ => BackendSchoolTrack.unknown,
    };
  }

  String? toBackend() {
    return switch (this) {
      BackendSchoolTrack.ntg => 'NTG',
      BackendSchoolTrack.musisch => 'Musisch',
      BackendSchoolTrack.unknown => null,
    };
  }
}

extension BackendDietCodec on BackendDiet {
  static BackendDiet fromBackend(String? raw) {
    final value = _normalize(raw);
    return switch (value) {
      'vegetarisch' || 'vegetarian' => BackendDiet.vegetarian,
      'keine einschränkung' ||
      'keine einschraenkung' ||
      'omnivore' ||
      'alles' =>
        BackendDiet.noRestriction,
      _ => BackendDiet.unknown,
    };
  }

  String? toBackend() {
    return switch (this) {
      BackendDiet.vegetarian => 'Vegetarisch',
      BackendDiet.noRestriction => 'Keine Einschränkung',
      BackendDiet.unknown => null,
    };
  }
}

extension BackendChoirLabel on BackendChoir {
  String get displayLabel {
    return switch (this) {
      BackendChoir.dkm => 'DKM',
      BackendChoir.raedlinger => 'Rädlinger',
      BackendChoir.giehl => 'Giehl',
      BackendChoir.szuczies => 'Szuczies',
      BackendChoir.schola => 'Schola',
      BackendChoir.unknown => 'Unbekannt',
    };
  }
}

extension BackendVoiceLabel on BackendVoice {
  String get displayLabel {
    return switch (this) {
      BackendVoice.sopran => 'Sopran',
      BackendVoice.alt => 'Alt',
      BackendVoice.tenor => 'Tenor',
      BackendVoice.bass => 'Bass',
      BackendVoice.unknown => 'Unbekannt',
    };
  }
}

extension BackendSchoolTrackLabel on BackendSchoolTrack {
  String get displayLabel {
    return switch (this) {
      BackendSchoolTrack.ntg => 'NTG',
      BackendSchoolTrack.musisch => 'Musisch',
      BackendSchoolTrack.unknown => 'Unbekannt',
    };
  }
}

extension BackendDietLabel on BackendDiet {
  String get displayLabel {
    return switch (this) {
      BackendDiet.vegetarian => 'Vegetarisch',
      BackendDiet.noRestriction => 'Keine Einschränkung',
      BackendDiet.unknown => 'Unbekannt',
    };
  }
}

String _normalize(String? raw) {
  if (raw == null) return '';
  var trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  // Wrapper aus Postgres/Serialisierung entfernen, z. B. "{NTG}" oder "[NTG]".
  while ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
      (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
    trimmed = trimmed.substring(1, trimmed.length - 1).trim();
    if (trimmed.isEmpty) return '';
  }
  // Falls ein Einzelelement als CSV o. ä. serialisiert wurde, erstes Token nutzen.
  if (trimmed.contains(',')) {
    trimmed = trimmed
        .split(',')
        .map((part) => part.trim())
        .firstWhere((part) => part.isNotEmpty, orElse: () => '');
    if (trimmed.isEmpty) return '';
  }
  // Support für Werte wie "CalendarEntryType.lesson" oder "public.type.lesson".
  if (trimmed.contains('.')) {
    trimmed = trimmed.split('.').last;
  }
  // Quotes aus serialisierten/geloggten Werten entfernen.
  trimmed = trimmed.replaceAll('"', '').replaceAll("'", '');
  return trimmed.toLowerCase();
}

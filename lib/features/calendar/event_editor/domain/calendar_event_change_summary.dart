import 'package:intl/intl.dart';
import 'package:rrule/rrule.dart';

import '../../../../core/database/backend_enums.dart';
import '../../domain/models/calendar_entry.dart';
import 'calendar_event_audience_snapshot.dart';
import 'calendar_event_form_state.dart';
import 'calendar_series_edit_state.dart';

/// Eine erkannte Feldänderung für Push und Dialog.
class CalendarEventChange {
  const CalendarEventChange({
    required this.label,
    required this.oldValue,
    required this.newValue,
  });

  final String label;
  final String oldValue;
  final String newValue;

  String get displayLine => '$label: $oldValue → $newValue';

  Map<String, dynamic> toJson() => {
        'label': label,
        'old': oldValue,
        'new': newValue,
      };
}

/// Diff zwischen Formular-Zustand vor und nach der Bearbeitung.
class CalendarEventChangeSummary {
  CalendarEventChangeSummary({
    required this.changes,
    required this.audienceBefore,
    required this.audienceAfter,
    required this.eventName,
    required this.eventType,
  });

  final List<CalendarEventChange> changes;
  final CalendarEventAudienceSnapshot audienceBefore;
  final CalendarEventAudienceSnapshot audienceAfter;
  final String eventName;
  final CalendarEntryType eventType;

  bool get hasChanges =>
      changes.isNotEmpty || !audienceBefore.sameAs(audienceAfter);

  bool get audienceChanged => !audienceBefore.sameAs(audienceAfter);

  List<String> get previewLines =>
      changes.map((c) => c.displayLine).toList(growable: false);

  Map<String, dynamic> toRequestBody({required String eventId}) {
    return {
      'event_id': eventId,
      'event_name': eventName,
      'event_type': _eventTypeToBackend(eventType),
      'audience_before': audienceBefore.toJson(),
      'audience_after': audienceAfter.toJson(),
      'changes': changes.map((c) => c.toJson()).toList(),
    };
  }

  static CalendarEventChangeSummary fromStates({
    required CalendarEventFormState before,
    required CalendarEventFormState after,
  }) {
    final diff = <CalendarEventChange>[];

    void addIfChanged(
      String label,
      String oldValue,
      String newValue, {
      bool force = false,
    }) {
      if (force || oldValue != newValue) {
        diff.add(
          CalendarEventChange(
            label: label,
            oldValue: oldValue,
            newValue: newValue,
          ),
        );
      }
    }

    addIfChanged('Name', before.eventName.trim(), after.eventName.trim());
    addIfChanged(
      'Art',
      _typeLabel(before.type),
      _typeLabel(after.type),
    );
    addIfChanged(
      'Beginn',
      _formatDateTime(before.startTime),
      _formatDateTime(after.startTime),
    );
    addIfChanged(
      'Ende',
      _formatDateTime(before.endTime),
      _formatDateTime(after.endTime),
    );
    addIfChanged('Ort', before.location.trim(), after.location.trim());

    if (before.description.trim() != after.description.trim()) {
      addIfChanged('Beschreibung', '—', 'geändert', force: true);
    }
    if (before.note.trim() != after.note.trim()) {
      addIfChanged('Notiz', '—', 'geändert', force: true);
    }

    addIfChanged(
      'Chor',
      _choirLabel(before.choir),
      _choirLabel(after.choir),
    );
    addIfChanged(
      'Stimmen',
      _voicesLabel(before.voices),
      _voicesLabel(after.voices),
    );
    addIfChanged(
      'Schulzweig',
      before.schoolTrack.displayLabel,
      after.schoolTrack.displayLabel,
    );
    addIfChanged(
      'Klasse',
      before.className?.trim() ?? '—',
      after.className?.trim() ?? '—',
    );
    addIfChanged(
      'Ernährung',
      before.diet.displayLabel,
      after.diet.displayLabel,
    );

    if (before.subjectId != after.subjectId) {
      addIfChanged(
        'Fach',
        before.subjectId?.trim() ?? '—',
        after.subjectId?.trim() ?? '—',
      );
    }

    _addSeriesChanges(diff, before.seriesEdit, after.seriesEdit);

    return CalendarEventChangeSummary(
      changes: diff,
      audienceBefore: CalendarEventAudienceSnapshot.fromFormState(before),
      audienceAfter: CalendarEventAudienceSnapshot.fromFormState(after),
      eventName: after.eventName.trim().isNotEmpty
          ? after.eventName.trim()
          : before.eventName.trim(),
      eventType: after.type,
    );
  }

  static void _addSeriesChanges(
    List<CalendarEventChange> diff,
    CalendarSeriesEditState? before,
    CalendarSeriesEditState? after,
  ) {
    if (before == null && after == null) return;
    if (before == null || after == null) {
      diff.add(
        CalendarEventChange(
          label: 'Wiederholung',
          oldValue: before == null ? '—' : _seriesLabel(before),
          newValue: after == null ? '—' : _seriesLabel(after),
        ),
      );
      return;
    }

    if (before.frequency != after.frequency ||
        before.interval != after.interval ||
        before.seriesStart != after.seriesStart ||
        before.seriesEnd != after.seriesEnd ||
        !_setEquals(before.weekdays, after.weekdays)) {
      diff.add(
        CalendarEventChange(
          label: 'Wiederholung',
          oldValue: _seriesLabel(before),
          newValue: _seriesLabel(after),
        ),
      );
    }
  }

  static String _formatDateTime(DateTime value) {
    return DateFormat('dd.MM.yyyy HH:mm', 'de').format(value.toLocal());
  }

  static String _typeLabel(CalendarEntryType type) {
    return switch (type) {
      CalendarEntryType.lesson => 'Stunde',
      CalendarEntryType.meal => 'Essen',
      CalendarEntryType.event => 'Event',
      CalendarEntryType.choir => 'Chor',
      CalendarEntryType.breakType => 'Ferien/Feiertag',
    };
  }

  static String _eventTypeToBackend(CalendarEntryType type) {
    return switch (type) {
      CalendarEntryType.lesson => 'lesson',
      CalendarEntryType.meal => 'meal',
      CalendarEntryType.event => 'event',
      CalendarEntryType.choir => 'choir',
      CalendarEntryType.breakType => 'break',
    };
  }

  static String _choirLabel(BackendChoir choir) {
    return choir == BackendChoir.unknown ? '—' : choir.displayLabel;
  }

  static String _voicesLabel(List<BackendVoice> voices) {
    final labels = voices
        .where((v) => v != BackendVoice.unknown)
        .map((v) => v.displayLabel)
        .toList();
    if (labels.isEmpty) return '—';
    return labels.join(', ');
  }

  static String _seriesLabel(CalendarSeriesEditState series) {
    final freq = switch (series.frequency) {
      Frequency.daily => 'Täglich',
      Frequency.weekly => 'Wöchentlich',
      Frequency.monthly => 'Monatlich',
      _ => 'Wiederholung',
    };
    final parts = <String>[freq];
    if (series.interval > 1) {
      parts.add('alle ${series.interval}');
    }
    if (series.frequency == Frequency.weekly && series.weekdays.isNotEmpty) {
      parts.add(_weekdaySelection(series.weekdays));
    }
    parts.add(
      'ab ${DateFormat('dd.MM.yyyy', 'de').format(series.seriesStart.toLocal())}',
    );
    if (series.seriesEnd != null) {
      parts.add(
        'bis ${DateFormat('dd.MM.yyyy', 'de').format(series.seriesEnd!.toLocal())}',
      );
    }
    return parts.join(', ');
  }

  static String _weekdaySelection(Set<int> weekdays) {
    const labels = <int, String>{
      DateTime.monday: 'Mo',
      DateTime.tuesday: 'Di',
      DateTime.wednesday: 'Mi',
      DateTime.thursday: 'Do',
      DateTime.friday: 'Fr',
      DateTime.saturday: 'Sa',
      DateTime.sunday: 'So',
    };
    final sorted = weekdays.toList()..sort();
    return sorted.map((d) => labels[d] ?? '$d').join(', ');
  }

  static bool _setEquals(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }
}

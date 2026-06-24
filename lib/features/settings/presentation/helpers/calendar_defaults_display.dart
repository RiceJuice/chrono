import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_settings_filter_widgets.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_profile_display.dart';

/// Anzeige-Werte für Kalender-Standardwerte in den Einstellungen.
class CalendarDefaultsDisplay {
  const CalendarDefaultsDisplay({
    this.choir,
    this.voice,
    this.className,
    this.schoolTrack,
    this.diet,
  });

  final String? choir;
  final String? voice;
  final String? className;
  final String? schoolTrack;
  final String? diet;
}

String? _nonEmpty(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

String? _firstFilterLabel(
  List<String> values,
  String Function(String) labelFor,
) {
  if (values.isEmpty) return null;
  return labelFor(values.first);
}

/// Profil, Gate und aktive Kalender-Filter-Defaults zu Anzeige-Strings.
CalendarDefaultsDisplay resolveCalendarDefaultsDisplay({
  ProfileSnapshot? profile,
  ProfileGateData? gate,
  required CalendarFiltersState filters,
}) {
  return CalendarDefaultsDisplay(
    choir: choirDisplayLabel(profile?.choir) ??
        choirDisplayLabel(gate?.choir) ??
        _firstFilterLabel(filters.defaultChoirs, calendarFilterChoirLabel),
    voice: _nonEmpty(profile?.voice) ??
        _nonEmpty(gate?.voice) ??
        _firstFilterLabel(filters.defaultVoices, calendarFilterVoiceLabel),
    className: _nonEmpty(profile?.className) ??
        _nonEmpty(gate?.className) ??
        _firstFilterLabel(filters.defaultClassNames, calendarFilterClassLabel),
    schoolTrack: schoolTrackDisplayLabel(profile?.schoolTrack) ??
        schoolTrackDisplayLabel(gate?.schoolTrack) ??
        _firstFilterLabel(
          filters.defaultSchoolTracks,
          calendarFilterSchoolTrackLabel,
        ),
    diet: dietDisplayLabel(profile?.diet) ??
        _firstFilterLabel(filters.defaultDiets, calendarFilterDietLabel),
  );
}

/// Rohwerte für Bearbeitungs-Sheets (Profil bevorzugt, sonst Filter-Default).
CalendarDefaultsDisplay resolveCalendarDefaultsEditValues({
  ProfileSnapshot? profile,
  ProfileGateData? gate,
  required CalendarFiltersState filters,
}) {
  return CalendarDefaultsDisplay(
    choir: _nonEmpty(profile?.choir) ??
        _nonEmpty(gate?.choir) ??
        (filters.defaultChoirs.isEmpty ? null : filters.defaultChoirs.first),
    voice: _nonEmpty(profile?.voice) ??
        _nonEmpty(gate?.voice) ??
        (filters.defaultVoices.isEmpty ? null : filters.defaultVoices.first),
    className: _nonEmpty(profile?.className) ??
        _nonEmpty(gate?.className) ??
        (filters.defaultClassNames.isEmpty
            ? null
            : filters.defaultClassNames.first),
    schoolTrack: _nonEmpty(profile?.schoolTrack) ??
        _nonEmpty(gate?.schoolTrack) ??
        (filters.defaultSchoolTracks.isEmpty
            ? null
            : filters.defaultSchoolTracks.first),
    diet: _nonEmpty(profile?.diet) ??
        (filters.defaultDiets.isEmpty ? null : filters.defaultDiets.first),
  );
}

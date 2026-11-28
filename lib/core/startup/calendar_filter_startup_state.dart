import 'package:chronoapp/features/calendar/domain/filter/calendar_filter_defaults.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';

/// Vorberechneter Kalender-Filter vor dem Verlassen des Ladescreens.
class CalendarFilterStartupState {
  CalendarFilterStartupState._();

  static CalendarFiltersState? _bootstrapped;

  static void preload({
    required ProfileGateData gateData,
    String? diet,
    ProfileSnapshot? childProfile,
  }) {
    if (!gateData.hasSession) return;

    if (gateData.role == 'Elternteil' || gateData.hasConfirmedGuardianLink) {
      if (childProfile == null) {
        _bootstrapped = calendarFiltersStateFromProfileFields();
        return;
      }
      _bootstrapped = calendarFiltersStateFromProfileFields(
        choir: childProfile.choir,
        voice: childProfile.voice,
        className: childProfile.className,
        schoolTrack: childProfile.schoolTrack,
        diet: childProfile.diet,
        artsSubject: childProfile.artsSubject,
        languageSubject: childProfile.languageSubject,
        timetableChoices: childProfile.timetableChoices,
      );
      return;
    }

    _bootstrapped = calendarFiltersStateFromProfileFields(
      choir: gateData.choir,
      voice: gateData.voice,
      className: gateData.className,
      schoolTrack: gateData.schoolTrack,
      diet: diet,
      artsSubject: gateData.artsSubject,
      languageSubject: gateData.languageSubject,
      timetableChoices: gateData.timetableChoices,
    );
  }

  static CalendarFiltersState? consume() {
    final bootstrapped = _bootstrapped;
    _bootstrapped = null;
    return bootstrapped;
  }

  static void reset() {
    _bootstrapped = null;
  }
}

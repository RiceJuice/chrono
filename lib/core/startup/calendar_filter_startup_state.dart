import 'package:chronoapp/features/calendar/domain/filter/calendar_filter_defaults.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';

/// Vorberechneter Kalender-Filter vor dem Verlassen des Ladescreens.
class CalendarFilterStartupState {
  CalendarFilterStartupState._();

  static CalendarFiltersState? _bootstrapped;

  static void preload({required ProfileGateData gateData, String? diet}) {
    if (!gateData.hasSession) return;
    _bootstrapped = calendarFiltersStateFromProfileFields(
      choir: gateData.choir,
      voice: gateData.voice,
      className: gateData.className,
      schoolTrack: gateData.schoolTrack,
      diet: diet,
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

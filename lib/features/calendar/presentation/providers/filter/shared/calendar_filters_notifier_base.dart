import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;

import '../../../../domain/filter/calendar_filters_logic.dart';
import '../../../../domain/filter/calendar_filters_state.dart';

abstract class CalendarFiltersNotifierBase extends fr.Notifier<CalendarFiltersState> {
  @override
  CalendarFiltersState build() => const CalendarFiltersState();

  void initializeDefaults({
    required List<String> choirs,
    required List<String> voices,
    required List<String> classNames,
  }) {
    if (!state.hasInitializedDefaults || !state.hasUserOverrides) {
      state = state.copyWith(
        choirs: choirs,
        voices: voices,
        classNames: classNames,
        defaultChoirs: choirs,
        defaultVoices: voices,
        defaultClassNames: classNames,
        hasInitializedDefaults: true,
        hasUserOverrides: false,
      );
      return;
    }

    state = state.copyWith(
      choirs: state.choirs,
      voices: state.voices,
      classNames: state.classNames,
      defaultChoirs: choirs,
      defaultVoices: voices,
      defaultClassNames: classNames,
      hasInitializedDefaults: true,
    );
  }

  void toggleChoir(String value) {
    state = state.copyWith(
      choirs: toggleCalendarFilterValue(state.choirs, value),
      hasUserOverrides: true,
    );
  }

  void toggleVoice(String value) {
    state = state.copyWith(
      voices: toggleCalendarFilterValue(state.voices, value),
      hasUserOverrides: true,
    );
  }

  void toggleClassName(String value) {
    state = state.copyWith(
      classNames: toggleCalendarFilterValue(state.classNames, value),
      hasUserOverrides: true,
    );
  }

  void clearChoirs() {
    state = state.copyWith(choirs: const <String>[], hasUserOverrides: true);
  }

  void clearVoices() {
    state = state.copyWith(voices: const <String>[], hasUserOverrides: true);
  }

  void clearClassNames() {
    state = state.copyWith(classNames: const <String>[], hasUserOverrides: true);
  }

  void removeChoir(String value) {
    state = state.copyWith(
      choirs: removeCalendarFilterValue(state.choirs, value),
      hasUserOverrides: true,
    );
  }

  void removeVoice(String value) {
    state = state.copyWith(
      voices: removeCalendarFilterValue(state.voices, value),
      hasUserOverrides: true,
    );
  }

  void removeClassName(String value) {
    state = state.copyWith(
      classNames: removeCalendarFilterValue(state.classNames, value),
      hasUserOverrides: true,
    );
  }

  void resetToDefaults() {
    state = state.copyWith(
      choirs: state.defaultChoirs,
      voices: state.defaultVoices,
      classNames: state.defaultClassNames,
      hasUserOverrides: false,
    );
  }
}
